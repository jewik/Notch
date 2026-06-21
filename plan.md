# План реализации Clipboard Manager для Notch

## 1. Цель

Реализовать полноценный локальный менеджер буфера обмена macOS, встроенный в существующую правую панель Notch.

Модуль должен:

- автоматически отслеживать изменения системного `NSPasteboard.general`;
- сохранять историю без потери исходных представлений данных;
- поддерживать одну операцию копирования с несколькими `NSPasteboardItem`;
- корректно работать с текстом, форматированным текстом, ссылками, изображениями, файлами, PDF и произвольными UTI/UTType;
- предоставлять быстрый поиск, превью, закрепление и удаление;
- позволять повторно скопировать элемент без дополнительных разрешений;
- при наличии Accessibility-разрешения вставлять выбранный элемент в ранее активное приложение;
- честно показывать недоступные превью и действия;
- не сохранять transient/concealed-содержимое и данные исключённых приложений;
- работать полностью локально, без облака и сторонних зависимостей.

## 2. Границы функционала

### Входит в первую полноценную версию

- наблюдение за системным pasteboard;
- локальная история с перезапуском приложения;
- дедупликация;
- полнотекстовый поиск;
- список, карточки и подробное превью;
- клавиатурная навигация;
- Copy, Paste, Delete, Pin/Unpin;
- очистка истории;
- лимиты хранения и автоматическая очистка;
- список исключённых приложений;
- безопасная обработка отсутствующих разрешений и повреждённых данных;
- миграции хранилища;
- тесты сервисов, хранилища и paste-flow.

### Не входит в первую версию

- синхронизация через iCloud;
- общий буфер между несколькими Mac;
- совместная история пользователей;
- OCR изображений;
- редактирование изображений, PDF или rich text;
- выполнение JavaScript из HTML;
- автоматическая загрузка содержимого URL из сети;
- бессрочное копирование содержимого исходных файлов в хранилище Notch;
- запись паролей или обход защит password manager-приложений.

## 3. Принципы реализации

1. `NSPasteboard` и AppKit используются только в сервисном слое.
2. SwiftUI отображает состояние и передаёт пользовательские действия во view model.
3. Хранилище не зависит от UI и системного pasteboard.
4. Каждое представление данных хранится с исходным type identifier.
5. Неизвестный тип не отбрасывается только потому, что Notch не умеет его показывать.
6. Никакое превью не должно выдавать себя за исходные данные.
7. Ошибка одного элемента не должна останавливать наблюдение за буфером.
8. Большие payload не должны декодироваться на main thread.
9. Все пользовательские данные остаются локально.
10. Реализация разбивается на небольшие вертикальные этапы, после каждого проект собирается.

## 4. Встраивание в текущий проект

Текущие `PanelController` и геометрия панели сохраняются. Clipboard становится содержимым раскрытой панели, а не новым AppKit-окном.

Предлагаемая структура:

```text
Notch/
├── Clipboard/
│   ├── Contracts/
│   │   ├── ClipboardControlling.swift
│   │   ├── ClipboardObserving.swift
│   │   ├── ClipboardStoring.swift
│   │   └── ClipboardPasting.swift
│   ├── Models/
│   │   ├── ClipboardCapture.swift
│   │   ├── ClipboardItem.swift
│   │   ├── ClipboardRepresentation.swift
│   │   ├── ClipboardContentKind.swift
│   │   └── ClipboardSearchQuery.swift
│   ├── Services/
│   │   ├── PasteboardObserver.swift
│   │   ├── PasteboardSnapshotReader.swift
│   │   ├── ClipboardContentClassifier.swift
│   │   ├── ClipboardDeduplicator.swift
│   │   ├── ClipboardPasteController.swift
│   │   ├── ClipboardPreviewService.swift
│   │   └── ClipboardRetentionService.swift
│   ├── Storage/
│   │   ├── ClipboardDatabase.swift
│   │   ├── ClipboardBlobStore.swift
│   │   ├── ClipboardSearchIndex.swift
│   │   └── ClipboardMigration.swift
│   ├── ViewModels/
│   │   ├── ClipboardViewModel.swift
│   │   ├── ClipboardItemViewModel.swift
│   │   └── ClipboardSettingsViewModel.swift
│   └── Views/
│       ├── ClipboardView.swift
│       ├── ClipboardListView.swift
│       ├── ClipboardCardView.swift
│       ├── ClipboardPreviewView.swift
│       ├── ClipboardEmptyView.swift
│       └── ClipboardSettingsView.swift
├── PanelController.swift
├── PanelView.swift
└── AppCoordinator.swift
```

