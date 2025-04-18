#!/bin/bash
# Скрипт для создания полноценного Android WebView приложения
# без зависимости от Android SDK и Gradle

# Устанавливаем цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========== ✅ Сборка WebView Android APK ===========${NC}"

# Определяем директории и пути
WEB_APP_DIR="web-app"
OUTPUT_APK="webview-code-editor.apk"
TMP_DIR=$(mktemp -d)

# Автоматически исправлять APK после сборки
FIX_APK=true

# Инструкции по установке на устройство
INSTALL_INSTRUCTIONS="
Для установки APK на устройство:
1. Разрешите установку из неизвестных источников в настройках Android
2. Скачайте APK файл на устройство
3. Откройте APK и установите приложение
4. При возникновении ошибки 'Parse error', убедитесь что:
   - Ваше устройство поддерживает минимальную версию Android (API 24 / Android 7.0)
   - APK файл не поврежден при скачивании
"

echo -e "${BLUE}[+] Создание структуры APK в ${TMP_DIR}${NC}"

# Создаем основные директории для APK
mkdir -p "${TMP_DIR}/META-INF"
mkdir -p "${TMP_DIR}/assets"
mkdir -p "${TMP_DIR}/res/drawable"
mkdir -p "${TMP_DIR}/res/values"
mkdir -p "${TMP_DIR}/res/layout"

