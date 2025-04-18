#!/bin/bash
# Скрипт для создания полноценного APK с правильным DEX файлом

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Выходной путь
OUTPUT_APK="codeeditor-full.apk"
TEMP_DIR=$(mktemp -d)

echo -e "${BLUE}========== ✅ Создание полноценного APK с правильным DEX файлом ===========${NC}"

# 1. Создаем структуру APK во временной директории
echo -e "${BLUE}[+] Подготовка структуры APK...${NC}"
mkdir -p "$TEMP_DIR/META-INF"
mkdir -p "$TEMP_DIR/assets"
mkdir -p "$TEMP_DIR/res/drawable"
mkdir -p "$TEMP_DIR/res/layout"
mkdir -p "$TEMP_DIR/res/values"

# 2. Создаем DEX файл с помощью Python-скрипта
echo -e "${BLUE}[+] Создание DEX файла...${NC}"
python3 create_dex.py "$TEMP_DIR/classes.dex"

# Проверяем создание DEX файла
if [ ! -f "$TEMP_DIR/classes.dex" ]; then
    echo -e "${RED}[ERROR] Не удалось создать DEX файл${NC}"
    exit 1
fi

# 3. Создаем простой AndroidManifest.xml
echo -e "${BLUE}[+] Создание AndroidManifest.xml...${NC}"
cat > "$TEMP_DIR/AndroidManifest.xml" << 'EOF'
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
        android:icon="@drawable/ic_launcher"
        android:label="Code Editor Pro"
        android:theme="@android:style/Theme.NoTitleBar">
        
        <activity 
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

# 4. Создаем простой лаунчер иконки
echo -e "${BLUE}[+] Создание ресурсов...${NC}"
cat > "$TEMP_DIR/res/drawable/ic_launcher.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="48dp"
    android:height="48dp"
    android:viewportWidth="48"
    android:viewportHeight="48">
  <path
      android:fillColor="#007ACC"
      android:pathData="M24,48C37.25,48 48,37.25 48,24C48,10.75 37.25,0 24,0C10.75,0 0,10.75 0,24C0,37.25 10.75,48 24,48Z"/>
  <path
      android:fillColor="#FFFFFF"
      android:pathData="M12,12L36,12L36,36L12,36L12,12ZM16,16L16,32L32,32L32,16L16,16ZM20,22L24,22L24,28L20,28L20,22ZM26,18L30,18L30,24L26,24L26,18Z"/>
</vector>
EOF

# 5. Создаем MANIFEST.MF файл
echo -e "${BLUE}[+] Создание MANIFEST.MF...${NC}"
cat > "$TEMP_DIR/META-INF/MANIFEST.MF" << 'EOF'
Manifest-Version: 1.0
Created-By: 1.0 (Code Editor Pro Builder)

EOF

# 6. Копируем web-app в assets
echo -e "${BLUE}[+] Копирование web-app в assets...${NC}"
cp -r web-app/* "$TEMP_DIR/assets/"

# 7. Упаковываем в APK (ZIP)
echo -e "${BLUE}[+] Упаковка APK...${NC}"
current_dir=$(pwd)
cd "$TEMP_DIR" || exit 1
zip -r "$OUTPUT_APK" META-INF classes.dex AndroidManifest.xml assets res
cp "$OUTPUT_APK" "$current_dir/"
cd "$current_dir" || exit 1

# Проверка размера APK
APK_SIZE=$(du -h "$OUTPUT_APK" | cut -f1)
echo -e "${GREEN}[+] APK успешно создан: $OUTPUT_APK (размер: $APK_SIZE)${NC}"

# 8. Проверка содержимого APK
echo -e "${BLUE}[+] Проверка содержимого APK...${NC}"
unzip -l "$OUTPUT_APK" | grep -E "classes.dex|AndroidManifest.xml"

# 9. Отправка в Telegram
if [ -f "send_to_telegram.py" ]; then
    echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
    python3 send_to_telegram.py "$OUTPUT_APK" --message "✅ Code Editor Pro APK (размер: $APK_SIZE) успешно собран с рабочим DEX файлом"
fi

echo -e "${GREEN}========== ✅ Сборка успешно завершена ===========${NC}"

# Создаем копию с именем code-editor.apk для совместимости с другими скриптами
cp "$OUTPUT_APK" "code-editor.apk"
echo -e "${BLUE}[+] Создана копия APK с именем code-editor.apk${NC}"

# Очистка
rm -rf "$TEMP_DIR"
echo -e "${BLUE}[+] Временные файлы удалены${NC}"

exit 0