`AppCoordinator` создаёт сервисы Clipboard, запускает observer, передаёт `ClipboardViewModel` в `PanelView` и останавливает observer при завершении приложения.

## 5. Контракты

Основной фасад модуля:

```swift
@MainActor
protocol ClipboardControlling: AnyObject {
    var viewModel: ClipboardViewModel { get }

    func start()
    func stop()
    func openClipboard()
    func copy(captureID: UUID)
    func paste(captureID: UUID)
    func delete(captureID: UUID)
    func setPinned(_ isPinned: Bool, captureID: UUID)
}
```

Внутренние контракты должны разделять:

- чтение `NSPasteboard`;
- хранение и запросы;
- генерацию превью;
- запись обратно в pasteboard;
- восстановление исходного приложения и отправку Paste;
- retention/cleanup;
- проверку разрешений.

Это позволит тестировать модуль без реального pasteboard и позднее заменить отдельные реализации без изменения панели.

## 6. Модель одной операции копирования

Одна операция копирования не равна одному типу данных. Pasteboard может содержать несколько items, а каждый item — несколько представлений одного содержимого.

```text
ClipboardCapture
└── items: [ClipboardItem]
    └── representations: [ClipboardRepresentation]
```

### ClipboardCapture

- `id: UUID`;
- `createdAt` и `lastCopiedAt`;
- `sourceBundleIdentifier` и отображаемое имя приложения;
- `sourceProcessIdentifier`, если доступен;
- `changeCount` исходного pasteboard;
- `itemCount`;
- `primaryKind`;
- `displayTitle`, `searchableText`;
- `exactHash`;
- `semanticHash`;
- `copyCount`;
- `isPinned`;
- `isSensitive`;
- `expiresAt`;
- `totalByteCount`;
- состояние доступности внешних файлов;
- состояние генерации превью.

### ClipboardItem

- порядковый индекс внутри capture;
- основной распознанный тип;
- набор исходных representations;
- метаданные: filename, dimensions, page count, duration, URL host и т. п.;
- ссылка на preview blob, если он создавался.

### ClipboardRepresentation

- исходный строковый type identifier;
- нормализованный `UTType`, если он известен системе;
- размер;
- способ хранения: inline/blob/external reference;
- SHA-256 содержимого;
- приоритет для восстановления pasteboard;
- флаг, можно ли безопасно индексировать содержимое.

## 7. Поддерживаемые варианты содержимого

### 7.1 Обычный текст

- `public.utf8-plain-text`;
- `public.utf16-plain-text` и другие текстовые кодировки;
- `NSPasteboard.PasteboardType.string`;
- многострочный текст;
- Unicode, emoji, RTL-текст;
- исходный тип и исходные bytes сохраняются, а для поиска создаётся нормализованная UTF-8 строка.

Превью: текст с ограничением числа строк, определением очень длинных строк и без исполнения содержимого.

### 7.2 Форматированный текст

- RTF;
- RTFD;
- `NSAttributedString`-совместимые представления;
- HTML;
- HTML fragment и сопутствующий plain-text fallback.

Хранить исходные representations вместе. Для поиска извлекать только видимый текст. HTML не должен исполнять JavaScript, загружать внешние ресурсы или открываться в активном WebView. Превью строить безопасным нативным преобразованием в attributed string.

