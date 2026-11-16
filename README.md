# Cue — Dating Assistant

Flutter-приложение для iOS и Android: AI-коуч для переписки в знакомствах — разбирает чат, показывает,
как развиваются отношения, и пишет следующее сообщение голосом пользователя.

Макет: [Figma](https://www.figma.com/design/plPqacnfO51V0VyG4cxlW1/Dating-Assistant).

## Запуск

```bash
flutter pub get
flutter run
```

Приложение ходит на наш сервер (`server/`, развёрнут на машине команды): `https://cue.korrekted.com`.
Локальный сервер с Mac — по адресу:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

Анализатор:

```bash
flutter analyze
```

## Архитектура

Слои как в Swift-проектах: **Transport → Service → Presentation**. Зависимости идут только в одну сторону:
экран не ходит в транспорт напрямую, сервис ничего не знает про экраны.

```
lib/
├── main.dart                       точка входа
├── misc/                           общее (≈ Misc)
│   ├── app.dart                    корневой виджет: тема, стартовый экран
│   ├── injector.dart               сборка зависимостей
│   ├── global_definitions.dart     адрес API, ключи OtterScale и Amplitude, ссылки
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
│   ├── rest_api_transport.dart     наш сервер (dio)
│   └── network_error.dart
├── service/                        бизнес-логика (≈ Service)
│   ├── session/                    идентификаторы и подписка из OtterScale
│   ├── analytics/                  события в Amplitude
│   ├── consent/                    согласие на передачу данных ИИ
│   ├── usage/                      бесплатные генерации: счётчик на устройстве
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
| `lazy var manager = XxxManager()`                | менеджер из `Injector`; через конструктор можно передать другой |

Rx не используем: `Future`, `Stream` и `ChangeNotifier` встроены в Dart и Flutter, этого хватает.

## Ресурсы

- Шрифт Plus Jakarta Sans (OFL) — `assets/fonts/plus_jakarta_sans/`, из [tokotype/PlusJakartaSans](https://github.com/tokotype/PlusJakartaSans).
- 3D-иллюстрации и картинки — `assets/images/` (PNG @3x), иконки — `assets/icons/` (SVG); выгружены из Figma.

## OtterScale

Аналитика и подписки — через наш SDK OtterScale, как в Swift-приложениях. Dart-обёртка
`misc/analytics/otter_scale.dart` ходит в нативный код по каналу `dating_assistant/otter_scale`:

- iOS — под `OtterScaleiOS` (`ios/Podfile`), мост `ios/Runner/OtterScaleBridge.swift`;
- Android — `android/app/libs/otterscale.aar` (из car_connect) и `OtterScaleBridge.kt`.

SDK запускает `SessionManager.start()` на сплэше. Ключ приложения — `GlobalDefinitions.otterScaleApiKey`;
с пустым ключом SDK не запускается, а приложение работает без него.

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
в `GlobalDefinitions`; id подписок пока пустые, с TODO.

## API

Приложение ходит на сервер из `server/` через `RestApiTransport`. Как добавить эндпоинт:

1. Запрос — `service/<домен>/request/xxx_request.dart` (наследник `ApiRequest`).
2. Метод в `<домен>_manager.dart`: вызвать транспорт и распарсить модель.
3. Обработчик на сервере — `server/api`, флоу с промптом — `server/flows`.

Эндпоинты:

| Запрос             | Ответ                                       | Зачем                                              |
|--------------------|---------------------------------------------|----------------------------------------------------|
| `POST /api/v1/analyses` `{"screenshot": "<base64 JPEG>"}` | разбор переписки, см. `ChatBreakdown.fromJson`; 422 — на скриншоте не переписка | «Upload screenshot» → «Chat breakdown» |
| `POST /api/v1/opening-lines` `{"spice", "you", "match"?, "profile_screenshot"?, "previous_lines"?}` | `{"id", "line", "match"?}` — в `match` то, что сервер прочитал в анкете | Opening line |
| `POST /api/v1/coach/messages` `{"text"?, "tone", "spice", "you", "messages"?, "chat"?, "breakdown"?, "chat_screenshot"?}` | `{"id", "text", "suggestion"?: {"text", "why"?}, "quick_replies", "chat"?}` — в `chat` то, что сервер прочитал на скриншоте переписки; 400 — сообщение пустое | Dating advice: чат с коучем |

Сервер ничего не хранит — ни скриншоты, ни разборы, ни разговоры, ни счётчик генераций: в каждом запросе
есть всё нужное. Коучу клиент шлёт весь разговор до нового сообщения (`messages`: `{"from": "you" | "coach",
"text"?, "suggestion"?}`; сообщение пользователя без `text` — он приложил скриншот), карточку переписки (`chat`)
и разбор, из которого открыли коуча (`breakdown`, тот же JSON, что прислал `POST /api/v1/analyses`). Первым
фразам — уже предложенные фразы (`previous_lines`).

## Аналитика

Amplitude — как в Swift-приложениях (`AmplitudeManager`) и во Flutter-приложении car_play_sync:
`service/analytics/AnalyticsManager` на плагине `amplitude_flutter`. Проект в Amplitude общий для приложений студии
(ключ `GlobalDefinitions.amplitudeApiKey`), поэтому у каждого события есть свойство `app` — метка
`GlobalDefinitions.applicationTag` (`DATING_ASSISTANT`) — и `anonymous_id` из OtterScale.

| Событие | Когда |
|---|---|
| `First Launch` | первый запуск, один раз |
| `Paygate Screen` | показался пейгейт — полноэкранный или шторка Plus |
| `Home Screen` | показалась главная |
| `UserIDSynced` | OtterScale узнал внутренний id пользователя (после проверки чека): он становится user id в Amplitude, событие — один раз на каждый новый id |

Amplitude запускается со сплэша после OtterScale — событиям нужен `anonymous_id`; до запуска события никуда
не уходят.

## Согласие на ИИ

Перед первым запросом к ИИ приложение спрашивает согласие на передачу переписок (правило App Review 5.1.2(i)),
экран — Figma 480:3341. `service/consent/AiConsentManager` хранит ответ, а менеджеры разбора, коуча и фраз
вызывают `ensureGranted()` перед каждым запросом: без согласия запрос не уходит. Спросить пользователя сервис
сам не может, поэтому экран показывает `askUser` — его ставит `MainScreen`, под которым живут все функции с ИИ.

- «Allow and continue» — согласие запоминается, запрос уходит; разбор спрашивает ещё до галереи.
- «Not now» — ничего не отправлено, и это не ошибка: экран просто останавливается (`AiConsentDeclined`),
  сообщение коуча возвращается в поле, экран первой фразы закрывается, а сверху плашка
  «Nothing was sent. Allow AI when you're ready».
- Профиль → «AI & privacy» (Figma 484:3499): согласие можно выключить — следующий запрос спросит снова;
  «Delete my data» после вопроса стирает историю, ответы с онбординга и согласие и начинает с онбординга.
  Подписка и счётчик бесплатных генераций остаются.

Тексты «How it works» поправлены против макета: переписки разбирает Google Gemini, а не OpenAI, а импорта
переписки файлом в приложении нет.

## Бесплатные генерации

Без Cue Plus — 3 генерации в неделю на всё вместе: разборы, ответы коуча и первые фразы, с понедельника по времени
телефона заново. Считает приложение, сервер о лимите не знает: `service/usage/UsageManager` проверяет счётчик
перед запросом (`checkLimit`, кончились — `GenerationLimitReached`, экран предлагает Cue Plus) и засчитывает
генерацию после ответа (`recordGeneration`), так что неудачная не тратится. С Cue Plus лимита нет и генерации
не считаются: если подписка кончится, у пользователя будут обычные три бесплатные.

Счётчик лежит на устройстве (`DeviceUsageStorage`): на iOS — в Keychain через `flutter_secure_storage`, его записи
система не удаляет вместе с приложением, и переустановка не возвращает бесплатные генерации; на Android —
в SharedPreferences, они стираются при удалении.

## Сервер

`server/` — прокси к Gemini на Go (Gin + Genkit): разбор, первые фразы и коуч. Как запустить, проверить
и выкатить — в [server/README.md](server/README.md).

## История

Разборы, разговоры с коучем и фразы для мэтча хранятся только на устройстве — в Hive (`hive_ce`), ящик `history`
в Application Support. Запись — JSON-строка `{"kind", "updated_at", ...}` под своим id: модели пишутся и читаются
тем же toJson/fromJson, что и ответы сервера, и адаптеры Hive не нужны. Запись, которую не прочитать, пропускается.

В историю попадает то, что пользователь увидел: разбор — когда сканирование дошло до конца (остановленное ничего
не сохраняет), разговор — после каждого ответа коуча, фразы для одного мэтча — одной записью после каждой фразы.
Сохранение сообщает `HistoryMediator`, и вкладка History сразу перечитывает список; поиск — по всему списку.

Удаление: свайп строки влево открывает корзину (открытой бывает одна строка, нажатие на строку или прокрутка
закрывают её), корзина спрашивает «Delete this conversation?», и после «Continue» запись удаляется. Около трёх
секунд плашка «Conversation deleted · Undo» может вернуть её: `HistoryManager.delete` отдаёт
`DeletedHistoryRecord` — сохранённую запись как есть, `restore` кладёт её обратно на то же место. VoiceOver
свайп не делает — у строки есть действие «Delete».
