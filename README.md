# Dating Assistant

Flutter-приложение для iOS и Android: анализ общения и развития отношений пары с помощью нейросети.

## Запуск

```bash
flutter pub get
flutter run
```

По умолчанию приложение работает на моках. Когда появится сервер:

```bash
flutter run --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://localhost:8080
```

Тесты и анализатор:

```bash
flutter analyze && flutter test
```

## Архитектура

Слои как в Swift-проектах: **Transport → Service → Presentation**. Зависимости идут только в одну сторону:
экран не ходит в транспорт напрямую, сервис ничего не знает про экраны.

```
lib/
├── main.dart                       точка входа
├── misc/                           общее (≈ Misc)
│   ├── app.dart                    корневой виджет: тема, стартовый экран
│   ├── injector.dart               сборка зависимостей: моки или реальный сервер
│   ├── global_definitions.dart     адрес API, флаг моков
│   ├── components/view_model.dart  база для ViewModel: лоадер, «Повторить», actions
│   ├── custom_views/               общие виджеты (TryAgainSheet)
│   └── extensions/
├── transport/                      сеть (≈ RestAPITransport)
│   ├── api_request.dart            описание запроса (≈ APIRequestBody)
│   ├── api_transport.dart          интерфейс транспорта
│   ├── rest_api_transport.dart     настоящий сервер (dio)
│   ├── network_error.dart
│   └── mock/                       фейковый сервер; моки = контракт будущего API
│       └── routes/                 обработчики эндпоинтов по доменам
├── service/                        бизнес-логика (≈ Service)
│   ├── session/                    токен анонимного пользователя
│   └── <домен>/
│       ├── <домен>_manager.dart    методы домена (≈ XxxManager)
│       ├── <домен>_mediator.dart   события между экранами (≈ XxxMediator), когда понадобятся
│       ├── model/                  модели + парсинг JSON
│       └── request/                по классу на эндпоинт
└── presentation/                   экраны (≈ Presentation)
    └── <флоу>/<экран>/
        ├── <экран>_screen.dart     виджет экрана (≈ ViewController + View)
        ├── <экран>_view_model.dart логика и состояние (≈ ViewModel)
        └── views/                  части экрана (≈ Views)
```

### Swift → Flutter

| Swift (RxSwift)                                  | Здесь                                                         |
|--------------------------------------------------|---------------------------------------------------------------|
| `Single<T>`                                      | `Future<T>`                                                   |
| ViewModel `Input`/`Output`, `Driver`             | `ChangeNotifier` + `ListenableBuilder`                        |
| `Output.action` / `Route`                        | `Stream<Action>`: экран слушает и навигирует                  |
| `RxActivityIndicator`                            | `ViewModel.isLoading`                                         |
| `ObservableRetrySingle` + `TryAgainViewController` | `ViewModel.perform` + `TryAgainSheet`                       |
| Mediator на `PublishRelay`                       | `StreamController.broadcast()`                                |
| `protocol XxxManagerProtocol`                    | не нужен: в Dart любой класс уже интерфейс (`implements`)     |
| `static func make()`                             | `static Route route()`                                        |
| `lazy var manager = XxxManager()`                | менеджер из `Injector`, в тестах подменяется через конструктор |

Rx не используем: `Future`, `Stream` и `ChangeNotifier` встроены в Dart и Flutter, этого хватает.

## Моки

Пока сервера нет, `MockApiTransport` отправляет запросы в фейковый сервер (`transport/mock/`). Обработчики
работают с сырым JSON, как настоящий бэкенд, а данные хранятся в SharedPreferences и переживают перезапуск.

Как добавить эндпоинт:

1. Запрос — `service/<домен>/request/xxx_request.dart` (наследник `ApiRequest`).
2. Метод в `<домен>_manager.dart`: вызвать транспорт и распарсить модель.
3. Обработчик — `transport/mock/routes/<домен>_mock_routes.dart`, зарегистрировать в `MockServer`.

Формат ответов в моках — это контракт API: по нему потом напишем сервер.
