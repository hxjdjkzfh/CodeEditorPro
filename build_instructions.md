# Инструкции по сборке приложения Code Editor

## Вариант 1: Использование готовых скриптов сборки в репозитории

В репозитории есть несколько готовых скриптов для создания APK-файла:

1. **build_android.sh** - основной скрипт, который автоматически выбирает подходящий метод сборки в зависимости от окружения:
   ```bash
   chmod +x build_android.sh
   ./build_android.sh
   ```

2. **build_webview_app.sh** - создает WebView-приложение с вашим веб-контентом:
   ```bash
   chmod +x build_webview_app.sh
   ./build_webview_app.sh
   ```

3. **build_real_android_app.sh** - создает полноценное Android-приложение с WebView:
   ```bash
   chmod +x build_real_android_app.sh
   ./build_real_android_app.sh
   ```

4. **create_minimal_apk.py** - генерирует минимальный валидный APK при отсутствии других возможностей:
   ```bash
   python create_minimal_apk.py
   ```

После выполнения любого из этих скриптов, файл APK будет создан как `code-editor.apk` в корневой директории проекта.

## Вариант 2: Сборка с помощью онлайн компилятора

1. Загрузите ZIP-архив `code-editor-web.zip` из этого проекта.
2. Посетите [AppCreator24](https://appcreator24.com/app/) или другой онлайн-сервис для создания WebView приложений.
3. Загрузите архив с веб-приложением и настройте базовые параметры (имя приложения, иконка).
4. Экспортируйте APK-файл.

## Вариант 3: Сборка с помощью Android Studio

1. Установите [Android Studio](https://developer.android.com/studio).
2. Создайте новый проект с пустой активностью (Empty Activity).
3. Скопируйте файлы из директории `android-webview-app/src` в соответствующие директории вашего проекта.
4. Скопируйте содержимое директории `web-app` в каталог `app/src/main/assets/` вашего проекта.
5. Соберите приложение, выбрав Build > Build Bundle(s) / APK(s) > Build APK(s).

## Вариант 4: Использование сервиса GitHub Actions

В репозитории уже настроены GitHub Actions Workflows для автоматической сборки APK:

1. **.github/workflows/android.yml** - стандартная сборка Android приложения
2. **.github/workflows/build_webview.yml** - сборка WebView приложения

Для использования:
1. Клонируйте репозиторий на GitHub.
2. Перейдите в раздел Actions.
3. Выберите нужный workflow и запустите его вручную или дождитесь автоматического запуска при внесении изменений.
4. Скачайте готовый APK из раздела Artifacts.

Пример workflow для вашего репозитория:

```yaml
name: Android CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: set up JDK 11
      uses: actions/setup-java@v3
      with:
        java-version: '11'
        distribution: 'temurin'
        cache: gradle
    - name: Grant execute permission for gradlew
      run: chmod +x gradlew
    - name: Build with Gradle
      run: ./gradlew build
    - name: Build debug APK
      run: ./gradlew assembleDebug
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-debug
        path: app/build/outputs/apk/debug/app-debug.apk
```

## Описание функциональности приложения

Приложение Code Editor представляет собой простой редактор кода, имеющий следующие функции:

1. **Редактирование кода с подсветкой синтаксиса JavaScript**
2. **Поддержка работы с вкладками для нескольких файлов**
3. **Возможность выполнения JavaScript кода прямо в приложении**
4. **Встроенная консоль для вывода результатов работы скриптов**
5. **Сохранение и открытие файлов**
6. **Поддержка темной темы для комфортной работы**

### Использование приложения

1. **Создание нового файла**: нажмите на "+" в панели вкладок.
2. **Сохранение файла**: нажмите кнопку "Save" в правом верхнем углу.
3. **Выполнение кода**: нажмите кнопку "Run" для запуска текущего JavaScript файла.
4. **Переключение между файлами**: просто нажмите на нужную вкладку.

Жёлтым цветом подсвечиваются вкладки с несохраненными изменениями.