#!/bin/bash
#
# Скрипт для создания полноценного WebView Android приложения
# с использованием Gradle

set -e

echo "=== Starting WebView APK build using Gradle ==="

# Делаем скрипт сборки исполняемым
chmod +x create_full_apk.py

# Запускаем Python-скрипт для создания APK через Gradle
python3 create_full_apk.py web-app android-webview-app ./code-editor.apk

# Проверяем результат
if [ -f "./code-editor.apk" ]; then
    echo "APK created successfully: ./code-editor.apk"
    echo "APK size: $(du -h ./code-editor.apk | cut -f1)"
    
    # Создаем ссылку для скачивания, если мы в GitHub
    if [ -n "$GITHUB_SERVER_URL" ] && [ -n "$GITHUB_REPOSITORY" ]; then
        RELEASE_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/releases/latest/download/code-editor.apk"
        echo ""
        echo "==============================================="
        echo "✓ Прямая ссылка для скачивания APK:"
        echo "$RELEASE_URL"
        echo "==============================================="
    elif [ -n "$GITHUB_REPOSITORY" ]; then
        RELEASE_URL="https://github.com/$GITHUB_REPOSITORY/releases/latest/download/code-editor.apk"
        echo ""
        echo "==============================================="
        echo "✓ Прямая ссылка для скачивания APK:"
        echo "$RELEASE_URL"
        echo "==============================================="
    fi
    
    # Копируем в директорию загрузок, если она существует
    if [ -d "/download" ]; then
        cp "./code-editor.apk" "/download/code-editor.apk"
        echo "✓ APK также доступен для скачивания в директории /download"
    fi
else
    echo "Failed to create APK file!"
    exit 1
fi

echo "=== WebView APK build completed ==="