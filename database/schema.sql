-- =====================================================================
-- TREINO FÁCIL AI — SCHEMA SUPABASE (Postgres)
-- v1: usuária única por conta. Campos e RLS já preparados para v2
-- (plataforma de personal trainers) — ver seção "PREPARAÇÃO PARA V2".
-- =====================================================================

-- ---------------------------------------------------------------------
-- EXTENSÕES
-- ---------------------------------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- FUNÇÃO UTILITÁRIA: updated_at automático
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- =====================================================================
-- 1. PROFILES — extensão de auth.users
-- =====================================================================
create table public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  nome            text not null,
  email           text not null,
  avatar_url      text,
  tipo_usuario    text not null default 'aluno'
                    check (tipo_usuario in ('aluno', 'personal', 'admin')), -- preparação v2
  unidade_carga   text not null default 'kg' check (unidade_carga in ('kg','lb')),
  criado_em       timestamptz not null default now(),
  atualizado_em   timestamptz not null default now()
);

create trigger trg_profiles_updated
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Cria profile automaticamente quando um usuário se registra (Google login)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, nome, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email,'@',1)),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
-- 2. EXERCICIOS — catálogo (do sistema OU criado pela própria usuária)
-- =====================================================================
create table public.exercicios (
  id                uuid primary key default uuid_generate_v4(),
  usuario_id        uuid references public.profiles(id) on delete cascade, -- null = catálogo global do sistema
  nome              text not null,
  grupo_muscular    text not null, -- ex: 'peito','dorsal','perna','ombro','biceps','triceps','core','gluteo'
  equipamento       text,          -- ex: 'barra','halteres','maquina','peso_corporal','cabo'
  video_url         text,
  observacoes       text,
  ativo             boolean not null default true,
  criado_em         timestamptz not null default now()
);

create index idx_exercicios_usuario on public.exercicios(usuario_id);
create index idx_exercicios_grupo on public.exercicios(grupo_muscular);

-- =====================================================================
-- 3. TREINOS — ex: "Treino A - Peito/Tríceps"
-- =====================================================================
create table public.treinos (
  id              uuid primary key default uuid_generate_v4(),
  usuario_id      uuid not null references public.profiles(id) on delete cascade, -- dona do treino (aluna)
  criado_por      uuid not null references public.profiles(id) on delete cascade, -- quem criou (== usuario_id na v1; personal na v2)
  nome            text not null,
  descricao       text,
  ordem           integer not null default 0,
  ativo           boolean not null default true,
  criado_em       timestamptz not null default now(),
  atualizado_em   timestamptz not null default now()
);

create trigger trg_treinos_updated
  before update on public.treinos
  for each row execute function public.set_updated_at();

create index idx_treinos_usuario on public.treinos(usuario_id);

-- =====================================================================
-- 4. TREINO_EXERCICIOS — exercícios dentro de um treino, com metas
-- =====================================================================
create table public.treino_exercicios (
  id                        uuid primary key default uuid_generate_v4(),
  treino_id                 uuid not null references public.treinos(id) on delete cascade,
  exercicio_id              uuid not null references public.exercicios(id) on delete restrict,
  ordem                     integer not null default 0,
  series_alvo               integer not null default 3,
  repeticoes_alvo_min       integer not null default 8,
  repeticoes_alvo_max       integer not null default 12,
  carga_inicial             numeric(6,2),               -- kg ou lb, conforme profiles.unidade_carga
  incremento_sugerido       numeric(6,2) not null default 2.5, -- "passo" de progressão padrão do exercício
  tempo_descanso_segundos   integer not null default 90,
  observacoes               text,
  criado_em                 timestamptz not null default now()
);

create index idx_treino_exercicios_treino on public.treino_exercicios(treino_id);
create unique index uq_treino_exercicio_ordem on public.treino_exercicios(treino_id, ordem);

