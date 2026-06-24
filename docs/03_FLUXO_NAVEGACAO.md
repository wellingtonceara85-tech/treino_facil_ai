# Treino Fácil AI — Fluxo de Navegação

## Mapa de rotas (go_router)

| Rota | Tela | Guard |
|---|---|---|
| `/login` | LoginScreen | pública |
| `/` | DashboardScreen | autenticada |
| `/treinos` | WorkoutsListScreen | autenticada |
| `/treinos/novo` | WorkoutFormScreen | autenticada |
| `/treinos/:id/editar` | WorkoutFormScreen | autenticada |
| `/treinos/:id/executar` | WorkoutSessionScreen | autenticada |
| `/exercicios/buscar` | ExercisePickerScreen | autenticada (modal) |
| `/historico` | HistoryScreen | autenticada |
| `/evolucao` | EvolutionScreen | autenticada |
| `/evolucao/:exercicioId` | EvolutionScreen (filtrado) | autenticada |
| `/perfil` | ProfileScreen | autenticada |

`redirect` global no router: se não há sessão Supabase válida → força `/login`.
Se há sessão e a rota é `/login` → redireciona para `/`.

## Fluxo principal (caminho feliz de um treino)

```
Login (Google)
   │
   ▼
Dashboard ──────────────► Meus Treinos ──► Form. de Treino ──► Buscar/Criar Exercício
   │                          │                                      │
   │ toca "Iniciar treino"    │ toca treino existente                ▼
   ▼                          ▼                              (volta para o form)
Execução do Treino ◄──────────┘
   │
   │  para cada exercício:
   │     registra série → Timer de descanso → próxima série/exercício
   ▼
Tela de Conclusão + Sugestões da IA
   │  aceitar/ignorar sugestão por exercício
   ▼
Dashboard (atualizado)
```

## Navegação secundária (bottom navigation)

```
[Início] [Treinos] [Histórico] [Perfil]
   │         │           │          │
   ▼         ▼           ▼          ▼
Dashboard  Lista de   Histórico   Perfil
           Treinos    de sessões  ── Meus exercícios
                          │       ── Unidade de carga
                          ▼       ── Sair
                      Evolução
                    (gráfico por
                     exercício)
```

## Regras de navegação importantes

1. **Execução de treino é uma rota "presa"**: ao entrar em
   `/treinos/:id/executar`, o botão de voltar do sistema pede confirmação
   ("Sair vai descartar o treino em andamento?") em vez de simplesmente
   sair, para não perder progresso por toque acidental.
2. **Timer de descanso não é uma rota separada**: é um widget sobreposto
   (overlay) dentro da própria `WorkoutSessionScreen`, para não recriar a
   tela e perder o estado da sessão ao navegar.
3. **Tela de conclusão é "para frente apenas"**: não dá para voltar para a
   execução do treino depois de finalizado (sessão já foi marcada como
   `concluida` no banco).
4. **Picker de exercício é modal (bottom sheet), não rota cheia**: usado
   tanto no cadastro de treino quanto futuramente em "adicionar exercício
   extra" durante a execução, sem perder o contexto da tela de origem.
