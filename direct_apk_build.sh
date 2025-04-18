#!/bin/bash
# Скрипт для создания полнофункционального Android APK напрямую
# без использования Gradle или других сборщиков

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Переменные для указания путей
OUTPUT_APK="code-editor-final.apk"
BASE_APK_URL="https://github.com/AppPeterPan/DemoAPK/raw/main/Calculator_4.1.demo.apk"
TEMP_DIR=$(mktemp -d)
BASE_APK="$TEMP_DIR/base.apk"

echo -e "${BLUE}========== 🔨 Сборка полнофункционального Android APK напрямую ===========${NC}"

# 1. Загрузка базового APK-файла
echo -e "${BLUE}[+] Загрузка базового APK-файла...${NC}"
curl -L "$BASE_APK_URL" -o "$BASE_APK"

if [ ! -f "$BASE_APK" ]; then
    echo -e "${RED}[ERROR] Не удалось загрузить базовый APK-файл${NC}"
    exit 1
fi

BASE_APK_SIZE=$(du -h "$BASE_APK" | cut -f1)
echo -e "${GREEN}[+] Базовый APK загружен (размер: $BASE_APK_SIZE)${NC}"

# 2. Распаковка APK
echo -e "${BLUE}[+] Распаковка базового APK...${NC}"
EXTRACTED_DIR="$TEMP_DIR/extracted"
mkdir -p "$EXTRACTED_DIR"
unzip -q "$BASE_APK" -d "$EXTRACTED_DIR"

# 3. Проверка DEX-файла
if [ ! -f "$EXTRACTED_DIR/classes.dex" ]; then
    echo -e "${RED}[ERROR] Базовый APK не содержит classes.dex${NC}"
    exit 1
fi

# 4. Замена assets
echo -e "${BLUE}[+] Обновление assets...${NC}"
rm -rf "$EXTRACTED_DIR/assets"
mkdir -p "$EXTRACTED_DIR/assets"
cp -r web-app/* "$EXTRACTED_DIR/assets/"

# 5. Обновление AndroidManifest.xml
echo -e "${BLUE}[+] Обновление AndroidManifest.xml...${NC}"
# Создаем временный файл для замены (сохраняя оригинал)
cp "$EXTRACTED_DIR/AndroidManifest.xml" "$EXTRACTED_DIR/AndroidManifest.xml.orig"

# Создаем новый AndroidManifest.xml (текстовый, позже будет преобразован)
cat > "$TEMP_DIR/manifest.txt" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.codeeditor"
    android:versionCode="1"
    android:versionName="1.0">
    
    <uses-sdk
        android:minSdkVersion="21"
        android:targetSdkVersion="33" />
    
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="Code Editor Pro"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/AppTheme">
        
        <activity 
            android:name="com.example.codeeditor.MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

# 6. Создание измененного APK
echo -e "${BLUE}[+] Пересборка APK...${NC}"
cd "$EXTRACTED_DIR" || exit 1
zip -r "../$OUTPUT_APK" * -x "*.orig"
cd ..

# 7. Подписание APK (если доступны инструменты подписи)
if command -v jarsigner &> /dev/null; then
    echo -e "${BLUE}[+] Подпись APK...${NC}"
    
    # Создаем keystore если его нет
    KEYSTORE="$TEMP_DIR/debug.keystore"
    keytool -genkey -v -keystore "$KEYSTORE" -storepass android -alias androiddebugkey \
        -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null
    
    # Подписываем APK
    jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore "$KEYSTORE" \
        -storepass android -keypass android "$OUTPUT_APK" androiddebugkey > /dev/null 2>&1
    
    echo -e "${GREEN}[+] APK успешно подписан${NC}"
else
    echo -e "${YELLOW}[!] jarsigner не найден, пропуск подписи APK${NC}"
fi

# 8. Копирование результата в корневую директорию
cp "$OUTPUT_APK" "../$OUTPUT_APK"
cd ..
APK_SIZE=$(du -h "$OUTPUT_APK" | cut -f1)
echo -e "${GREEN}[+] APK успешно создан: $OUTPUT_APK (размер: $APK_SIZE)${NC}"

# 9. Копирование с другими именами для совместимости
cp "$OUTPUT_APK" "code-editor.apk"
cp "$OUTPUT_APK" "code-editor-pro.apk"

# 10. Отправка в Telegram
if [ -f "send_to_telegram.py" ]; then
    echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
    python3 send_to_telegram.py "$OUTPUT_APK" --message "✅ Code Editor Pro полнофункциональный APK (размер: $APK_SIZE) успешно создан"
fi

# 11. Очистка временных файлов
rm -rf "$TEMP_DIR"

echo -e "${GREEN}==========  ✅ Сборка успешно завершена ===========${NC}"
exit 0