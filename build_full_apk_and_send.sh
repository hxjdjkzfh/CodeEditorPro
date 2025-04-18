#!/bin/bash
#
# Скрипт для сборки полноценного Android APK и отправки в Telegram
# Не создает минимальный/WebView APK, только полную версию через Android SDK

# Устанавливаем переменные цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========== ✅ Сборка полноценного Android APK ===========${NC}"

# Указываем пути по умолчанию
WEB_APP_DIR="web-app"
ANDROID_APP_DIR="android-app"
OUTPUT_APK="./code-editor-pro.apk"

# Проверяем наличие Python для запуска скриптов создания
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[ERROR] Python3 не найден. Пожалуйста, установите Python 3.${NC}"
    exit 1
fi

# Создаем директорию для Android приложения, если не существует
mkdir -p "$ANDROID_APP_DIR"
mkdir -p "$ANDROID_APP_DIR/app/src/main/assets"

# Копируем веб-приложение в assets
echo -e "${BLUE}[+] Копирование веб-приложения в Android активы...${NC}"
if [ -d "$WEB_APP_DIR" ]; then
    cp -r "$WEB_APP_DIR"/* "$ANDROID_APP_DIR/app/src/main/assets/"
else
    echo -e "${RED}[ERROR] Директория $WEB_APP_DIR не найдена!${NC}"
    exit 1
fi

# Используем улучшенную функцию для создания полноценного APK
echo -e "${BLUE}[+] Запуск создания полноценного Android APK...${NC}"
chmod +x create_full_apk.py
python3 create_full_apk.py "$WEB_APP_DIR" "$ANDROID_APP_DIR" "$OUTPUT_APK"

# Проверяем, успешно ли создан APK
if [ $? -eq 0 ] && [ -f "$OUTPUT_APK" ]; then
    echo -e "${GREEN}[+] Полноценный APK успешно создан: $OUTPUT_APK${NC}"
    APK_SIZE=$(du -h "$OUTPUT_APK" | cut -f1)
    echo -e "${GREEN}[+] Размер файла: $APK_SIZE${NC}"
    
    # Проверяем содержимое APK
    echo -e "${BLUE}[+] Проверка содержимого APK...${NC}"
    unzip -l "$OUTPUT_APK" | head -n 20
    
    # Проверяем основные компоненты
    echo -e "${BLUE}[+] Проверка критических файлов:${NC}"
    unzip -l "$OUTPUT_APK" | grep -q "classes.dex"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ DEX файл найден${NC}"
    else
        echo -e "${RED}✗ DEX файл не найден!${NC}"
    fi
    
    unzip -l "$OUTPUT_APK" | grep -q "resources.arsc"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Resources.arsc файл найден${NC}"
    else
        echo -e "${RED}✗ Resources.arsc файл не найден!${NC}"
    fi
    
    unzip -l "$OUTPUT_APK" | grep -q "AndroidManifest.xml"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ AndroidManifest.xml найден${NC}"
    else
        echo -e "${RED}✗ AndroidManifest.xml не найден!${NC}"
    fi
    
    unzip -l "$OUTPUT_APK" | grep -q "META-INF/CERT.RSA"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Подпись приложения найдена${NC}"
    else
        echo -e "${RED}✗ Подпись приложения не найдена!${NC}"
    fi
    
    # Отправляем APK в Telegram
    echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
    if [ -f "send_to_telegram.py" ]; then
        chmod +x send_to_telegram.py
        python3 send_to_telegram.py "$OUTPUT_APK" "✅ Code Editor Pro - Полноценный Android APK"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[+] APK успешно отправлен в Telegram!${NC}"
        else
            echo -e "${RED}[ERROR] Не удалось отправить APK в Telegram. Проверьте секреты TELEGRAM_TOKEN и TELEGRAM_TO.${NC}"
        fi
    else
        echo -e "${RED}[ERROR] скрипт send_to_telegram.py не найден!${NC}"
    fi
    
    echo ""
    echo "==============================================="
    echo -e "${GREEN}✅ APK успешно создан и готов к использованию!${NC}"
    echo "==============================================="
    exit 0
else
    echo -e "${RED}[ERROR] Не удалось создать полноценный APK файл!${NC}"
    echo -e "${RED}==========================================================${NC}"
    exit 1
fi