### 7.3 URL и ссылки

- обычный URL;
- URL, скопированный как plain text;
- несколько URL в одной операции;
- `mailto`, `tel`, custom schemes;
- file URL обрабатывается отдельно как файл.

Хранить оригинальную строку, нормализованную строку, scheme, host и display title. Не выполнять сетевые запросы ради метаданных. Действия `Open` и `Copy URL` должны быть отдельными и явными.

### 7.4 Файлы и папки

- один или несколько file URL;
- папки;
- aliases/symlinks;
- Finder-specific representations;
- имена, расширения, размеры и даты, если они доступны;
- security-scoped bookmark, если sandbox предоставляет доступ и bookmark можно создать;
- fallback на исходный URL без обещания бессрочного доступа.

Notch не должен молча копировать содержимое всех файлов в свою базу. История хранит references и небольшие thumbnails. Если файл перемещён, удалён или permission extension истёк, UI показывает `Файл недоступен`, но запись истории не вызывает crash.

### 7.5 Изображения

- PNG;
- TIFF;
- JPEG/JPEG 2000;
- HEIC/HEIF;
- GIF, включая анимированный оригинал;
- WebP и другие типы, которые распознаёт системный `UTType`/ImageIO;
- несколько representations одного изображения;
- изображение вместе с file URL или HTML fallback.

Хранить оригинальные bytes без перекодирования. Для списка генерировать отдельный ограниченный thumbnail. Индексировать filename и доступные метаданные, но не выполнять OCR в первой версии.

### 7.6 PDF и документы

- PDF bytes;
- PDF как file URL;
- текстовое представление PDF, если оно уже присутствует в pasteboard;
- EPS/PostScript и документы, для которых Quick Look может создать thumbnail;
- офисные и iWork-файлы как file URL.

Для PDF использовать PDFKit/Quick Look для page count и thumbnail. Не индексировать весь большой документ синхронно; извлечение текста должно иметь лимит размера и времени.

### 7.7 Табличные и структурированные данные

- tab-separated values;
- CSV;
- JSON;
- XML/plist;
- source code;
- tabular text из Numbers/Excel вместе с rich representations.

Основная гарантия — сохранение всех исходных representations. Специализированное превью возможно после MVP; первая версия показывает безопасное текстовое превью и корректно восстанавливает исходный pasteboard.

### 7.8 Контакты, календарь и цвета

- vCard/contact data;
- calendar event representations;
- `NSColor`/color representations;
- location/map URLs;
- другие системные типы, для которых доступен UTType.

Если специализированного renderer нет, использовать metadata/raw fallback и не объявлять содержимое неподдерживаемым для повторного копирования.

### 7.9 Аудио и видео

- media files как file URL;
- inline audio/video representations, если они фактически присутствуют;
- длительность, codec и thumbnail извлекать асинхронно через AVFoundation только в пределах лимитов.

Первая версия не проигрывает медиа автоматически. Preview показывает метаданные и poster frame, если их можно получить безопасно.

### 7.10 Произвольные и custom types

Pasteboard открыт для vendor-specific и dynamic UTI. Невозможно заранее перечислить абсолютно все варианты, поэтому применяется универсальное правило:

1. сохранить identifier и bytes каждого доступного representation;
2. не декодировать неизвестные данные как текст без подтверждённого conformance;
3. ограничить максимальный размер;
4. показать generic card с названием типа и размером;
5. при повторном Copy восстановить исходный тип и bytes;
6. если данные lazy/promised и не успели материализоваться, сохранить честное состояние `representationUnavailable`.

Таким образом поддержка не ограничивается жёстким enum известных форматов.

## 8. Чтение pasteboard

У `NSPasteboard` нет надёжного push-события для всех изменений. Observer использует `changeCount`:

