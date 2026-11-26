# OTKAT Games — отчёт о работе на 27.11.2026

## Основные ссылки

- [Сайт OTKAT Games](https://otkat628.github.io/otkat-games/)
- [Репозиторий и архив исходников](https://github.com/OTKAT628/otkat-games)
- [Каталог игр на сайте](https://otkat628.github.io/otkat-games/games/)
- [Каталог приложений](https://otkat628.github.io/otkat-games/apps/)
- [Driftline: Apex Circuit](https://otkat628.github.io/otkat-games/driftline/)
- [Исходники Driftline](https://github.com/OTKAT628/otkat-games/tree/main/web/driftline)
- [Общий 3D-прототип](https://github.com/OTKAT628/otkat-games/tree/main/web/prototype-3d)
- [Описание коллекций мини-игр](https://github.com/OTKAT628/otkat-games/blob/main/docs/APP_COLLECTIONS.md)
- [Полный отчёт и продолжение AI Team](https://github.com/OTKAT628/otkat-ai-team/blob/feature/android-chat-control-ui/docs/DAILY_HANDOFF_2026-11-27.md)

## Что сделано

- Сайт разделён на каталоги Games и Apps.
- В каталоге — десять отдельных игровых проектов и пять приложений-сборников мини-игр.
- Для Driftline добавлен интерактивный 3D-гараж и расширен выбор до двенадцати вымышленных автомобилей.
- В 3D-гараже можно просматривать модели, менять окраску и выбирать разные концепты кузова.
- В workflow публикации сайта добавлена проверка JavaScript, включая встроенный скрипт Driftline.
- Последний проверенный запуск публикации OTKAT Games завершился успешно: [GitHub Actions](https://github.com/OTKAT628/otkat-games/actions).

## Важные ограничения

- Driftline пока не полноценная 3D-гонка: гоночный режим остаётся top-down 2D-style прототипом, 3D сейчас реализован в гараже.
- Hide and Seek и Survival остаются прототипами, их нужно углублять и тестировать.
- Локальные рекорды и сохранения не являются глобальным рейтингом или облачной синхронизацией.
- OTKAT ID, онлайн-мультиплеер, общий чат, друзья, глобальные таблицы лидеров и донаты ещё не подключены.
- APK/установщики игр не подтверждены готовыми к скачиванию.
- Внешние модели автомобилей добавлять только после проверки прав на использование; приоритет — оригинальные 3D-модели.

## Приоритет разработки

1. Hide and Seek — довести игровой цикл, карты, AI, режимы и сохранения.
2. Survival — довести выживание, прогрессию, окружение и баланс.
3. Driftline — сделать полноценную 3D-гонку с управлением автомобилем, физикой, камерами, трассами и гаражом.
4. Выбрать и отполировать несколько сборников мини-игр с полноценной офлайн-работой.
5. После OTKAT ID добавить облачные сохранения и отдельные глобальные таблицы лидеров.
6. Добавлять донаты только после выбора легального провайдера, который поддерживает страну и банковский счёт владельца.

## Как продолжить

Открой [полный handoff-отчёт в OTKAT AI Team](https://github.com/OTKAT628/otkat-ai-team/blob/feature/android-chat-control-ui/docs/DAILY_HANDOFF_2026-11-27.md) и продолжи с раздела «Next work session — exact order». Сначала проверить CI и Android APK, затем реальные подключения провайдеров и GitHub.
