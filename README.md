# Nutrox

Aplicativo mobile desenvolvido em **Flutter** para auxiliar usuários no gerenciamento da alimentação por meio do cadastro de alimentos, criação de cardápios personalizados e gerenciamento do perfil.

O projeto foi desenvolvido como forma de aplicar conceitos de desenvolvimento mobile, arquitetura em camadas, persistência de dados e organização de código utilizando Flutter.

---

# Funcionalidades

- Cadastro de usuários
- Login
- Gerenciamento de perfil
- Alteração da foto de perfil
- Cadastro de alimentos
- Consulta de alimentos
- Cadastro de cardápios
- Visualização de cardápios
- Pesquisa de conteúdo
- Visualização de perfis públicos
- Persistência local dos dados
- Navegação entre múltiplas telas

---

# Arquitetura

O projeto foi organizado utilizando separação de responsabilidades, tornando o código mais organizado e de fácil manutenção.

```
lib/
│
├── controllers/
├── database/
├── models/
├── repository/
├── routes/
├── screens/
├── utils/
├── widgets/
└── main.dart
```

### Estrutura

- **Controllers** → Controle das regras de negócio.
- **Models** → Entidades da aplicação.
- **Repository** → Comunicação com a camada de dados.
- **Database** → Persistência local.
- **Routes** → Gerenciamento das rotas.
- **Screens** → Interfaces da aplicação.
- **Widgets** → Componentes reutilizáveis.
- **Utils** → Funções auxiliares.

---

# Tecnologias

- Flutter
- Dart
- Material Design
- Persistência local de dados

---

# Fluxo da aplicação

```text
Splash Screen
      │
      ▼
Login / Cadastro
      │
      ▼
Home
 ├── Pesquisa
 ├── Cardápios
 ├── Alimentos
 └── Perfil
```

---

# Objetivo

O Nutrox foi desenvolvido com o objetivo de oferecer uma solução simples para organização alimentar, permitindo que usuários gerenciem alimentos e cardápios em uma interface intuitiva.

Além do propósito funcional, o projeto serviu como prática de conceitos importantes do desenvolvimento mobile utilizando Flutter.

---

# Como executar

## Pré-requisitos

- Flutter SDK
- Dart SDK
- Android Studio ou VS Code
- Emulador Android ou dispositivo físico

## Clone o projeto

```bash
git clone https://github.com/devcauas/nutrox.git
```

Entre na pasta

```bash
cd nutrox
```

Instale as dependências

```bash
flutter pub get
```

Execute

```bash
flutter run
```

---

# Organização do projeto

```
lib
├── controllers
├── database
├── models
├── repository
├── routes
├── screens
├── utils
├── widgets
└── main.dart
```

---

# Aprendizados

Durante o desenvolvimento deste projeto foram aplicados conhecimentos em:

- Desenvolvimento Mobile com Flutter
- Organização de projetos em camadas
- Persistência de dados
- Programação Orientada a Objetos
- Navegação entre telas
- Componentização
- Gerenciamento de estado da interface
- Estruturação de aplicações escaláveis

---

# Melhorias futuras

- Autenticação utilizando Firebase Authentication
- Sincronização em nuvem
- Favoritos
- Informações nutricionais completas
- Dashboard com gráficos
- Tema escuro
- Testes automatizados
- Publicação na Play Store