- проверка каждые 300–500 мс;
- timer работает в `.common` run loop mode;
- если `changeCount` не изменился, данные не читаются;
- снимок `pasteboardItems` и их types создаётся сразу после изменения;
- lazy representations материализуются как можно раньше, пока приложение-владелец доступно;
- тяжёлая классификация, hashing, запись blobs и previews выполняются вне main thread;
- при sleep/wake и смене пользователя observer корректно возобновляется;
- повторный `start()` не создаёт второй timer.

Чтение одной операции должно быть атомарным: либо сохраняется согласованный capture, либо операция отклоняется с диагностикой. Если `changeCount` изменился во время чтения, snapshot повторяется ограниченное число раз.

## 9. Исключение чувствительных данных

Перед сохранением проверять:

- `org.nspasteboard.TransientType`;
- `org.nspasteboard.ConcealedType`;
- `org.nspasteboard.AutoGeneratedType`;
- другие общеупотребимые marker types password manager-приложений;
- bundle identifier источника по пользовательскому denylist;
- превышение лимитов размера;
- пользовательский режим `Pause History`.

Правила:

- concealed/transient capture не попадает ни в БД, ни в логи, ни в thumbnails;
- содержимое не логируется даже в Debug;
- denylist должен поддерживать добавление приложения через выбор из запущенных/установленных приложений;
- опциональный TTL для потенциально чувствительных записей;
- pinned entries не удаляются retention-политикой, но пользователь может удалить их вручную;
- очистка удаляет строки БД, blobs и previews.

Автоматическое определение пароля по тексту ненадёжно и не должно быть единственным защитным механизмом.

## 10. Дедупликация

Использовать два SHA-256 hash:

- `exactHash`: type identifier + исходные bytes всех representations всех items в стабильном порядке;
- `semanticHash`: нормализованное основное содержимое, например текст без различий кодировки или canonical URL.

Правила:

- одинаковый `exactHash` обновляет `lastCopiedAt`, увеличивает `copyCount` и поднимает запись вверх;
- pinned-состояние сохраняется;
- одинаковый plain text с разным rich formatting не должен автоматически терять форматирование;
- несколько файлов сравниваются с учётом порядка и URL;
- self-write из Notch не создаёт дубль: `ClipboardPasteController` запоминает ожидаемый `changeCount` и hash;
- hash больших blobs считается streaming-способом.

## 11. Хранение

Рекомендуемая структура:

```text
~/Library/Application Support/Notch/
├── clipboard.sqlite
├── clipboard.sqlite-wal
├── clipboard.sqlite-shm
├── blobs/
│   └── <sha256-prefix>/<sha256>
└── previews/
    └── <capture-id>-<item-index>.<extension>
```

Использовать системный SQLite (`SQLite3`), без стороннего ORM.

### Основные таблицы

- `captures`;
- `items`;
- `representations`;
- `blobs` с reference count;
- `source_apps`;
- `schema_migrations`;
- FTS5-таблица для searchable text, title, URL host, filename и source app.

### Стратегия payload

- маленькие данные до настраиваемого порога хранятся inline;
- крупные данные хранятся content-addressed в `blobs/`;
- одинаковые blobs физически хранятся один раз;
- запись blob выполняется через временный файл и atomic rename;
- БД использует WAL и foreign keys;
- удаление capture уменьшает reference count и удаляет orphan blobs;
- при старте выполняется лёгкая проверка целостности и уборка orphan temp files.

### Миграции

- каждая версия схемы имеет последовательный номер;
- миграция выполняется transactionally;
- при невозможности миграции существующая база не перезаписывается;
- создаётся диагностическая ошибка и модуль переходит в безопасное read-only/unavailable состояние;
- UI панели и остальные функции Notch продолжают работать.

## 12. Лимиты и retention

Настройки по умолчанию, уточняемые после профилирования:

- максимум 2 000–5 000 captures;
- общий storage budget 1–2 ГБ;
- предупреждение/отказ для одного inline payload свыше 100 МБ;
- thumbnail не более 512 px по длинной стороне;
- preview-текст ограничивается по символам;
- автоматическая очистка по возрасту: Never / 1 день / 7 дней / 30 дней / 90 дней;
- pinned entries исключаются из автоочистки;
- очистка запускается после записи и при старте, но не блокирует UI.

