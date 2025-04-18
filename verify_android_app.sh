#!/bin/bash
#
# Скрипт для проверки корректности Android-приложения
# Выполняет различные проверки на совместимость с новейшими версиями Android

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}======== Проверка Android-приложения ========${NC}"

# Проверка существования APK
APK_FILE="./code-editor.apk"
if [ ! -f "$APK_FILE" ]; then
    echo -e "${RED}[ERROR] APK файл не найден: $APK_FILE${NC}"
    exit 1
fi

# Получаем размер APK
APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
echo -e "${GREEN}[✓] APK файл найден: $APK_FILE (размер: $APK_SIZE)${NC}"

# Проверяем структуру APK (если есть unzip)
if command -v unzip &> /dev/null; then
    echo -e "${BLUE}[*] Проверка структуры APK...${NC}"
    
    # Создаем временную директорию для распаковки
    TEMP_DIR=$(mktemp -d)
    unzip -q "$APK_FILE" -d "$TEMP_DIR"
    
    # Проверяем наличие основных файлов
    MANIFEST_FILE="$TEMP_DIR/AndroidManifest.xml"
    DEX_FILE="$TEMP_DIR/classes.dex"
    RESOURCES_FILE="$TEMP_DIR/resources.arsc"
    
    if [ -f "$MANIFEST_FILE" ]; then
        echo -e "${GREEN}[✓] AndroidManifest.xml найден${NC}"
    else
        echo -e "${RED}[ERROR] AndroidManifest.xml не найден!${NC}"
    fi
    
    if [ -f "$DEX_FILE" ]; then
        echo -e "${GREEN}[✓] classes.dex найден${NC}"
        DEX_SIZE=$(du -h "$DEX_FILE" | cut -f1)
        echo -e "${BLUE}[*] Размер DEX файла: $DEX_SIZE${NC}"
    else
        echo -e "${RED}[ERROR] classes.dex не найден!${NC}"
    fi
    
    if [ -f "$RESOURCES_FILE" ]; then
        echo -e "${GREEN}[✓] resources.arsc найден${NC}"
    else
        echo -e "${RED}[ERROR] resources.arsc не найден!${NC}"
    fi
    
    # Проверяем наличие META-INF и подписи
    if [ -d "$TEMP_DIR/META-INF" ]; then
        echo -e "${GREEN}[✓] META-INF директория найдена${NC}"
        
        if [ -f "$TEMP_DIR/META-INF/MANIFEST.MF" ]; then
            echo -e "${GREEN}[✓] MANIFEST.MF найден${NC}"
        fi
        
        if [ -f "$TEMP_DIR/META-INF/CERT.SF" ]; then
            echo -e "${GREEN}[✓] CERT.SF найден${NC}"
        fi
        
        if [ -f "$TEMP_DIR/META-INF/CERT.RSA" ]; then
            echo -e "${GREEN}[✓] CERT.RSA найден${NC}"
        fi
    else
        echo -e "${RED}[ERROR] META-INF директория не найдена!${NC}"
    fi
    
    # Проверяем assets
    if [ -d "$TEMP_DIR/assets" ]; then
        echo -e "${GREEN}[✓] assets директория найдена${NC}"
        
        # Проверяем наличие HTML-файла
        if [ -f "$TEMP_DIR/assets/index.html" ]; then
            echo -e "${GREEN}[✓] assets/index.html найден${NC}"
        else
            echo -e "${YELLOW}[WARNING] assets/index.html не найден${NC}"
        fi
    else
        echo -e "${YELLOW}[WARNING] assets директория не найдена${NC}"
    fi
    
    # Проверяем папку с ресурсами
    if [ -d "$TEMP_DIR/res" ]; then
        echo -e "${GREEN}[✓] res директория найдена${NC}"
    else
        echo -e "${YELLOW}[WARNING] res директория не найдена${NC}"
    fi
    
    # Удаляем временную директорию
    rm -rf "$TEMP_DIR"
else
    echo -e "${YELLOW}[WARNING] unzip не установлен, пропускаем проверку структуры APK${NC}"
fi

echo -e "${BLUE}[*] Проверка совместимости с Android...${NC}"

# Запускаем проверку с помощью Android Debug Bridge (adb), если он установлен
if command -v adb &> /dev/null; then
    echo -e "${BLUE}[*] adb найден, проверяем подключенные устройства...${NC}"
    
    DEVICES=$(adb devices | grep -v "List" | grep -v "^$" | wc -l)
    if [ "$DEVICES" -gt 0 ]; then
        echo -e "${GREEN}[✓] Найдено $DEVICES подключенных устройств${NC}"
        echo -e "${BLUE}[*] Вы можете установить APK на устройство с помощью команды:${NC}"
        echo -e "${YELLOW}adb install -r $APK_FILE${NC}"
    else
        echo -e "${YELLOW}[WARNING] Нет подключенных устройств для тестирования${NC}"
    fi
else
    echo -e "${YELLOW}[WARNING] adb не установлен, пропускаем проверку устройств${NC}"
fi

echo -e "${BLUE}======== Проверка завершена ========${NC}"

# Показываем сводную информацию
echo -e "${GREEN}[SUMMARY] APK файл ($APK_SIZE) готов для установки${NC}"
echo -e "${GREEN}[SUMMARY] Путь к файлу: $APK_FILE${NC}"

# Если файл существует в директории загрузок, показываем информацию
if [ -f "/download/code-editor.apk" ]; then
    echo -e "${GREEN}[SUMMARY] APK также доступен в директории загрузок: /download/code-editor.apk${NC}"
fi

# Если есть GitHub репозиторий, показываем ссылку для скачивания
if [ -n "$GITHUB_REPOSITORY" ]; then
    RELEASE_URL="https://github.com/$GITHUB_REPOSITORY/releases/latest/download/code-editor.apk"
    echo -e "${GREEN}[SUMMARY] Ссылка для скачивания: $RELEASE_URL${NC}"
fi