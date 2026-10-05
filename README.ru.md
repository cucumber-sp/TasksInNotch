# TasksInNotch

[English](README.md) | [Русский](README.ru.md)

Нативный таск-трекер для macOS рядом с вырезом экрана MacBook.
Простой список задач на день, прогресс при наведении и история по датам.

Интерфейс написан на SwiftUI, хранение — SwiftData.
[DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) отвечает за геометрию,
расположение и анимации панели. Версия закреплена на **1.1.0**.

## Как это работает

- **В покое:** счётчик и кольцо прогресса скрыты, ширина их содержимого свёрнута.
- **Наведение:** штатное увеличение показывает выполненные / все задачи слева и кольцо справа.
  Список не раскрывается, клавиатурный фокус остаётся в текущем приложении.
- **Клик в верхней области notch:** раскрывает или сворачивает список. При раскрытии поле ввода получает фокус.
- **Клик снаружи или переключение приложения:** сворачивает панель.
- **Список:** только невыполненные задачи на сегодня; высота шести строк, дальше — прокрутка.
- **Выполнение:** нажми на строку. Задача остаётся в истории, где её можно вернуть в невыполненные.
- **Добавление:** однострочное название, **Return** или **+**. Пустой ввод игнорируется.
- **История:** кнопка календаря открывает все задачи дня; поле даты и стрелки переключают дни.
- **Удаление:** контекстное меню строки.

Когда невыполненных задач нет, появляется «Все задачи на сегодня выполнены».
Задачи остаются на назначенной дате, автоматического переноса на следующий день нет.

Приложение работает без иконки в Dock. Меню в строке меню открывает задачи и историю,
переключает язык и завершает приложение. На экранах без выреза панель открывается из меню в floating-режиме кита.

## Языки

По умолчанию включён **английский**. Выбери **Language → Русский** в меню приложения.
Выбор сохраняется и меняет подписи, даты и названия для доступности. Названия задач остаются в исходном виде.

## Требования

- **macOS 14+** для приложения.
- **Xcode 26+** для сборки текущего проекта.
- MacBook с вырезом для notch-интерфейса; на остальных экранах доступна плавающая панель.

Проверено на Apple Silicon с Xcode 26.6 и macOS 26.6.2. Release-сборка включает Apple Silicon и Intel.

## Запуск через Xcode

```sh
git clone https://github.com/cucumber-sp/TasksInNotch.git
cd TasksInNotch
open TasksInNotch/TasksInNotch.xcodeproj
```

1. Дождись загрузки Swift Package Dependencies.
2. Выбери схему **TasksInNotch** и **My Mac**.
3. Укажи свою команду в **Signing & Capabilities**.
4. Нажми **⌘R**, затем наведи курсор на вырез или нажми на него.

### Release-сборка

Для локальной сборки с ad hoc-подписью:

```sh
xcodebuild \
  -project TasksInNotch/TasksInNotch.xcodeproj \
  -scheme TasksInNotch \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath .build/xcode \
  build CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

Скопируй `.build/xcode/Build/Products/Release/TasksInNotch.app` в `/Applications` для запуска без Xcode.

## Хранение данных

SwiftData сохраняет задачи в локальном контейнере сразу после добавления, изменения статуса или удаления.
CloudKit отключён; аккаунт и сервер не требуются.

Дата хранится как календарный день, прогресс учитывает выполненные и невыполненные задачи.
Идентификатор `com.cucumberspace.NotchTasks` сохраняется, чтобы переименование не меняло контейнер данных.

## Структура проекта

Исходники находятся в `TasksInNotch/TasksInNotch/`.

| Файл | Назначение |
| --- | --- |
| `TasksInNotchApp.swift` | Точка входа и меню macOS |
| `AppDelegate.swift` | Запуск, хранилище и окно истории |
| `NotchController.swift` | Клики, фокус и состояние наведения кита |
| `TaskViews.swift` | Счётчик, кольцо, список и ввод |
| `HistoryView.swift` | Все задачи и переключение дат |
| `AppLanguage.swift` | Выбор языка и локализованные строки |
| `TaskStore.swift` | Операции с задачами и сохранение |
| `TodoTask.swift` | Модель задачи и прогресс |

Геометрия и анимации раскрытия остаются внутри DynamicNotchKit.

Основная иконка — `TasksInNotch/TasksInNotch/tasksinnotch.icon`, редактируемый файл
[Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer).
В Debug и Release настройка App Icon указывает на `tasksinnotch`.

## Проверки

Три теста `TasksInNotchTests` проверяют прогресс и разделение дат, однострочный ввод и удаление,
а также повторное открытие файлового хранилища SwiftData. Тестовые targets требуют **macOS 26.5+**.

```sh
xcodebuild \
  -project TasksInNotch/TasksInNotch.xcodeproj \
  -scheme TasksInNotch \
  -destination 'platform=macOS' \
  -derivedDataPath .build/xcode \
  -only-testing:TasksInNotchTests \
  -parallel-testing-enabled NO \
  test CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES
```

Наведение, клик, фокус, язык и сворачивание проверяются в запущенном приложении.
Шаблонные UI-тесты Xcode пока не покрывают взаимодействие с notch.