-- =====================================================================
-- 5. SESSOES_TREINO — uma execução real do treino (ex: hoje às 18h)
-- =====================================================================
create table public.sessoes_treino (
  id              uuid primary key default uuid_generate_v4(),
  usuario_id      uuid not null references public.profiles(id) on delete cascade,
  treino_id       uuid not null references public.treinos(id) on delete restrict,
  data_inicio     timestamptz not null default now(),
  data_fim        timestamptz,
  status          text not null default 'em_andamento'
                    check (status in ('em_andamento','concluida','abandonada')),
  observacoes     text,
  criado_em       timestamptz not null default now()
);

create index idx_sessoes_usuario on public.sessoes_treino(usuario_id, data_inicio desc);
create index idx_sessoes_treino on public.sessoes_treino(treino_id);

-- =====================================================================
-- 6. SERIES_REGISTRADAS — cada série feita: carga, reps, feedback
-- =====================================================================
create table public.series_registradas (
  id                    uuid primary key default uuid_generate_v4(),
  sessao_id             uuid not null references public.sessoes_treino(id) on delete cascade,
  treino_exercicio_id   uuid not null references public.treino_exercicios(id) on delete cascade,
  exercicio_id          uuid not null references public.exercicios(id) on delete restrict,
  numero_serie          integer not null,           -- 1, 2, 3...
  carga                 numeric(6,2) not null,
  repeticoes            integer not null,
  feedback              text not null default 'normal'
                          check (feedback in ('muito_facil','facil','normal','dificil','falhou')),
  falhou_serie          boolean not null default false,
  criado_em             timestamptz not null default now()
);

create index idx_series_sessao on public.series_registradas(sessao_id);
create index idx_series_exercicio_data on public.series_registradas(exercicio_id, criado_em desc);

-- =====================================================================
-- 7. SUGESTOES_PROGRESSAO — histórico do que a "IA" sugeriu (auditável)
-- =====================================================================
create table public.sugestoes_progressao (
  id                uuid primary key default uuid_generate_v4(),
  usuario_id        uuid not null references public.profiles(id) on delete cascade,
  exercicio_id      uuid not null references public.exercicios(id) on delete cascade,
  sessao_origem_id  uuid references public.sessoes_treino(id) on delete set null,
  carga_anterior    numeric(6,2) not null,
  carga_sugerida    numeric(6,2) not null,
  tipo_sugestao     text not null check (tipo_sugestao in ('aumentar','manter','reduzir')),
  motivo            text not null,         -- explicação legível gerada pelo motor de regras
  aceita            boolean,                -- null = ainda não respondida pela usuária
  criado_em         timestamptz not null default now()
);

create index idx_sugestoes_usuario on public.sugestoes_progressao(usuario_id, criado_em desc);

-- =====================================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================================
alter table public.profiles             enable row level security;
alter table public.exercicios           enable row level security;
alter table public.treinos              enable row level security;
alter table public.treino_exercicios    enable row level security;
alter table public.sessoes_treino       enable row level security;
alter table public.series_registradas   enable row level security;
alter table public.sugestoes_progressao enable row level security;

-- profiles: cada usuária só vê/edita o próprio perfil
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

-- exercicios: vê catálogo global (usuario_id null) + os seus próprios
create policy "exercicios_select" on public.exercicios
  for select using (usuario_id is null or usuario_id = auth.uid());
create policy "exercicios_insert_own" on public.exercicios
  for insert with check (usuario_id = auth.uid());
create policy "exercicios_update_own" on public.exercicios
  for update using (usuario_id = auth.uid());
create policy "exercicios_delete_own" on public.exercicios
  for delete using (usuario_id = auth.uid());

-- treinos: somente o dono
create policy "treinos_crud_own" on public.treinos
  for all using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

-- treino_exercicios: via join implícito (dono do treino pai)
create policy "treino_exercicios_crud_own" on public.treino_exercicios
  for all using (
    exists (select 1 from public.treinos t where t.id = treino_id and t.usuario_id = auth.uid())
  ) with check (
    exists (select 1 from public.treinos t where t.id = treino_id and t.usuario_id = auth.uid())
  );

-- sessoes_treino: somente o dono
create policy "sessoes_crud_own" on public.sessoes_treino
  for all using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

