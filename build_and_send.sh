#!/bin/bash
# Скрипт для сборки APK и отправки его в Telegram
# Генерирует WebView APK из веб-приложения и отправляет в Telegram

# Устанавливаем переменные цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========== ✅ Сборка Android APK и отправка в Telegram ==========${NC}"

# Проверяем наличие необходимых переменных окружения
if [ -z "$TELEGRAM_TOKEN" ]; then
    echo -e "${RED}[ERROR] Переменная окружения TELEGRAM_TOKEN не установлена!${NC}"
    echo -e "${YELLOW}Установите TELEGRAM_TOKEN для отправки файлов в Telegram.${NC}"
    TELEGRAM_AVAILABLE=0
else
    TELEGRAM_AVAILABLE=1
fi

if [ -z "$TELEGRAM_TO" ]; then
    echo -e "${RED}[ERROR] Переменная окружения TELEGRAM_TO не установлена!${NC}"
    echo -e "${YELLOW}Установите TELEGRAM_TO (ID чата) для отправки файлов в Telegram.${NC}"
    TELEGRAM_AVAILABLE=0
fi

# Указываем пути по умолчанию
WEB_APP_DIR="web-app"
ANDROID_APP_DIR="android-webview-app"
OUTPUT_APK="./code-editor.apk"

# Сборка минимального APK из веб-приложения
echo -e "${BLUE}[+] Запуск сборки WebView APK...${NC}"
python3 create_minimal_apk.py "$WEB_APP_DIR" "$ANDROID_APP_DIR" "$OUTPUT_APK"

# Проверяем, успешно ли создан APK
if [ $? -eq 0 ] && [ -f "$OUTPUT_APK" ]; then
    echo -e "${GREEN}[+] APK успешно создан: $OUTPUT_APK${NC}"
    APK_SIZE=$(du -h "$OUTPUT_APK" | cut -f1)
    echo -e "${GREEN}[+] Размер файла: $APK_SIZE${NC}"
    
    # Отправляем APK в Telegram, если доступно
    if [ $TELEGRAM_AVAILABLE -eq 1 ]; then
        echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
        
        # Генерируем информативное сообщение
        COMMIT_INFO=$(git log -1 --pretty=format:"Commit: %h - %s (%an)" 2>/dev/null || echo "")
        if [ -n "$COMMIT_INFO" ]; then
            MESSAGE="✅ Code Editor APK успешно собран!\n\nВерсия: 1.0\nРазмер: $APK_SIZE\n\n$COMMIT_INFO"
        else
            MESSAGE="✅ Code Editor APK успешно собран!\n\nВерсия: 1.0\nРазмер: $APK_SIZE"
        fi
        
        # Отправляем через Python-скрипт
        python3 send_to_telegram.py "$OUTPUT_APK" --message "$MESSAGE"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[+] APK успешно отправлен в Telegram!${NC}"
        else
            echo -e "${RED}[ERROR] Не удалось отправить APK в Telegram.${NC}"
        fi
    else
        echo -e "${YELLOW}[!] Отправка в Telegram пропущена из-за отсутствия переменных окружения.${NC}"
    fi
    
    echo -e "${GREEN}==========================================================${NC}"
    echo -e "${GREEN}✅ Сборка завершена успешно!${NC}"
    echo -e "${GREEN}APK доступен по пути: $OUTPUT_APK${NC}"
    echo -e "${GREEN}==========================================================${NC}"
    
    # Предлагаем инструкции по установке
    echo -e "${BLUE}Для установки на устройство Android:${NC}"
    echo -e "1. Включите режим разработчика на вашем устройстве"
    echo -e "2. Включите отладку по USB"
    echo -e "3. Подключите устройство к компьютеру"
    echo -e "4. Выполните команду: ${YELLOW}adb install -r $OUTPUT_APK${NC}"
    
    exit 0
else
    echo -e "${RED}[ERROR] Не удалось создать APK файл!${NC}"
    echo -e "${RED}==========================================================${NC}"
    exit 1
fi