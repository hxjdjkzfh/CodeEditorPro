#!/bin/bash
#
# Основной скрипт для сборки Android-приложения
# Выбирает оптимальный метод сборки для корректного APK
# 
# Режимы:
# - webview: использует улучшенный метод WebView для создания легкого APK (по умолчанию)
# - sdk: пытается использовать полный Android SDK
# - auto: пробует оба варианта (сначала webview, затем sdk)
#
# Использование: 
#   ./build_android.sh [режим]
#   Например: ./build_android.sh sdk 

# Устанавливаем переменные цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========== ✅ Сборка Android APK ===========${NC}"

# Указываем пути по умолчанию
WEB_APP_DIR="web-app"
ANDROID_APP_DIR="android-webview-app"
OUTPUT_APK="./code-editor.apk"

# Определяем режим работы
BUILD_MODE="sdk"  # По умолчанию используем SDK

if [ "$1" == "sdk" ]; then
    BUILD_MODE="sdk"
    echo -e "${YELLOW}[+] Выбран режим полной сборки через Android SDK${NC}"
elif [ "$1" == "auto" ]; then
    BUILD_MODE="auto"
    echo -e "${YELLOW}[+] Выбран автоматический режим (попытка использовать оба метода)${NC}"
elif [ "$1" == "webview" ]; then
    BUILD_MODE="webview"
    echo -e "${YELLOW}[+] Выбран режим сборки через WebView${NC}"
elif [ -z "$1" ]; then
    BUILD_MODE="sdk"
    echo -e "${YELLOW}[+] Выбран режим полной сборки через Android SDK (по умолчанию)${NC}"
else
    echo -e "${RED}[!] Неизвестный режим: $1. Используется SDK режим по умолчанию${NC}"
    BUILD_MODE="sdk"
fi

# Функция для сборки через WebView
build_webview() {
    echo -e "${BLUE}[+] Запуск улучшенного метода сборки APK через WebView...${NC}"
    chmod +x build_webview_app.sh
    ./build_webview_app.sh
    
    # Копируем APK в стандартный выходной файл
    if [ -f "webview-code-editor.apk" ]; then
        cp webview-code-editor.apk "$OUTPUT_APK"
        echo -e "${GREEN}[+] APK скопирован в стандартный путь: $OUTPUT_APK${NC}"
        return 0
    else
        echo -e "${RED}[!] Не удалось создать WebView APK${NC}"
        return 1
    fi
}

# Функция для сборки через Android SDK
build_sdk() {
    echo -e "${BLUE}[+] Запуск метода сборки через Android SDK...${NC}"
    chmod +x build_full_sdk_apk.sh
    ./build_full_sdk_apk.sh
    
    if [ -f "code-editor-pro.apk" ]; then
        cp code-editor-pro.apk "$OUTPUT_APK"
        echo -e "${GREEN}[+] APK успешно собран через Android SDK и скопирован в $OUTPUT_APK${NC}"
        return 0
    else
        echo -e "${RED}[!] Не удалось создать APK через Android SDK${NC}"
        return 1
    fi
}

# Запускаем сборку в зависимости от выбранного режима
if [ "$BUILD_MODE" == "webview" ]; then
    build_webview
    RESULT=$?
elif [ "$BUILD_MODE" == "sdk" ]; then
    build_sdk
    RESULT=$?
else 
    # Автоматический режим - пробуем оба варианта
    echo -e "${BLUE}[+] Автоматический режим: сначала попробуем WebView...${NC}"
    build_webview
    RESULT=$?
    
    # Если WebView не сработал, пробуем SDK
    if [ $RESULT -ne 0 ]; then
        echo -e "${YELLOW}[!] WebView метод не сработал, переключаемся на полный SDK...${NC}"
        build_sdk
        RESULT=$?
    fi
fi

# Проверяем, успешно ли создан APK
if [ $? -eq 0 ] && [ -f "$OUTPUT_APK" ]; then
    echo -e "${GREEN}[+] APK успешно создан: $OUTPUT_APK${NC}"
    APK_SIZE=$(du -h "$OUTPUT_APK" | cut -f1)
    echo -e "${GREEN}[+] Размер файла: $APK_SIZE${NC}"
    
    # Проверяем содержимое APK
    echo -e "${BLUE}[+] Проверка содержимого APK...${NC}"
    unzip -l "$OUTPUT_APK" | grep -q "classes.dex"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] APK содержит корректный DEX файл${NC}"
    else
        echo -e "${RED}[!] APK не содержит корректный DEX файл, возможно он не будет работать${NC}"
    fi
    
    # Получаем прямую ссылку на APK в GitHub, если доступно
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
    
    echo ""
    echo "To install the APK on your device:"
    echo "1. Enable Developer options on your Android device"
    echo "2. Enable USB debugging"
    echo "3. Connect your device to computer"
    echo "4. Run: adb install -r ./code-editor.apk"
    
    # Копируем APK в общедоступную директорию, если она существует
    if [ -d "/download" ]; then
        cp ./code-editor.apk /download/code-editor.apk
        echo ""
        echo "✓ APK также доступен для скачивания в директории /download"
    fi
    
    exit 0
else
    echo -e "${RED}[ERROR] Не удалось создать APK файл!${NC}"
    echo -e "${RED}==========================================================${NC}"
    exit 1
fi