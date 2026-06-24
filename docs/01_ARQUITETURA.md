# Treino Fácil AI — Arquitetura Completa

## 1. Visão geral

App mobile (Flutter) focado em **uma única usuária** na v1, para registrar
treinos de musculação, cargas, evolução e receber sugestões automáticas de
progressão de carga. Arquitetura pensada desde o início para evoluir para
uma **plataforma multi-tenant de personal trainers** (v2), sem precisar
reescrever o core.

### Princípios de design
- **Simplicidade de uso > completude de features.** Durante o treino, a
  usuária está com a mão suada, sem paciência para preencher formulários
  longos. Toda a tela de execução de treino é otimizada para "1 toque = 1 ação".
- **Offline-first parcial.** Os dados de uma sessão de treino em andamento
  ficam em memória/local até serem sincronizados — uma queda de internet no
  meio da série não pode fazer a usuária perder o treino.
- **Camadas desacopladas.** Regra de negócio (e a "IA" de progressão) não
  conhece Supabase nem Flutter — é Dart puro, testável, e reaproveitável em
  uma futura API própria, Cloud Function, ou app web de personal trainer.

## 2. Stack tecnológica

| Camada | Tecnologia | Motivo |
|---|---|---|
| App | Flutter (Dart) | Single codebase iOS/Android |
| Gerência de estado | Riverpod | Testável, escalável, DI nativa |
| Navegação | go_router | Deep links, rotas declarativas, guards de auth |
| Backend | Supabase (Postgres + Auth + Storage + Realtime) | Backend gerenciado, RLS nativo, login social |
| Autenticação | Supabase Auth + Google Sign-In | Login rápido, sem senha |
| Gráficos | fl_chart | Leve, nativo Flutter, customizável |
| IA de progressão | Motor de regras em Dart (v1) → Edge Function / modelo externo (v2) | v1 não precisa de infra de ML; lógica clara e auditável |

## 3. Arquitetura em camadas (Clean Architecture simplificada, feature-first)

```
lib/
├── core/                     # Código transversal, sem regra de negócio de domínio
│   ├── config/               # Supabase, env, constantes
│   ├── router/               # go_router + guards
│   ├── theme/                # Design system (cores, tipografia, espaçamento)
│   ├── widgets/              # Componentes reutilizáveis (botão, card, input)
│   └── utils/                # Formatadores, extensões, result/either
│
└── features/                 # Cada feature é um módulo quase independente
    ├── auth/
    │   ├── domain/            # Entidades + contratos (interfaces)
    │   ├── data/              # Implementação concreta (Supabase)
    │   └── presentation/      # Telas + controllers (Riverpod)
    ├── dashboard/
    ├── exercises/
    ├── workouts/
    ├── progress/
    ├── timer/
    └── ai_suggestion/
```

Cada feature segue o mesmo padrão de 3 sub-camadas:
- **domain**: entidades puras (`Treino`, `Exercicio`, `SerieRegistrada`...) e
  contratos de repositório (`abstract class TreinoRepository`). Não importa
  `supabase_flutter`.
- **data**: implementação do contrato usando Supabase
  (`SupabaseTreinoRepository implements TreinoRepository`). Troca de backend
  no futuro = trocar só essa camada.
- **presentation**: telas (Widgets) + `*Controller`/`*Notifier` (Riverpod) que
  orquestram domain + data e expõem estado para a UI.

Essa separação é o que permite, na v2, transformar `TreinoRepository` em algo
que filtra por `personal_id`/`aluno_id` sem tocar nas telas.

## 4. Fluxo de dados (exemplo: registrar uma série)

```
[WorkoutSessionScreen]
      │ usuária toca "Concluir série"
      ▼
[SessionController.registrarSerie()]   (presentation)
      │ valida input, monta SerieRegistrada
      ▼
[ProgressRepository.salvarSerie()]      (domain contract)
      ▼
[SupabaseProgressRepository]            (data)
      │ insert na tabela series_registradas
      ▼
[Supabase Postgres]  ──► trigger/consulta histórica
      ▼
[ProgressionEngine.sugerir()]           (ai_suggestion/domain, Dart puro)
      │ compara série atual x últimas sessões
      ▼
[SuggestionCardWidget] exibe "Na próxima, suba para 32,5 kg 💪"
```

## 5. Escalabilidade para plataforma de personal trainers (v2)

A v1 já nasce com a coluna `usuario_id` em todas as tabelas de domínio (em
vez de assumir "usuária única" implicitamente). Isso significa que a
evolução para multi-tenant é uma **extensão**, não uma migração destrutiva:

1. **`profiles.tipo_usuario`**: `'aluno' | 'personal' | 'admin'` (já no schema v1).
2. **Nova tabela `vinculos_personal_aluno`**: liga `personal_id` ↔ `aluno_id`,
   com status (`pendente`, `ativo`, `encerrado`).
3. **RLS evolui de "usuario_id = auth.uid()" para "usuario_id = auth.uid() OR
   usuario_id IN (SELECT aluno_id FROM vinculos_personal_aluno WHERE
   personal_id = auth.uid() AND status = 'ativo')"** — uma política a mais,
   sem alterar estrutura de tabela.
4. **Templates de treino**: tabela `treinos` já tem `criado_por` separado de
   `usuario_id`, permitindo que um personal crie o treino e atribua à aluna.
5. **Billing/planos**: módulo novo (`subscriptions`), isolado, plugado depois.
6. **App**: a camada `presentation` ganha um novo "shell" de navegação para
   personal (lista de alunos → dashboard de cada aluno), reusando 100% dos
   widgets de gráfico, histórico e timer já construídos para a aluna única.

Ou seja: **nenhuma regra de negócio do v1 precisa ser jogada fora.**

## 6. Decisões técnicas relevantes

- **Riverpod** em vez de Provider/Bloc: menos boilerplate, melhor testabilidade,
  e os `Notifier`s mapeiam bem para os Controllers de cada feature.
- **go_router**: permite proteger rotas (`redirect:` checando sessão Supabase)
  e terá utilidade direta quando o app de personal precisar de rotas
  `/aluno/:id/dashboard`.
- **"IA" da v1 é um motor de regras determinístico, não um modelo treinado.**
  Decisão consciente: é auditável, explica o motivo da sugestão para a
  usuária ("você bateu todas as repetições com folga 2x seguidas"), funciona
  100% offline e tem custo zero de inferência. A interface
  (`ProgressionEngine`) foi desenhada para, na v2, ser substituída/decorada
  por uma chamada a um modelo (ex.: Claude via Supabase Edge Function) sem
  alterar quem a consome.
- **Supabase Storage** reservado (não implementado na v1) para fotos de
  evolução física e vídeos de execução de exercício — apenas o bucket é
  citado no schema como próximo passo.

## 7. Não-objetivos da v1 (escopo deliberadamente fora)

- Múltiplos perfis/usuárias no mesmo app (vem na v2).
- Treino guiado por vídeo/IA visual de execução.
- Notificações push de lembrete (fácil de adicionar depois, via Supabase + FCM).
- Integração com wearables.