При превышении лимита запись должна показывать понятный unavailable reason, а не падать и не читать гигабайты в память.

## 13. Поиск

Поиск должен работать по:

- plain text и извлечённому видимому тексту rich content;
- URL и host;
- именам файлов и расширениям;
- source app;
- типу содержимого;
- дате;
- pinned status.

Поддержать:

- быстрый debounce 100–150 мс;
- FTS prefix search;
- фильтры `Text`, `Images`, `Files`, `Links`, `PDF`, `Other`, `Pinned`;
- сортировку по `lastCopiedAt` с pinned-first режимом;
- пустой запрос без полного FTS scan;
- пагинацию/cursor loading;
- подсветку совпадений без изменения исходного текста.

## 14. Превью

`ClipboardPreviewService` выбирает renderer по conformance UTType, а не только по строковому совпадению identifier.

Приоритеты:

1. специализированное безопасное превью;
2. Quick Look thumbnail для файлов;
3. metadata card;
4. generic type/size card.

Renderer-ы:

- text/attributed text;
- URL;
- image через ImageIO/NSImage;
- PDF через PDFKit;
- file/folder через QuickLookThumbnailing;
- color swatch;
- audio/video metadata через AVFoundation;
- unknown data.

Preview cache отделён от оригинальных blobs. Ошибка preview не делает capture недоступным для Copy.

## 15. UI панели

В полностью раскрытом `PanelView` показывать `ClipboardView`:

```text
Header: Clipboard + Settings
Search field
Filter chips
Scrollable history
Selected-item preview
Footer/commands
```

Карточка истории содержит:

- иконку типа;
- безопасный thumbnail или text snippet;
- source app;
- относительное время;
- item count для multi-item capture;
- pin indicator;
- unavailable/sensitive status;
- context menu.

Состояния UI:

- loading;
- empty history;
- empty search result;
- capture unavailable;
- storage unavailable;
- permission missing для автоматической вставки;
- history paused;
- normal list.

Unsupported actions должны быть disabled с понятным help-текстом.

## 16. Клавиатурный UX и фокус

Текущая `OverlayPanel` является `.nonactivatingPanel` и не становится key window. Это правильно для обычного Peek/Show, но поле поиска не сможет честно получать ввод без изменения режима.

Нужны два режима:

### Passive panel mode

- обычный hover/menu toggle;
- активное приложение не теряет фокус;
- просмотр мышью и Copy доступны;
- глобальный ввод не перехватывается.

### Clipboard interaction mode

Запускается отдельным Clipboard hotkey:

1. запомнить `NSWorkspace.shared.frontmostApplication`;
2. раскрыть панель на активном экране;
3. временно разрешить панели становиться key;
4. сфокусировать search field;
5. выбрать последний capture;
6. после Paste/Cancel вернуть исходное приложение;
7. вернуть панели non-activating режим;
8. закрыть панель согласно настройке.

Для этого `OverlayPanel.canBecomeKey` должен зависеть от явно управляемого interaction mode. AppKit-логика остаётся в `PanelController`, а SwiftUI только сообщает `beginInteraction`, `paste`, `cancel`.

Клавиши:

- Up/Down — выбор;
- Enter — Paste, если разрешено, иначе Copy;
- Command+Enter — Copy without paste;
- Escape — закрыть и восстановить приложение;
- Command+F — search;
- Delete — удалить после безопасной обработки;
- Command+P — Pin/Unpin;
- Command+Shift+C — Copy only;
- Space — Quick Look/expanded preview.

## 17. Повторное Copy и автоматический Paste

### Copy

1. загрузить все items и representations;
2. вызвать `pasteboard.clearContents()`;
3. восстановить массив `NSPasteboardItem` с исходными identifiers и bytes;
4. записать items одной операцией;
5. зарегистрировать self-write hash/changeCount;
6. не создавать новый дубль истории.

