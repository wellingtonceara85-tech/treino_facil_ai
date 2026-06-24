# Treino Fácil AI — Wireframes

Wireframes em baixa fidelidade (ASCII) para guiar a implementação. Foco:
poucos toques, texto grande, botões grandes (uso com a mão suada no treino).

---

## 1. Login

```
┌─────────────────────────────┐
│                              │
│         🏋️  (logo)          │
│      Treino Fácil AI         │
│                              │
│   "Treine. Registre.         │
│    Evolua."                  │
│                              │
│  ┌─────────────────────────┐ │
│  │  G   Entrar com Google  │ │
│  └─────────────────────────┘ │
│                              │
│   Seus dados ficam só seus.  │
└─────────────────────────────┘
```

---

## 2. Dashboard (Home)

```
┌─────────────────────────────┐
│ Oi, Ana 👋          [👤]     │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │  ▶  Iniciar treino       │ │
│ │     Treino A · Peito     │ │  ← treino sugerido (próximo na rotação)
│ └─────────────────────────┘ │
│                              │
│  Esta semana: 2/4 treinos   │
│  [██████░░░░░░] 50%          │
│                              │
│  Sugestão da semana:         │
│  💡 Suba a carga do Supino   │
│     para 32,5 kg              │
│                              │
│  Meus treinos                │
│  ┌─────────┐ ┌─────────┐    │
│  │Treino A │ │Treino B │    │
│  │Peito/Tri│ │Dorsal/Bi│    │
│  └─────────┘ └─────────┘    │
│  ┌─────────┐ ┌─────────┐    │
│  │Treino C │ │ + Novo  │    │
│  │Perna    │ │ treino  │    │
│  └─────────┘ └─────────┘    │
├─────────────────────────────┤
│ [Início] [Treinos] [Hist.] [Perfil] │
└─────────────────────────────┘
```

---

## 3. Lista / Cadastro de Treinos

```
┌─────────────────────────────┐
│ ← Meus treinos        [+]   │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Treino A — Peito/Tríceps │ │
│ │ 5 exercícios             │ │
│ │            [Editar] [▶]  │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Treino B — Dorsal/Bíceps │ │
│ │ 4 exercícios             │ │
│ │            [Editar] [▶]  │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

### 3.1 Formulário de Treino

```
┌─────────────────────────────┐
│ ← Novo treino         [Salvar]│
├─────────────────────────────┤
│ Nome do treino                │
│ [ Treino A - Peito/Tríceps ] │
│                              │
│ Exercícios                   │
│ ┌─────────────────────────┐ │
│ │ ☰ Supino reto       [✕] │ │
│ │   3 séries · 8-12 reps   │ │
│ │   Carga inicial: 30 kg   │ │
│ │   Descanso: 90s          │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ ☰ Crucifixo         [✕] │ │
│ └─────────────────────────┘ │
│                              │
│  [+ Adicionar exercício]     │
└─────────────────────────────┘
```

---

## 4. Cadastro / Busca de Exercício

```
┌─────────────────────────────┐
│ ← Adicionar exercício        │
├─────────────────────────────┤
│ 🔍 Buscar exercício...        │
│                              │
│ Grupo: [Todos ▾]              │
│                              │
│ ┌─────────────────────────┐ │
│ │ Supino reto com barra    │ │
│ │ Peito · Barra        [+]│ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Supino inclinado halteres│ │
│ │ Peito · Halteres     [+]│ │
│ └─────────────────────────┘ │
│                              │
│ Não achou? [+ Criar exercício]│
└─────────────────────────────┘
```

---

## 5. Execução do Treino (tela mais importante do app)

```
┌─────────────────────────────┐
│ ← Treino A      ⏱ 12:34      │
├─────────────────────────────┤
│ Exercício 2 de 5              │
│ ███████░░░░░░░░░░             │
│                              │
│      Supino reto              │
│   Meta: 3x8-12 · 30 kg        │
│                              │
│   Série 1 de 3                │
│                              │
│   Carga (kg)                  │
│   [ -2.5 ]  30.0  [ +2.5 ]    │
│                              │
│   Repetições                  │
│   [  -1  ]   10   [  +1  ]    │
│                              │
│   Como foi essa série?        │
│  [😅Difícil][🙂Normal][😎Fácil]│
│                              │
│  ┌─────────────────────────┐ │
│  │   ✓  Concluir série      │ │
│  └─────────────────────────┘ │
└─────────────────────────────┘
```

### 5.1 Timer de descanso (sobreposto/automático após concluir série)

```
┌─────────────────────────────┐
│                              │
│        Descansa 😌           │
│                              │
│         01:23                │
│      ⭕ (anel regressivo)     │
│                              │
│   [ -15s ]      [ +15s ]     │
│                              │
│      [ Pular descanso ]      │
│                              │
└─────────────────────────────┘
```

### 5.2 Fim do treino + sugestão da IA

```
┌─────────────────────────────┐
│        Treino concluído! 🎉  │
│                              │
│   Duração: 48 min             │
│   Volume total: 4.230 kg      │
│                              │
│  💡 Sugestões para a próxima: │
│  ┌─────────────────────────┐ │
│  │ Supino reto               │ │
│  │ 30kg → 32,5kg             │ │
│  │ Você bateu 12 reps nas    │ │
│  │ 3 séries. Hora de subir.  │ │
│  │      [Aceitar] [Ignorar]  │ │
│  └─────────────────────────┘ │
│                              │
│      [ Voltar ao início ]     │
└─────────────────────────────┘
```

---

## 6. Histórico

```
┌─────────────────────────────┐
│ ← Histórico                  │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ Hoje, 18:32                │ │
│ │ Treino A · 48 min · 4.230kg│ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Seg, 19/jun                │ │
│ │ Treino B · 41 min · 3.810kg│ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Sáb, 17/jun                │ │
│ │ Treino C · 52 min · 5.100kg│ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## 7. Evolução / Gráficos

```
┌─────────────────────────────┐
│ ← Evolução                   │
├─────────────────────────────┤
│ Exercício: [Supino reto ▾]    │
│                              │
│ Carga máxima ao longo do tempo│
│  35┤                    ●    │
│  30┤        ●───●───●        │
│  25┤  ●───●                  │
│  20└──────────────────────   │
│    mar  abr  mai  jun        │
│                              │
│ Volume total por treino       │
│  ▓▓▓ ▓▓▓▓ ▓▓ ▓▓▓▓▓ ▓▓▓▓      │
│                              │
│  Recorde pessoal: 35 kg       │
│  (3 reps, 15/jun)             │
└─────────────────────────────┘
```

---

## 8. Perfil

```
┌─────────────────────────────┐
│ ← Perfil                     │
├─────────────────────────────┤
│       (foto)  Ana Silva       │
│       ana@email.com           │
│                              │
│  Unidade de carga: [Kg|Lb]    │
│  Meus exercícios               │
│  Notificações                  │
│  Sobre o app                   │
│                              │
│      [ Sair da conta ]        │
└─────────────────────────────┘
```