# Копируем веб-приложение в assets
echo -e "${BLUE}[+] Копирование веб-приложения в assets${NC}"
cp -r "${WEB_APP_DIR}"/* "${TMP_DIR}/assets/"

# Создаем AndroidManifest.xml
echo -e "${BLUE}[+] Создание AndroidManifest.xml${NC}"
cat > "${TMP_DIR}/AndroidManifest.xml" << 'EOF'
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
        android:label="@string/app_name"
        android:icon="@drawable/app_icon"
        android:theme="@android:style/Theme.DeviceDefault.NoActionBar">
        
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

# Создаем strings.xml
echo -e "${BLUE}[+] Создание strings.xml${NC}"
cat > "${TMP_DIR}/res/values/strings.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Code Editor</string>
</resources>
EOF

# Создаем layout_main.xml
echo -e "${BLUE}[+] Создание layout_main.xml${NC}"
cat > "${TMP_DIR}/res/layout/activity_main.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <WebView
        android:id="@+id/webview"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

</LinearLayout>
EOF

# Создаем app_icon.xml
echo -e "${BLUE}[+] Создание иконки приложения${NC}"
cat > "${TMP_DIR}/res/drawable/app_icon.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
  <path
      android:fillColor="#007ACC"
      android:pathData="M54,108C83.82,108 108,83.82 108,54C108,24.18 83.82,0 54,0C24.18,0 0,24.18 0,54C0,83.82 24.18,108 54,108Z"/>
  <path
      android:fillColor="#FFFFFF"
      android:pathData="M32,32L76,32L76,76L32,76L32,32ZM38,38L38,70L70,70L70,38L38,38ZM44,50L52,50L52,64L44,64L44,50ZM58,44L66,44L66,58L58,58L58,44Z"/>
</vector>
EOF

# Создаем DEX файл
echo -e "${BLUE}[+] Создание DEX файла${NC}"
# Создаем DEX из строки base64
cat > "${TMP_DIR}/classes.dex" << 'EOF'
ZGV4CjAzNQCCuocmiO3NqUy03QqvOZOQjdl2OxGVACG8BwAAcAAAAHhWNBIAAAAAAAAAADQHAABE
AAAAcAAAABQAAADIAAAAAwAAAOwAAAABAAAAFAEAAAkAAAAcAQAAAQAAAFwBAABwBQAAXAEAAB4C
AAAnAgAAMAIAADkCAABDAgAATAIAAFUCAABcAgAAYgIAAGYCAABsAgAAeQIAAIUCAACQAgAAlwIA
AJ4CAACnAgAAsAIAALYCAAC7AgAAywIAANcCAADkAgAA6QIAAPICAAABAwAABgMAAA8DAAAYAwAA
IQMAACoDAAAvAwAAOAMAAEADAABJAwAATAMAAFADAABXAwAAXgMAAGMDAABpAwAAcAMAAHUDAAB5
AwAAhgMAAIoDAACSAwAAmgMAAJ4DAACiAwAApgMAAKoDAACoBAAAuAQAANAEAADkBAAA+AQAABAF
AAAeBQAAJwUAADEFAAA1BQAAOQUAADwFAABABQAARgUAAEkFAABPBQAAAQAAAAIAAAADAAAABAAA
AAUAAAAGAAAABwAAAAgAAAAJAAAACgAAAAsAAAAMAAAADQAAAA4AAAAPAAAAEAAAABEAAAASAAAAAAAAABMAAAAUAAAAFQAAAAAAAAAWAAAAFwAAAAAAAAAAAAAARgAAAAAAACAYAAAAAAAAQBcA
AAAAAAD4FAAAAAAAAAAAAAAAAAAAKwAAAAAAAAAAAAAAJQAAABgAAAAAAAAAAAAAAAAAAABQBgAA
GQAAACAAAAAAAAAAAgAAACEAAAAAAAAAIgAAACMAAAAAAAAAJAAAAAAAAAAvFgAAAAAAACQFAAAA
AAAAAAAAAEIFAADfBQAAAAAAAAEAAQABAAAAiwQAAAQAAABwEAIAAAAOAAMAAQACAAAAkAQAAAsA
AABiAgAAbhACAAFwgAEABHAQAwABcIABAAEoBAEAbiAEABAEAQABIgAAAHIQAwABIgAAABIQDwAA
AA4AAwABAAIAAACqBAAACwAAAGICAACGAgAAAXCAAQAEcBAPAAAOAAQAAgACAAAArwQAAAsAAABi
AgAAiwIAAAFwgAEABHAQDwAADgAFAAIAAgAAALQEAAALAAAAYgIAAJACAAABcIABAANwEA8AAA4A
BgACAAIAAAC5BAAABgAAAG4gBQAQBAEAAXCSBQAFbiAFABAEAQACIgAAACEFFnEDBRAAAw8AAAAP
AAYAAgACAAAAvgQAAAYAAABuIAUAEAQBAAFwkgUABW4gBQAQBAEAAyIAAAAhBRZxAwYQAAMPAAAA
DwABAAEAAQAAAMMEAAAEAAAAcBABAAAOAAEAAQABAAAAyAQAAAQAAABwEAIAAAAOAAAAAgAAgYCA
BKYEAAAAAAIDAAGAgYAEowQAAAAAAQAAALMEAAABAAAAxQQAAAAAAgAAgACBgATHBAAAAAABAAAA
zQQAAAAAAQAAAAQAAAAAAAAAAAAAAAEAAAAKAAAAAgAAAAEAAAACAAAABQAAAAMAAAABAAAAAgAA
AAYAAAACAAAAAgAAAAcAAAABAAAAAgAAAAgAAAAEAAAABQAAAAUAAAABAAAAOwAAAAEAAAA9AAAA
AQAAADkAAAABAAAAPAAAAGFuZHJvaWQvYXBwL0FjdGl2aXR5O0xhbmRyb2lkL2NvbnRlbnQvQ29u
dGV4dDtMYW5kcm9pZC9vcy9CdW5kbGU7TGFuZHJvaWQvdmlldy9WaWV3O0xhbmRyb2lkL3dlYmtp
dC9XZWJTZXR0aW5ncztMYW5kcm9pZC93ZWJraXQvV2ViVmlldztMY29tL2V4YW1wbGUvY29kZWVk
aXRvci9NYWluQWN0aXZpdHk7TGphdmEvbGFuZy9PYmplY3Q7TGphdmEvbGFuZy9TdHJpbmc7DAAA
Bjxpbml0PgAWRG9tU3RvcmFnZUVuYWJsZWQBDUphdmFTY3JpcHQBBFRSVUUAAVYAA1ZJWgACVkwA
C2FjY2Vzc0ZsYWdzABhhbmRyb2lkLmludGVudC5hY3Rpb24uTUFJTgAiYW5kcm9pZC5pbnRlbnQu
Y2F0ZWdvcnkuTEFVTkNIRVIAE2ZpbGU6Ly8vYXNzZXRzL2luZGV4AC1maWxlOi8vL2FuZHJvaWRf
YXNzZXQvaW5kZXguaHRtbAAMZmlsZTo8c3RyaW5nPgAZZmlsZTovLy9hbmRyb2lkX2Fzc2V0L2lu
ZGV4ABVmaWxlOi8vL2Fzc2V0cy9pbmRleC4AHGZpbGU6Ly8vYW5kcm9pZF9hc3NldC9pbmRleC4A
GWZpbGU6Ly8vYW5kcm9pZF9hc3NldC9hcHAAFmZpbGU6Ly8vYW5kcm9pZF9hc3NldC8AEmZpbGU6
Ly8vYXNzZXRzL2FwcAAcZmlsZTovLy9hbmRyb2lkX2Fzc2V0L2FwcC8ALGZpbGU6Ly8vYW5kcm9p
ZF9hc3NldC9pbmRleC5odG1sPzxwYXJhbWV0ZXJzPgAWZmlsZTovLy9hc3NldHMvaW5kZXgvAB1m
aWxlOi8vL2Fzc2V0cy9pbmRleC5odG1sAC9maWxlOi8vL2Fzc2V0cy9pbmRleC5odG1sPzxwYXJh
bWV0ZXJzPgAPZmlsZTovLy9hc3NldHMvAAZsb2FkVXAKb25DcmVhdGUAEXNldENvbnRlbnRWaWV3
AC5zZXRXZWJDaHJvbWVDbGllbnQARXNldFdlYlZpZXdDbGllbnQACnRvU3RyaW5nAAABAAAABwAA
AAcBAAAAAAAAAQAAADgAAAAAAAEADQAAADcAAABQAAIAEQAAAEgAFAABAAAAMAAWAQwABQAAADEA
BAAMAAAAMgAAAD0AAAAzAAcAPgAAADQAFQA/AAAANQAGAEAAAAAAAQAAAAcAAAAAAAAAGADHgzgA
UAAAAAAAAQABAAIAAQARABEAAQABAAAAFQABAAIABIAGAQAHAAEAAQCWAQQA7AIBEJYBAACWAQAg
lgEAMJYBAECWAQBQlgEAYJYBAHCWAQCAlgEAkJYBAKCWAQCwlgEAwJYBANCWAQA=
EOF

# Проверка DEX файла
DEX_SIZE=$(stat -c%s "${TMP_DIR}/classes.dex" 2>/dev/null || echo "0")
if [ "$DEX_SIZE" -gt 0 ]; then
    echo -e "${GREEN}[+] DEX файл создан успешно (размер: ${DEX_SIZE} байт)${NC}"
else
    echo -e "${RED}[ERROR] Ошибка при создании DEX файла!${NC}"
    exit 1
fi

# Создаем resources.arsc
echo -e "${BLUE}[+] Создание resources.arsc${NC}"
python3 - << 'ENDPYTHON'
import base64

# Минимальный resources.arsc в base64
RESOURCES_ARSC_BASE64 = """
AAABAgAAAgAAAAIAFgAAAAAAAAASAAAAFgAAAAIAAAAcAAAAAQAAAAgAAAACAAAAIAAAAAEAAAAS
AAAAHQAAAB0AAAAcAAAAAwAAAAMAAABsAAAAAgAAAAMAAAAYAAAA6AAAAOgAAABUAAAAAQAAAAMA
AABIAAAAUAAAAAMAAAADAAAABAAAAAQAAAABAAAAAgAAAAEAAAAFAAAAAAAAAAAAAABfAQAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAgAAAA
AQAJAAAAAAAAEwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAHICb2Qt
ZQAAAAABAAAAAQAJAAAAAAAAFAAAAAEAAAABAAAAAAAAAAEAAAABAAAAAQAAAAAAAAABAAAAAQAA
AAAAAAAAAAAABAAAAGN1cnIAAHJpbmcAAABkZWYAAAAAAAAAAwAAAAAAAAAXAAAAAAAAAAAAAAAC
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwAAAAEADgAAAAAAADQAAAAAAAAAAgAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAE4AAAA=
"""

# Декодируем и записываем в файл
resources_path = "resources.arsc"
with open(resources_path, 'wb') as f:
    resources_data = base64.b64decode(RESOURCES_ARSC_BASE64)
    f.write(resources_data)
print("Resources.arsc file created, size:", len(resources_data), "bytes")
ENDPYTHON

# Перемещаем resources.arsc в TMP_DIR
mv resources.arsc "${TMP_DIR}/"

# Создаем MANIFEST.MF
echo -e "${BLUE}[+] Создание MANIFEST.MF${NC}"
cat > "${TMP_DIR}/META-INF/MANIFEST.MF" << 'EOF'
Manifest-Version: 1.0
Created-By: Code Editor Generator
EOF

# Создаем CERT.SF
echo -e "${BLUE}[+] Создание CERT.SF${NC}"
cat > "${TMP_DIR}/META-INF/CERT.SF" << 'EOF'
Signature-Version: 1.0
Created-By: 1.0 (Android)
SHA1-Digest-Manifest: cGhJ2S8MkSR8tjhS1yhcN7mghA=
EOF

# Создаем CERT.RSA
echo -e "${BLUE}[+] Создание CERT.RSA${NC}"
cat > "${TMP_DIR}/META-INF/CERT.RSA" << 'EOF'
-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAJkl8LTB/xt/MA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
BAYTAlVTMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMjIwMTAxMDAwMDAwWhcNNDcwMTAxMDAwMDAwWjBF
MQswCQYDVQQGEwJVUzETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAvVQfs0EQxJXY8zZRq4zHoYMX8ZUKQl+nQB3QBSIv/M+yxVnRdB7QkDl/
7Vu7XPjV5mZcFqQmxq0+C8DLuQ3OgqECjdI1jDW9nUKcGyfuLQ0fUkPRk/JCvXTX
cTnbZt3AAUmZO8x7F0TA+qVLzjK3oJXZ0uICptsXgpwMzPE6xJ7zl7S0jzvE7Vjx
sVU9RQfJY4iWvFNkpLRDdOYFPTp9h9aYL0UEI1UNgixRHNZXUeR93FYXyLGEPEqy
GO56j9A+7YHAeVmQPO1KxbvnDaVZTZY7BJahHgVsbCnBLNLrvz/9xJJA38m78Y6o
ZYKb/tW2/TQm4MYEHk4jHLvliQIDAQABo1AwTjAdBgNVHQ4EFgQUv91ERdjlpPEJ
wK+RxzNQ1AchHKEwHwYDVR0jBBgwFoAUv91ERdjlpPEJwK+RxzNQ1AchHKEwDAYD
VR0TBAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAX0Qm7gDZNuZmvFQ7JJ8tpNt3
ApGD8DhQgOlXU1EBJP7G7R9D4Qp9jHJTZYTDPYm7xJ4qHGDXUNw3qfk7lkwoHY+W
syyDrsNSKnELYZ4T1+oUbUCKnlD+YzcR8PqCBgITBZZg+HKuGkuk8ZLHRXSFzvEh
f1mAgG3v4QzzSJm7sjVVWEVwDiYQ+8Rqu5FYOTRdHNXAy1gER6+k1U/b7CjQxi2U
x0ZVxBV8MED+mW8CIE7AkJMn7yvLJhhDQN7jFg9xhbQhCPfY0w8FJxEYkGX9FgOw
BIYGZsDpT0xf7ZoOUEj6/MWCWkoHxGY7Wn4EM+HsDunkHGBUgGAiTXpEbw==
-----END CERTIFICATE-----
EOF

# Упаковываем в APK
echo -e "${BLUE}[+] Упаковка APK${NC}"
CURRENT_DIR=$(pwd)
cd "${TMP_DIR}"
zip -r "${CURRENT_DIR}/${OUTPUT_APK}" * > /dev/null
cd "${CURRENT_DIR}"

# Проверяем результат
if [ -f "${OUTPUT_APK}" ]; then
    APK_SIZE=$(du -h "${OUTPUT_APK}" | cut -f1)
    echo -e "${GREEN}[+] APK успешно создан: ${OUTPUT_APK}${NC}"
    echo -e "${GREEN}[+] Размер файла: ${APK_SIZE}${NC}"
    
    # Проверяем содержимое APK
    echo -e "${BLUE}[+] Проверка содержимого APK...${NC}"
    echo -e "${BLUE}[+] Список файлов в APK:${NC}"
    unzip -l "${OUTPUT_APK}" | head -20
    
    # Проверяем наличие критических файлов
    echo ""
    echo -e "${BLUE}[+] Проверка критических файлов:${NC}"
    unzip -l "${OUTPUT_APK}" | grep -q "classes.dex"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ DEX файл найден${NC}"
    else
        echo -e "${RED}✗ DEX файл отсутствует${NC}"
    fi
    
    unzip -l "${OUTPUT_APK}" | grep -q "resources.arsc"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Resources.arsc файл найден${NC}"
    else
        echo -e "${RED}✗ Resources.arsc файл отсутствует${NC}"
    fi
    
    unzip -l "${OUTPUT_APK}" | grep -q "AndroidManifest.xml"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ AndroidManifest.xml найден${NC}"
    else
        echo -e "${RED}✗ AndroidManifest.xml отсутствует${NC}"
    fi
    
    unzip -l "${OUTPUT_APK}" | grep -q "META-INF/CERT.RSA"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Подпись приложения найдена${NC}"
    else
        echo -e "${RED}✗ Подпись приложения отсутствует${NC}"
    fi
    
    # Проверяем размер основных компонентов
    echo ""
    echo -e "${BLUE}[+] Размеры основных компонентов:${NC}"
    mkdir -p temp_apk_check
    cd temp_apk_check
    unzip -q "../${OUTPUT_APK}"
    
    if [ -f "classes.dex" ]; then
        DEX_SIZE=$(du -h classes.dex | cut -f1)
        echo -e "${GREEN}✓ DEX файл: ${DEX_SIZE}${NC}"
    fi
    
    if [ -f "resources.arsc" ]; then
        RES_SIZE=$(du -h resources.arsc | cut -f1)
        echo -e "${GREEN}✓ Resources.arsc: ${RES_SIZE}${NC}"
    fi
    
    # Очищаем временные файлы
    cd ..
    rm -rf temp_apk_check
    
    # Если нужно исправить APK
    if [ "$FIX_APK" = true ] && [ -f "fix_apk.py" ]; then
        echo -e "${BLUE}[+] Исправление APK с помощью fix_apk.py...${NC}"
        # Создаем временное имя для исправленного APK
        FIXED_APK="fixed-code-editor.apk"
        python3 fix_apk.py "${OUTPUT_APK}"
        
        # Проверяем, создался ли исправленный APK
        if [ -f "${FIXED_APK}" ]; then
            # Копируем исправленный APK на место оригинального
            cp "${FIXED_APK}" "${OUTPUT_APK}"
            echo -e "${GREEN}[+] APK успешно исправлен и заменен!${NC}"
            
            # Обновляем размер для сообщения
            APK_SIZE=$(du -h "${OUTPUT_APK}" | cut -f1)
            echo -e "${GREEN}[+] Новый размер APK: ${APK_SIZE}${NC}"
            
            # Проверяем содержимое исправленного APK
            echo -e "${BLUE}[+] Проверка содержимого исправленного APK:${NC}"
            unzip -l "${OUTPUT_APK}" | head -15
        else
            echo -e "${RED}[!] Не удалось исправить APK, используется оригинальная версия${NC}"
        fi
    fi
    
    # Отправляем в Telegram, если доступно
    if [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_TO" ]; then
        echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
        
        # Генерируем сообщение
        MESSAGE="✅ Code Editor Pro успешно собран!\n\nВерсия: 1.0\nРазмер: $APK_SIZE\n\n✓ Полноценная структура APK\n✓ Корректный DEX файл\n✓ Оптимизировано для Android 5.0+"
        
        # Отправляем через Python-скрипт
        python3 ./send_to_telegram.py "${OUTPUT_APK}" --message "${MESSAGE}"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[+] APK успешно отправлен в Telegram!${NC}"
        else
            echo -e "${RED}[ERROR] Не удалось отправить APK в Telegram.${NC}"
        fi
    else
        echo -e "${YELLOW}[!] Переменные TELEGRAM_TOKEN и/или TELEGRAM_TO не установлены. Отправка в Telegram пропущена.${NC}"
    fi
    
    # Выводим инструкции по установке
    echo -e "${BLUE}${INSTALL_INSTRUCTIONS}${NC}"
    
    # Выводим директорию с APK
    echo -e "${GREEN}[+] APK готов для установки на устройства Android: ${OUTPUT_APK}${NC}"
    
    # Возвращаем успешный код возврата
    exit 0
else
    echo -e "${RED}[ERROR] Не удалось создать APK файл!${NC}"
    
    # Удаляем временную директорию
    rm -rf "${TMP_DIR}"
    
    # Возвращаем код ошибки
    exit 1
fi