Copy не требует Accessibility.

### Paste

1. выполнить Copy;
2. активировать ранее сохранённое приложение;
3. дождаться подтверждения activation с коротким timeout;
4. отправить Command+V через `CGEvent`;
5. закрыть/свернуть панель;
6. при ошибке оставить данные в pasteboard и показать: `Скопировано, вставьте вручную`.

Отправка Command+V требует Accessibility. При отсутствии разрешения действие Paste не симулируется и не падает: UI предлагает открыть System Settings либо использовать Copy-only.

## 18. Настройки Clipboard

- Enable Clipboard History;
- история paused/resume;
- максимальное число записей;
- storage budget;
- срок хранения;
- сохранять изображения;
- сохранять большие payload;
- сохранять file references;
- excluded applications;
- показывать source app;
- поведение после Copy/Paste;
- hotkey Clipboard;
- кнопки `Clear Unpinned`, `Clear All` с подтверждением;
- текущий размер хранилища;
- Accessibility status;
- диагностический статус БД без вывода пользовательского содержимого.

Простые настройки хранить в `UserDefaults`; историю и metadata — только в Clipboard database.

## 19. Concurrency

- UI и взаимодействие с окнами — `@MainActor`;
- `NSPasteboard` snapshot читается контролируемо на main thread, потому что AppKit не считается полностью thread-safe;
- database и blob operations — отдельный actor/serial executor;
- preview generation — ограниченная task queue;
- один capture pipeline за раз, более новый `changeCount` ставится в очередь;
- отмена preview/search task при исчезновении элемента;
- никакой синхронной работы с большими blobs в SwiftUI `body`.

## 20. Ошибки и диагностика

Типизированные ошибки:

- pasteboard changed during read;
- representation unavailable;
- unsupported/invalid encoding;
- payload too large;
- database unavailable/corrupted;
- blob write/read failed;
- file reference expired;
- permission missing;
- source app unavailable;
- paste activation timeout.

Логи через `OSLog` содержат только category, identifier, размеры, длительность и код ошибки. Текст, URL, filenames, raw bytes и thumbnails в лог не записываются.

Ошибка Clipboard-модуля не должна ломать panel, hotkey toggle или завершение приложения.

## 21. Тестирование

### Unit tests

- классификация всех известных типов;
- unknown/custom type fallback;
- multi-item capture;
- exact/semantic hash;
- дедупликация и pinned behavior;
- transient/concealed filtering;
- limits и retention;
- search normalization;
- database migrations;
- orphan blob cleanup;
- self-write suppression;
- unavailable file handling;
- paste fallback без Accessibility.

### Fixture-набор

- ASCII/Unicode/emoji/RTL text;
- RTF/RTFD/HTML;
- URL/custom URL scheme;
- PNG/TIFF/JPEG/HEIC/GIF/WebP;
- PDF;
- один и несколько файлов/папок;
- CSV/JSON/XML/source code;
- vCard/color;
- несколько items с несколькими representations;
- custom dynamic UTI;
- corrupted/truncated data;
- payload на границе лимита.

### Integration tests

- внешний app → copy → запись появляется;
- restart → история сохранена;
- Copy from history восстанавливает types и items;
- Notch self-write не создаёт дубль;
- Paste возвращается в исходное приложение;
- отказ Accessibility даёт Copy-only fallback;
- ignored app не сохраняется;
- удалённый файл показывает unavailable;
- очистка удаляет blobs;
- панель остаётся работоспособной при ошибке БД.

### Manual verification

- Finder, Safari, TextEdit, Preview, Photos, Numbers/Excel, Xcode;
- password managers с transient/concealed markers;
- несколько дисплеев и Spaces;
- full-screen приложения;
- большие изображения и PDF;
- sleep/wake;
- быстрое последовательное копирование;
- смена приложения во время paste-flow.

## 22. Этапы реализации

### Этап 1 — модели и протоколы

