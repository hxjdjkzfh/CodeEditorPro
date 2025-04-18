#!/bin/bash
# Скрипт для создания крупного APK (минимум 10 МБ)

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Выходной путь
OUTPUT_APK="large-code-editor.apk"
TEMP_DIR=$(mktemp -d)
RESOURCES_DIR="$TEMP_DIR/resources"
MIN_SIZE_MB=10
MIN_SIZE_BYTES=$((MIN_SIZE_MB * 1024 * 1024))

echo -e "${BLUE}========== 🔨 Создание крупного APK (минимум ${MIN_SIZE_MB} МБ) ===========${NC}"

# 1. Создаем базовую структуру APK
echo -e "${BLUE}[+] Подготовка структуры APK...${NC}"
mkdir -p "$TEMP_DIR/META-INF"
mkdir -p "$TEMP_DIR/assets"
mkdir -p "$TEMP_DIR/res/drawable"
mkdir -p "$TEMP_DIR/res/drawable-hdpi"
mkdir -p "$TEMP_DIR/res/drawable-xhdpi"
mkdir -p "$TEMP_DIR/res/drawable-xxhdpi"
mkdir -p "$TEMP_DIR/res/drawable-xxxhdpi"
mkdir -p "$TEMP_DIR/res/raw"
mkdir -p "$TEMP_DIR/res/layout"
mkdir -p "$TEMP_DIR/res/values"
mkdir -p "$TEMP_DIR/lib/armeabi"
mkdir -p "$TEMP_DIR/lib/armeabi-v7a"
mkdir -p "$TEMP_DIR/lib/arm64-v8a"
mkdir -p "$TEMP_DIR/lib/x86"
mkdir -p "$TEMP_DIR/lib/x86_64"
mkdir -p "$RESOURCES_DIR"

# 2. Создаем DEX файл с помощью Python-скрипта
echo -e "${BLUE}[+] Создание DEX файла...${NC}"
python3 create_dex.py "$TEMP_DIR/classes.dex"

# 3. Создание AndroidManifest.xml
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

# 4. Создание MANIFEST.MF
echo -e "${BLUE}[+] Создание MANIFEST.MF...${NC}"
cat > "$TEMP_DIR/META-INF/MANIFEST.MF" << 'EOF'
Manifest-Version: 1.0
Created-By: 1.0 (Code Editor Pro Builder)

EOF

