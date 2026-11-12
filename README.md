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
│   ├── history/                    история разборов, разговоров и фраз — только на устройстве (Hive)
│   ├── connectivity/               есть ли сеть (≈ Reachability)
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
| `POST /api/v1/coach/messages` `{"text"?, "tone", "spice", "you", "messages"?, "chat"?, "breakdown"?, "chat_screenshot"?}` | `{"id", "text", "suggestion"?: {"text", "why"?}, "quick_replies", "chat"?}` — в `chat` то, что сервер прочитал на скриншоте переписки; 400 — сообщение пустое; 402 — генерации кончились | Dating advice: чат с коучем |

Генерации (разбор, ответы коуча, первые фразы) считает сервер: 3 в неделю бесплатно, с понедельника заново.
Мок отвечает на любой скриншот примером из Figma и считает всех пользователей бесплатными; настоящий сервер
узнаёт о подписке через OtterScale.

Сервер ничего не хранит — ни скриншоты, ни разборы, ни разговоры: кроме счётчика генераций, в каждом запросе
есть всё нужное. Коучу клиент шлёт весь разговор до нового сообщения (`messages`: `{"from": "you" | "coach",
"text"?, "suggestion"?}`; сообщение пользователя без `text` — он приложил скриншот), карточку переписки (`chat`)
и разбор, из которого открыли коуча (`breakdown`, тот же JSON, что прислал `POST /api/v1/analyses`). Первым
фразам — уже предложенные фразы (`previous_lines`). Мок не учитывает тон и узнаёт тему по словам («ask them out»,
«stopped replying»), а «Give me another option» и «Make it bolder» относит к теме последнего ответа из `messages`.

## Сервер

`server/` — прокси к Gemini на Go (Gin + Genkit) по контракту моков: разбор, первые фразы и коуч. Как запустить,
проверить и выкатить — в [server/README.md](server/README.md). Проверка контракта с настоящим сервером —
`test/server_contract_test.dart`: без `--dart-define=CUE_SERVER_URL` она пропускается.

## История

Разборы, разговоры с коучем и фразы для мэтча хранятся только на устройстве — в Hive (`hive_ce`), ящик `history`
в Application Support. Запись — JSON-строка `{"kind", "updated_at", ...}` под своим id: модели пишутся и читаются
тем же toJson/fromJson, что и ответы сервера, и адаптеры Hive не нужны. Запись, которую не прочитать, пропускается.

В историю попадает то, что пользователь увидел: разбор — когда сканирование дошло до конца (остановленное ничего
не сохраняет), разговор — после каждого ответа коуча, фразы для одного мэтча — одной записью после каждой фразы.
Сохранение сообщает `HistoryMediator`, и вкладка History сразу перечитывает список; поиск — по всему списку.
В тестах история — ящик в памяти: `Injector.configure(historyBox: ...)`.

Удаление: свайп строки влево открывает корзину (открытой бывает одна строка, нажатие на строку или прокрутка
закрывают её), корзина спрашивает «Delete this conversation?», и после «Continue» запись удаляется. Около трёх
секунд плашка «Conversation deleted · Undo» может вернуть её: `HistoryManager.delete` отдаёт
`DeletedHistoryRecord` — сохранённую запись как есть, `restore` кладёт её обратно на то же место. VoiceOver
свайп не делает — у строки есть действие «Delete».