- добавить модели capture/item/representation;
- определить storage/observer/paste contracts;
- добавить mock repository;
- показать пустой `ClipboardView` в существующей панели.

Критерий: проект собирается, панель показывает честное empty state.

### Этап 2 — наблюдение и in-memory history

- реализовать `changeCount` observer;
- snapshot нескольких items/representations;
- transient/concealed filters;
- classifier и exact hash;
- временный in-memory repository.

Критерий: текст, URL, изображения и файлы появляются без persistence.

### Этап 3 — постоянное хранилище

- SQLite schema и migrations;
- blob store;
- atomic transaction pipeline;
- startup recovery;
- retention basics.

Критерий: история переживает restart, удаление чистит связанные blobs.

### Этап 4 — список и базовые действия

- list/card UI;
- selection;
- Copy, Delete, Pin;
- context menu;
- pagination.

Критерий: все действия работают мышью без Accessibility.

### Этап 5 — превью всех категорий

- text/rich text/HTML;
- URL;
- image;
- PDF;
- file Quick Look;
- audio/video metadata;
- generic custom type fallback.

Критерий: ошибка renderer не мешает повторному Copy.

### Этап 6 — поиск

- searchable text extraction;
- FTS5;
- filters;
- debounce и pagination;
- keyboard selection.

Критерий: поиск не блокирует UI на максимальном объёме истории.

### Этап 7 — interaction mode и Paste

- отдельный Clipboard hotkey;
- сохранение frontmost app;
- временный key mode панели;
- фокус search;
- Accessibility check;
- restore app + Command+V;
- Copy-only fallback.

Критерий: обычный показ панели не забирает фокус, Clipboard mode корректно возвращает его.

### Этап 8 — settings, privacy и limits

- UserDefaults settings;
- excluded apps;
- pause/resume;
- storage stats;
- clear actions;
- expiry/size cleanup;
- permission guidance.

Критерий: чувствительные marker types не сохраняются, лимиты соблюдаются.

### Этап 9 — hardening

- fixtures и unit tests;
- integration/manual matrix;
- performance profiling;
- corrupted DB/blob recovery;
- rapid-copy stress test;
- memory and disk audit.

Критерий: все критерии готовности ниже выполнены или имеют документированное ограничение.

## 23. Критерии готовности

- История автоматически фиксирует изменения `NSPasteboard.general`.
- Одна операция с несколькими items сохраняется и восстанавливается без схлопывания.
- Известные типы имеют корректные превью.
- Неизвестные типы сохраняют identifier и raw representation в пределах лимита.
- Plain text, rich text, HTML, URL, image, PDF и file references проходят round-trip Copy.
- История переживает restart.
- Дубликаты обрабатываются предсказуемо и не размножаются после self-write.
- Поиск работает по тексту, URL, filename и source app.
- Copy работает без Accessibility.
- Paste либо вставляет в исходное приложение, либо честно оставляет Copy-only fallback.
- Transient/concealed data не попадает в БД и логи.
- Игнорируемые приложения не сохраняются.
- Большие и повреждённые данные не блокируют UI и не вызывают crash.
- Удаление и retention очищают orphan blobs.
- Pinned entries не удаляются автоматически.
- Обычное появление панели не забирает фокус.
- Clipboard interaction mode возвращает фокус исходному приложению.
- Ошибка Clipboard не ломает остальную панель Notch.
- Нет сторонних зависимостей.
- Проект собирается после каждого этапа.

## 24. Порядок приоритетов

Если реализацию нужно сокращать, приоритет следующий:

1. безопасное наблюдение и privacy filters;
2. lossless capture нескольких items/representations;
3. надёжное хранилище и round-trip Copy;
4. список, Delete и Pin;
5. поиск;
6. превью;
7. автоматический Paste;
8. расширенные metadata и специализированные renderer-ы.

Главная гарантия модуля — не красивое превью, а безопасное и максимально полное восстановление исходного содержимого pasteboard.