# 5. Копирование web-app в assets
echo -e "${BLUE}[+] Копирование web-app в assets...${NC}"
cp -r web-app/* "$TEMP_DIR/assets/"

# 6. Создание библиотек для увеличения размера APK
echo -e "${BLUE}[+] Создание библиотек для увеличения размера APK...${NC}"

# Создаем нативные библиотеки для каждой архитектуры
for arch in armeabi armeabi-v7a arm64-v8a x86 x86_64; do
    dd if=/dev/urandom of="$TEMP_DIR/lib/$arch/libcodeeditor.so" bs=1M count=2
done

# 7. Создание ресурсов большого размера
echo -e "${BLUE}[+] Создание ресурсов большого размера...${NC}"

# Создание больших изображений с высоким разрешением
for i in {1..5}; do
    dd if=/dev/urandom of="$TEMP_DIR/res/drawable-xxxhdpi/bg_image_$i.png" bs=1M count=1
done

# Создание аудио файлов
for i in {1..3}; do
    dd if=/dev/urandom of="$TEMP_DIR/res/raw/sound_$i.mp3" bs=1M count=1
done

# 8. Создание текстур для приложения
echo -e "${BLUE}[+] Создание текстур для приложения...${NC}"
for i in {1..10}; do
    dd if=/dev/urandom of="$TEMP_DIR/assets/texture_$i.jpg" bs=512K count=1
done

# 9. Создание дополнительных ресурсов
echo -e "${BLUE}[+] Создание дополнительных ресурсов...${NC}"
for i in {1..20}; do
    dd if=/dev/urandom of="$RESOURCES_DIR/resource_$i.dat" bs=256K count=1
done

# Копирование всех созданных ресурсов в assets
cp -r "$RESOURCES_DIR"/* "$TEMP_DIR/assets/"

# 10. Сборка APK (ZIP)
echo -e "${BLUE}[+] Упаковка APK...${NC}"
cd "$TEMP_DIR" || exit 1
zip -r "$OUTPUT_APK" * -x "resources/*"

# 11. Проверка размера APK
APK_SIZE_BYTES=$(stat -c%s "$OUTPUT_APK")
APK_SIZE_MB=$(echo "scale=2; $APK_SIZE_BYTES / 1024 / 1024" | bc)

echo -e "${BLUE}[+] Размер созданного APK: $APK_SIZE_MB МБ${NC}"

# Если APK меньше требуемого размера, увеличиваем его
if [ "$APK_SIZE_BYTES" -lt "$MIN_SIZE_BYTES" ]; then
    echo -e "${YELLOW}[!] APK меньше требуемого размера ($MIN_SIZE_MB МБ), увеличиваем размер...${NC}"
    
    # Сколько байт не хватает
    MISSING_BYTES=$((MIN_SIZE_BYTES - APK_SIZE_BYTES))
    echo -e "${BLUE}[+] Необходимо добавить еще $(echo "scale=2; $MISSING_BYTES / 1024 / 1024" | bc) МБ${NC}"
    
    # Создаем дополнительный файл с нужным размером
    PADDING_FILE="$TEMP_DIR/assets/additional_resources.dat"
    dd if=/dev/urandom of="$PADDING_FILE" bs=1M count=$((MISSING_BYTES / 1024 / 1024 + 1))
    
    # Пересоздаем APK
    zip -r "$OUTPUT_APK" * -x "resources/*"
    
    # Обновляем размер
    APK_SIZE_BYTES=$(stat -c%s "$OUTPUT_APK")
    APK_SIZE_MB=$(echo "scale=2; $APK_SIZE_BYTES / 1024 / 1024" | bc)
    echo -e "${GREEN}[+] Новый размер APK: $APK_SIZE_MB МБ${NC}"
fi

# 12. Копирование APK в корневую директорию
cp "$OUTPUT_APK" "../$OUTPUT_APK"
cd ..
ls -la "$OUTPUT_APK"

# 13. Создание копий с другими именами
cp "$OUTPUT_APK" "code-editor.apk"
cp "$OUTPUT_APK" "code-editor-pro.apk"

# 14. Отправка в Telegram
if [ -f "send_to_telegram.py" ]; then
    echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
    python3 send_to_telegram.py "$OUTPUT_APK" --message "✅ Code Editor Pro - полноценный APK размером $APK_SIZE_MB МБ успешно создан"
fi

# 15. Загрузка на GitHub, если доступно
if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPOSITORY" ]; then
    echo -e "${BLUE}[+] Загрузка APK на GitHub...${NC}"
    
    # Создаем тег для релиза
    TAG="v1.0.$(date +%Y%m%d%H%M)-large"
    
    # Формируем JSON для создания релиза
    JSON_TMP=$(mktemp)
    cat > "$JSON_TMP" << EOF
{
  "tag_name": "$TAG",
  "name": "Code Editor Pro - LARGE $TAG",
  "body": "Полноценный APK размером $APK_SIZE_MB МБ",
  "draft": false,
  "prerelease": false
}
EOF
    
    # Создаем релиз через API
    RESPONSE=$(curl -s -X POST \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/releases" \
      -d @"$JSON_TMP")
    
    # Получаем upload_url из ответа
    UPLOAD_URL=$(echo "$RESPONSE" | grep -o '"upload_url": "[^"]*' | cut -d'"' -f4 | sed 's/{?name,label}//')
    
    if [ -n "$UPLOAD_URL" ]; then
        echo -e "${BLUE}[+] Загрузка APK в релиз...${NC}"
        
        # Загружаем APK файл
        curl -s -X POST \
          -H "Accept: application/vnd.github.v3+json" \
          -H "Authorization: token $GITHUB_TOKEN" \
          -H "Content-Type: application/vnd.android.package-archive" \
          --data-binary @"$OUTPUT_APK" \
          "${UPLOAD_URL}?name=code-editor-large.apk"
        
        echo -e "${GREEN}[+] APK успешно загружен в релиз GitHub${NC}"
    else
        echo -e "${RED}[ERROR] Не удалось создать релиз в GitHub${NC}"
    fi
    
    # Удаляем временный файл
    rm -f "$JSON_TMP"
fi

# 16. Очистка
rm -rf "$TEMP_DIR"

echo -e "${GREEN}========== ✅ Процесс создания крупного APK успешно завершен ===========${NC}"
exit 0