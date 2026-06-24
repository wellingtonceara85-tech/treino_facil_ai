# Treino Fácil AI 🏋️‍♀️

App Flutter + Supabase para registrar treinos de musculação, acompanhar
cargas e receber sugestões automáticas de progressão.

> **Versão do Flutter:** o código usa APIs relativamente recentes do
> Flutter (`Color.withValues`, `CardThemeData`, `initialValue` em
> `DropdownButtonFormField`). Use Flutter estável atual (3.27+) — com uma
> versão mais antiga, troque `withValues(alpha: x)` por `withOpacity(x)`,
> `CardThemeData` por `CardTheme` e `initialValue` por `value` nos
> dropdowns.

## Setup rápido

1. **Crie um projeto no [Supabase](https://supabase.com).**
2. Rode o script `database/schema.sql` no SQL Editor do Supabase
   (cria tabelas, RLS, view e catálogo inicial de exercícios).
3. Em **Authentication → Providers**, habilite **Google** e configure o
   OAuth Client ID (Web + Android + iOS conforme a plataforma).
4. Copie a URL e a anon key do projeto e preencha
   `lib/core/config/supabase_config.dart`.
5. Instale as dependências:
   ```bash
   flutter pub get
   ```
6. Rode o app:
   ```bash
   flutter run
   ```

## Estrutura

Veja `docs/01_ARQUITETURA.md` para a explicação completa da arquitetura,
`docs/02_WIREFRAMES.md` para os wireframes de todas as telas e
`docs/03_FLUXO_NAVEGACAO.md` para o mapa de rotas e navegação.

```
lib/
├── core/          # config, router, tema, widgets compartilhados
└── features/
    ├── auth/          # login com Google
    ├── dashboard/      # tela inicial
    ├── exercises/      # catálogo e cadastro de exercícios
    ├── workouts/       # criação e execução de treinos
    ├── progress/        # histórico e gráficos de evolução
    ├── timer/           # cronômetro de descanso
    └── ai_suggestion/   # motor de sugestão de progressão de carga
```

## Etapas do desenvolvimento (conforme solicitado)

1. ✅ Arquitetura completa + banco de dados (`docs/01_ARQUITETURA.md`, `database/schema.sql`)
2. ✅ Wireframes + fluxo de navegação (`docs/02_WIREFRAMES.md`, `docs/03_FLUXO_NAVEGACAO.md`)
3. ✅ Estrutura do projeto Flutter (este repositório)
4. ✅ Autenticação com Supabase + Google (`lib/features/auth`)
5. ✅ Módulo de treinos — exercícios, treinos, execução (`lib/features/exercises`, `lib/features/workouts`, `lib/features/timer`)
6. ✅ Módulo de evolução e gráficos (`lib/features/progress`)
7. ✅ Módulo de IA de sugestão de cargas (`lib/features/ai_suggestion`)
8. ✅ Extras de perfil — Meus exercícios (editar/remover), unidade de carga (kg/lb), Sobre o app

## Checklist para colocar em uso (pessoal)

1. Criar projeto no Supabase e rodar `database/schema.sql`
2. Criar Client ID OAuth (Web) no Google Cloud Console e habilitar o provider Google em Supabase Auth
3. Preencher `lib/core/config/supabase_config.dart`
4. `flutter pub get`
5. `flutter run` (com dispositivo/emulador conectado)

Publicar nas lojas (Play Store/App Store) é um passo **opcional**, separado — não
é necessário para usar o app no seu próprio celular.
