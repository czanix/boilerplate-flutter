# Czanix Boilerplate — Flutter

> Flutter com Clean Architecture real. Offline-first, state management sem overengineering, e a disciplina que separa app que funciona de app que sobrevive.

[![Flutter](https://img.shields.io/badge/Flutter-3.22-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4-0175C2?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tech Reference](https://img.shields.io/badge/Czanix-Tech%20Reference-gold)](https://czanix.com/pt/stack)

---

## Filosofia

Flutter é fácil para começar, difícil para manter. Este boilerplate resolve o "manter":

1. **Clean Architecture com 3 camadas** — domínio puro, data layer isolada, presentation desacoplada
2. **Riverpod para state management** — compile-safe, testável, sem Provider hell
3. **Offline-first** — SQLite local + sync queue. O app funciona sem rede
4. **Feature-based** — cada módulo é independente, testável e substituível

**O que não tem aqui:** BLoC para CRUD simples (overengineering), `setState` global, God Widget de 500 linhas, API call direto no Widget.

---

## Estrutura

```
lib/
├── core/                            # Infra compartilhada
│   ├── network/
│   │   ├── api_client.dart          # Dio configurado + interceptors
│   │   ├── api_result.dart          # Result<T> — sem exceção
│   │   └── connectivity.dart        # Online/offline detection
│   ├── database/
│   │   ├── app_database.dart        # Drift/SQLite setup
│   │   └── sync_queue.dart          # Fila de sync offline
│   ├── di/
│   │   └── injection.dart           # Riverpod providers root
│   └── theme/
│       ├── app_theme.dart           # Design tokens
│       └── app_colors.dart
│
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart        # Entity pura
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart  # Abstract class
│   │   │   └── usecases/
│   │   │       └── login_usecase.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote.dart
│   │   │   │   └── auth_local.dart  # Token storage
│   │   │   ├── models/
│   │   │   │   └── user_model.dart  # JSON serialization
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── pages/
│   │       │   └── login_page.dart
│   │       └── widgets/
│   │           └── login_form.dart
│   │
│   └── orders/
│       ├── domain/
│       ├── data/
│       └── presentation/
│
├── app.dart                         # MaterialApp + Router
└── main.dart                        # Entrypoint
```

### Por que Domain/Data/Presentation por feature?

Porque quando o PM pede "remove o módulo de orders", você deleta uma pasta. Não precisa caçar 15 arquivos espalhados em `models/`, `screens/`, `controllers/`.

---

## Início rápido

```bash
# 1. Clone
git clone https://github.com/czanix/boilerplate-flutter.git meu-app
cd meu-app

# 2. Dependências
flutter pub get

# 3. Geração de código (Freezed, JSON, Drift)
dart run build_runner build --delete-conflicting-outputs

# 4. Run
flutter run
```

---

## Result Pattern — sem try/catch espalhado

```dart
// api_result.dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final int? statusCode;
  const Failure(this.message, {this.statusCode});
}

// Uso no use case
class LoginUseCase {
  final AuthRepository _repository;
  
  LoginUseCase(this._repository);

  Future<Result<User>> call(LoginParams params) async {
    if (params.email.isEmpty) {
      return const Failure('Email obrigatório');
    }

    return _repository.login(
      email: params.email,
      password: params.password,
    );
  }
}

// No provider — tratamento explícito
final loginProvider = FutureProvider.family<User, LoginParams>((ref, params) async {
  final result = await ref.read(loginUseCaseProvider).call(params);
  
  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw AppException(message),
  };
});
```

---

## Offline-First — sync queue

```dart
// sync_queue.dart — operações ficam na fila quando offline
class SyncQueue {
  final AppDatabase _db;
  final ApiClient _api;
  final Connectivity _connectivity;

  Future<void> enqueue(SyncOperation operation) async {
    // Salva localmente primeiro — SEMPRE
    await _db.syncOperations.insert(operation);

    // Tenta sync imediato se online
    if (await _connectivity.isConnected) {
      await _processQueue();
    }
  }

  Future<void> _processQueue() async {
    final pending = await _db.syncOperations.getPending();

    for (final op in pending) {
      try {
        await _api.execute(op.method, op.endpoint, data: op.payload);
        await _db.syncOperations.markCompleted(op.id);
      } catch (e) {
        // Retry na próxima sync — não perde dado
        await _db.syncOperations.incrementRetry(op.id);
      }
    }
  }
}
```

**O app salva localmente primeiro, sincroniza depois.** O usuário nunca percebe a falta de rede. Isso é o que separa app profissional de app amador.

---

## Riverpod — state management tipado

```dart
// Providers são compile-time safe — erro de tipo não compila
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final repository = ref.read(orderRepositoryProvider);
  final result = await repository.getAll();
  
  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw AppException(message),
  };
});

// Widget consumindo — sem rebuild desnecessário
class OrderListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return ordersAsync.when(
      loading: () => const OrdersSkeleton(),
      error: (err, _) => ErrorWidget(message: err.toString()),
      data: (orders) => ListView.builder(
        itemCount: orders.length,
        itemBuilder: (_, i) => OrderCard(order: orders[i]),
      ),
    );
  }
}
```

---

## Navegação — GoRouter declarativo

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = auth.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (_, __, child) => AppScaffold(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/orders', builder: (_, __) => const OrdersPage()),
          GoRoute(path: '/orders/:id', builder: (_, state) => 
            OrderDetailPage(id: state.pathParameters['id']!)),
        ],
      ),
    ],
  );
});
```

---

## Testes

```bash
flutter test                        # Todos
flutter test test/unit/              # Só unit
flutter test --coverage              # Coverage
flutter test integration_test/       # Integration
```

```dart
// Unit test — domínio puro, sem Flutter
test('login com email vazio retorna Failure', () async {
  final useCase = LoginUseCase(MockAuthRepository());

  final result = await useCase.call(
    const LoginParams(email: '', password: '123'),
  );

  expect(result, isA<Failure>());
});
```

---

## Referência técnica

- [Guia de Arquitetura](https://czanix.com/pt/stack/backend)
- [Trade-offs: Provider vs Riverpod vs BLoC](https://czanix.com/pt/stack/tradeoffs)
- [Tech Radar](https://czanix.com/pt/stack/tech-radar)

---

## Licença

MIT — use, adapte, melhore. Se ajudou, [deixa uma estrela](https://github.com/czanix/boilerplate-flutter) ⭐

---

<div align="center">
<sub>Desenvolvido e mantido por <a href="https://czanix.com">Cesar Zanis</a> — Czanix</sub>
</div>
