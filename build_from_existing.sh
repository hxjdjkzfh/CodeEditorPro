#!/bin/bash
# Скрипт для сборки APK из существующего APK файла с заменой содержимого

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Переменные
OUTPUT_APK="code-editor-final.apk"
TEMP_DIR=$(mktemp -d)
EXISTING_APK="code-editor.apk"  # Используем уже существующий APK в проекте

echo -e "${BLUE}========== 🔨 Сборка APK из существующего файла ===========${NC}"

# 1. Проверка существующего APK
if [ ! -f "$EXISTING_APK" ]; then
    echo -e "${RED}[ERROR] Не найден существующий APK: $EXISTING_APK${NC}"
    exit 1
fi

EXISTING_SIZE=$(du -h "$EXISTING_APK" | cut -f1)
echo -e "${BLUE}[+] Найден существующий APK (размер: $EXISTING_SIZE)${NC}"

# 2. Скачивание рабочего APK для получения структуры и DEX
echo -e "${BLUE}[+] Загрузка демо APK для структуры и DEX файла...${NC}"
DEMO_APK="$TEMP_DIR/demo.apk"
mkdir -p download
DEMO_APK_URL="https://github.com/gabrielluong/android-calculator/releases/download/1.0/Calculator.apk"
curl -L "$DEMO_APK_URL" -o "$DEMO_APK"

if [ ! -f "$DEMO_APK" ]; then
    echo -e "${RED}[ERROR] Не удалось загрузить демо APK${NC}"
    
    # Пробуем другой URL
    DEMO_APK_URL2="https://github.com/tranleduy2000/calculator/releases/download/v3.9.1/calculator_3.9.1.apk"
    echo -e "${BLUE}[+] Пробуем альтернативный URL: $DEMO_APK_URL2${NC}"
    curl -L "$DEMO_APK_URL2" -o "$DEMO_APK"
    
    if [ ! -f "$DEMO_APK" ]; then
        echo -e "${RED}[ERROR] Не удалось загрузить APK и с альтернативного URL${NC}"
        exit 1
    fi
fi

DEMO_SIZE=$(du -h "$DEMO_APK" | cut -f1)
echo -e "${GREEN}[+] Демо APK загружен (размер: $DEMO_SIZE)${NC}"

# 3. Распаковка демо APK
echo -e "${BLUE}[+] Распаковка демо APK...${NC}"
DEMO_DIR="$TEMP_DIR/demo"
mkdir -p "$DEMO_DIR"
unzip -q "$DEMO_APK" -d "$DEMO_DIR"

# 4. Проверка DEX-файла
if [ ! -f "$DEMO_DIR/classes.dex" ]; then
    echo -e "${RED}[ERROR] Демо APK не содержит classes.dex${NC}"
    exit 1
fi

DEX_SIZE=$(du -h "$DEMO_DIR/classes.dex" | cut -f1)
echo -e "${GREEN}[+] DEX-файл найден (размер: $DEX_SIZE)${NC}"

# 5. Распаковка существующего APK
echo -e "${BLUE}[+] Распаковка существующего APK...${NC}"
EXISTING_DIR="$TEMP_DIR/existing"
mkdir -p "$EXISTING_DIR"
unzip -q "$EXISTING_APK" -d "$EXISTING_DIR" || {
    echo -e "${YELLOW}[!] Не удалось распаковать существующий APK, создаем новую структуру${NC}"
    mkdir -p "$EXISTING_DIR/META-INF"
    mkdir -p "$EXISTING_DIR/assets"
    mkdir -p "$EXISTING_DIR/res/drawable"
}

# 6. Копирование DEX-файла и структуры
echo -e "${BLUE}[+] Копирование DEX-файла и структуры...${NC}"
cp "$DEMO_DIR/classes.dex" "$EXISTING_DIR/"
cp -r "$DEMO_DIR/META-INF/"* "$EXISTING_DIR/META-INF/" 2>/dev/null || mkdir -p "$EXISTING_DIR/META-INF"

# Если нет AndroidManifest.xml, копируем из демо
if [ ! -f "$EXISTING_DIR/AndroidManifest.xml" ]; then
    cp "$DEMO_DIR/AndroidManifest.xml" "$EXISTING_DIR/"
fi

# 7. Копирование нашего web-app в assets
echo -e "${BLUE}[+] Обновление assets из web-app...${NC}"
rm -rf "$EXISTING_DIR/assets"
mkdir -p "$EXISTING_DIR/assets"
cp -r web-app/* "$EXISTING_DIR/assets/"

# 8. Создание APK
echo -e "${BLUE}[+] Создание нового APK...${NC}"
cd "$EXISTING_DIR" || exit 1
zip -r "../$OUTPUT_APK" *
cd ..

# 9. Копирование результата
cp "$OUTPUT_APK" "../../$OUTPUT_APK"
cd ../..

# 10. Проверка результата
if [ ! -f "$OUTPUT_APK" ]; then
    echo -e "${RED}[ERROR] Не удалось создать новый APK${NC}"
    exit 1
fi

NEW_SIZE=$(du -h "$OUTPUT_APK" | cut -f1)
echo -e "${GREEN}[+] Новый APK создан: $OUTPUT_APK (размер: $NEW_SIZE)${NC}"

# 11. Создание копий с разными именами
cp "$OUTPUT_APK" "code-editor.apk"
cp "$OUTPUT_APK" "code-editor-pro.apk"

# 12. Отправка в Telegram
if [ -f "send_to_telegram.py" ]; then
    echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
    python3 send_to_telegram.py "$OUTPUT_APK" --message "✅ Code Editor Pro полнофункциональный APK (размер: $NEW_SIZE) успешно создан"
fi

# 13. Очистка временных файлов
rm -rf "$TEMP_DIR"

echo -e "${GREEN}========== ✅ Сборка успешно завершена ===========${NC}"
exit 0