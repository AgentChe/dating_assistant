# Cue — Dating Assistant

Flutter-приложение для iOS и Android: AI-коуч для переписки в знакомствах — разбирает чат, показывает,
как развиваются отношения, и пишет следующее сообщение голосом пользователя.

Макет: [Figma](https://www.figma.com/design/plPqacnfO51V0VyG4cxlW1/Dating-Assistant).

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
│   ├── global_definitions.dart     адрес API, флаг моков, ключи OtterScale
│   ├── appearance.dart             цвета и градиенты из Figma (≈ Appearance)
│   ├── fonts.dart                  текстовые стили, Plus Jakarta Sans (≈ Fonts)
│   ├── assets.dart                 пути к картинкам и иконкам
│   ├── analytics/otter_scale.dart  мост к нативному SDK OtterScale
│   ├── components/                 база ViewModel, переходы между экранами
│   ├── custom_views/               кнопки, карточки, чипы из Figma, TryAgainSheet
│   └── extensions/                 подписи значений профиля
├── transport/                      сеть (≈ RestAPITransport)
│   ├── api_request.dart            описание запроса (≈ APIRequestBody)
│   ├── api_transport.dart          интерфейс транспорта
│   ├── rest_api_transport.dart     настоящий сервер (dio)
│   ├── network_error.dart
│   └── mock/                       фейковый сервер; моки = контракт будущего API
│       └── routes/                 обработчики эндпоинтов по доменам
├── service/                        бизнес-логика (≈ Service)
│   ├── session/                    идентификаторы и подписка из OtterScale
│   ├── profile/                    ответы онбординга, хранятся на устройстве
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
| `MainViewController` + `TabView` + `MainViewCoordinator` | `MainScreen` + `MainTabBar` + `MainViewModel`         |
| `NavigationController` в табе                    | свой `Navigator` у вкладки; поверх таб-бара — `Navigator.of(context, rootNavigator: true)` |
| `lazy var manager = XxxManager()`                | менеджер из `Injector`, в тестах подменяется через конструктор |

Rx не используем: `Future`, `Stream` и `ChangeNotifier` встроены в Dart и Flutter, этого хватает.

## Ресурсы

- Шрифт Plus Jakarta Sans (OFL) — `assets/fonts/plus_jakarta_sans/`, из [tokotype/PlusJakartaSans](https://github.com/tokotype/PlusJakartaSans).
- 3D-иллюстрации и картинки — `assets/images/` (PNG @3x), иконки — `assets/icons/` (SVG); выгружены из Figma.

## OtterScale

Аналитика и подписки — через наш SDK OtterScale, как в Swift-приложениях. Dart-обёртка
`misc/analytics/otter_scale.dart` ходит в нативный код по каналу `dating_assistant/otter_scale`:

- iOS — под `OtterScaleiOS` (`ios/Podfile`), мост `ios/Runner/OtterScaleBridge.swift`;
- Android — `android/app/libs/otterscale.aar` (из car_connect) и `OtterScaleBridge.kt`.

SDK запускает `SessionManager.start()` на сплэше. Ключ приложения — `GlobalDefinitions.otterScaleApiKey`:
пока он пустой, SDK не запускается, а приложение работает без него.

Методы канала: `initialize`, `get_user_ids`, `has_active_subscription`, `get_subscriptions` (дата окончания,
пробный период и автопродление — для карточки плана в профиле), на Android ещё `save_purchase`.

## Покупки

Как в Swift-приложениях: `service/purchase/PurchaseManager` (≈ IAPManager + PaygateInteractor) покупает через
плагин `in_app_purchase`, а подписку подтверждает OtterScale:

- iOS — плагин переключён на StoreKit 1 (`PurchaseManager.registerStore`): его очередь слушает OtterScaleiOS,
  сам валидирует чек и присылает событие `receipt_validated`;
- Android — чек Google Play отдаём в OtterScale методом `save_purchase`, как в car_connect;
- магазин присылает покупки и без пейгейта (продления, незавершённые), поэтому `PurchaseManager.start()`
  слушает его с запуска приложения.

Пейгейт показывается после онбординга и на старте, если подписки нет. Id подписок, Terms и Privacy —
в `GlobalDefinitions` (пока пустые, с TODO).

## Моки

Пока сервера нет, `MockApiTransport` отправляет запросы в фейковый сервер (`transport/mock/`). Обработчики
работают с сырым JSON, как настоящий бэкенд, а данные хранятся в SharedPreferences и переживают перезапуск.

Как добавить эндпоинт:

1. Запрос — `service/<домен>/request/xxx_request.dart` (наследник `ApiRequest`).
2. Метод в `<домен>_manager.dart`: вызвать транспорт и распарсить модель.
3. Обработчик — `transport/mock/routes/<домен>_mock_routes.dart`, зарегистрировать в `MockServer`.

Формат ответов в моках — это контракт API: по нему потом напишем сервер.

Эндпоинты:

| Запрос             | Ответ                                       | Зачем                                              |
|--------------------|---------------------------------------------|----------------------------------------------------|
| `GET /api/v1/usage` | `{"generations": {"used": 2, "limit": 3}}` | бесплатные генерации на неделе — карточка плана в профиле |
| `POST /api/v1/analyses` `{"screenshot": "<base64 JPEG>"}` | разбор переписки, см. `ChatBreakdown.fromJson`; 402 — генерации кончились | «Upload screenshot» → «Chat breakdown» |
| `POST /api/v1/opening-lines` `{"spice", "you", "match"?, "profile_screenshot"?, "previous_lines"?}` | `{"id", "line", "match"?}` — в `match` то, что сервер прочитал в анкете; 402 — генерации кончились | Opening line |

Генерации (разбор, ответы коуча, первые фразы) считает сервер: 3 в неделю бесплатно, с понедельника заново.
Скриншоты сервер не хранит — в истории остаётся только разбор. Мок отвечает на любой скриншот примером из Figma
и считает всех пользователей бесплатными; настоящий сервер узнаёт о подписке через OtterScale.