-- series_registradas: via sessão (dono da sessão)
create policy "series_crud_own" on public.series_registradas
  for all using (
    exists (select 1 from public.sessoes_treino s where s.id = sessao_id and s.usuario_id = auth.uid())
  ) with check (
    exists (select 1 from public.sessoes_treino s where s.id = sessao_id and s.usuario_id = auth.uid())
  );

-- sugestoes_progressao: somente o dono
create policy "sugestoes_crud_own" on public.sugestoes_progressao
  for all using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

-- =====================================================================
-- VIEW: última carga usada por exercício (acelera o "preencher automático")
-- =====================================================================
create or replace view public.vw_ultima_carga_exercicio as
select
  sr.exercicio_id,
  s.usuario_id,
  sr.carga as ultima_carga,
  sr.repeticoes as ultimas_repeticoes,
  sr.feedback as ultimo_feedback,
  sr.criado_em as registrado_em,
  row_number() over (partition by s.usuario_id, sr.exercicio_id order by sr.criado_em desc) as rn
from public.series_registradas sr
join public.sessoes_treino s on s.id = sr.sessao_id;

-- Uso: select * from vw_ultima_carga_exercicio where usuario_id = auth.uid() and exercicio_id = '...' and rn = 1;

-- =====================================================================
-- SEED: catálogo inicial de exercícios (global, usuario_id = null)
-- =====================================================================
insert into public.exercicios (nome, grupo_muscular, equipamento) values
  ('Supino reto com barra', 'peito', 'barra'),
  ('Supino inclinado com halteres', 'peito', 'halteres'),
  ('Crucifixo com halteres', 'peito', 'halteres'),
  ('Puxada frontal', 'dorsal', 'maquina'),
  ('Remada baixa', 'dorsal', 'cabo'),
  ('Remada curvada com barra', 'dorsal', 'barra'),
  ('Desenvolvimento com halteres', 'ombro', 'halteres'),
  ('Elevação lateral', 'ombro', 'halteres'),
  ('Rosca direta com barra', 'biceps', 'barra'),
  ('Rosca alternada com halteres', 'biceps', 'halteres'),
  ('Tríceps na polia', 'triceps', 'cabo'),
  ('Tríceps testa', 'triceps', 'barra'),
  ('Agachamento livre', 'perna', 'barra'),
  ('Leg press 45°', 'perna', 'maquina'),
  ('Cadeira extensora', 'perna', 'maquina'),
  ('Cadeira flexora', 'perna', 'maquina'),
  ('Stiff com barra', 'perna', 'barra'),
  ('Elevação pélvica (hip thrust)', 'gluteo', 'barra'),
  ('Cadeira abdutora', 'gluteo', 'maquina'),
  ('Abdominal supra', 'core', 'peso_corporal'),
  ('Prancha isométrica', 'core', 'peso_corporal');

-- =====================================================================
-- PREPARAÇÃO PARA V2 (plataforma de personal trainers)
-- Não executar agora — referência para migração futura.
-- =====================================================================
-- create table public.vinculos_personal_aluno (
--   id            uuid primary key default uuid_generate_v4(),
--   personal_id   uuid not null references public.profiles(id),
--   aluno_id      uuid not null references public.profiles(id),
--   status        text not null default 'pendente' check (status in ('pendente','ativo','encerrado')),
--   criado_em     timestamptz not null default now(),
--   unique (personal_id, aluno_id)
-- );
--
-- -- RLS evolui (exemplo para sessoes_treino):
-- -- create policy "sessoes_select_own_or_personal" on public.sessoes_treino
-- --   for select using (
-- --     usuario_id = auth.uid()
-- --     or usuario_id in (
-- --       select aluno_id from public.vinculos_personal_aluno
-- --       where personal_id = auth.uid() and status = 'ativo'
-- --     )
-- --   );
--
-- create table public.subscriptions (
--   id              uuid primary key default uuid_generate_v4(),
--   personal_id     uuid not null references public.profiles(id),
--   plano           text not null,
--   status          text not null,
--   renovacao_em    timestamptz
-- );
