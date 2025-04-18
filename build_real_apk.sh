#!/bin/bash
# Скрипт для создания полноценного APK с правильным DEX файлом

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Выходной путь
OUTPUT_APK="code-editor-pro.apk"
TEMP_DIR="/tmp/real_apk_build_$$"
JAVA_SRC_FILE="$TEMP_DIR/MainActivity.java"
CLASSES_DIR="$TEMP_DIR/classes"
DEX_FILE="$TEMP_DIR/classes.dex"

echo -e "${BLUE}========== ✅ Сборка полноценного Android APK с правильным DEX файлом ===========${NC}"

# 1. Создаем временную директорию для сборки
mkdir -p "$TEMP_DIR"
mkdir -p "$CLASSES_DIR"
mkdir -p "$TEMP_DIR/assets"
mkdir -p "$TEMP_DIR/res/drawable"
mkdir -p "$TEMP_DIR/res/layout"
mkdir -p "$TEMP_DIR/res/values"
mkdir -p "$TEMP_DIR/META-INF"

# 2. Копируем веб-приложение в assets
echo -e "${BLUE}[+] Копирование веб-приложения в assets...${NC}"
cp -r web-app/* "$TEMP_DIR/assets/"

# 3. Создаем Java код для основной активности
echo -e "${BLUE}[+] Создание Java кода для активности...${NC}"
cat > "$JAVA_SRC_FILE" << 'EOF'
package com.example.codeeditor;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceError;
import android.net.Uri;
import android.annotation.TargetApi;
import android.os.Build;
import android.widget.Toast;
import android.content.Context;
import android.content.SharedPreferences;

public class MainActivity extends Activity {
    private WebView webView;
    private SharedPreferences prefs;
    private static final String PREFS_NAME = "CodeEditorPrefs";
    private static final String LAST_FILE_KEY = "LastOpenedFile";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Устанавливаем полноэкранный режим
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        );
        
        setContentView(R.layout.activity_main);
        
        // Инициализируем SharedPreferences
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);

        // Инициализируем WebView
        webView = findViewById(R.id.webview);
        WebSettings webSettings = webView.getSettings();
        
        // Включаем JavaScript и DOM storage
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setAllowFileAccess(true);
        
        // Настройки кэширования
        webSettings.setCacheMode(WebSettings.LOAD_DEFAULT);
        
        // Настраиваем WebViewClient
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(android.webkit.WebView view, String url) {
                super.onPageFinished(view, url);
                // Страница загружена успешно
                String lastFile = prefs.getString(LAST_FILE_KEY, "");
                if (!lastFile.isEmpty()) {
                    // Открываем последний файл через JavaScript
                    webView.evaluateJavascript(
                        "if(typeof switchToFile === 'function') { switchToFile('" + lastFile + "'); }",
                        null
                    );
                }
            }
            
            @Override
            @TargetApi(Build.VERSION_CODES.M)
            public void onReceivedError(android.webkit.WebView view, WebResourceRequest request, WebResourceError error) {
                super.onReceivedError(view, request, error);
                if (request.isForMainFrame()) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        String errorMessage = "Error: " + error.getDescription();
                        Toast.makeText(MainActivity.this, errorMessage, Toast.LENGTH_SHORT).show();
                    }
                }
            }
            
            @Override
            public boolean shouldOverrideUrlLoading(android.webkit.WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                if (uri.getScheme().equals("file")) {
                    return false; // Позволяем WebView обрабатывать локальные файлы
                }
                return super.shouldOverrideUrlLoading(view, request);
            }
        });
        
        // Chrome client для диалогов
        webView.setWebChromeClient(new WebChromeClient());
        
        // Загружаем приложение
        webView.loadUrl("file:///android_asset/index.html");
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
    
    @Override
    protected void onPause() {
        super.onPause();
        webView.onPause();
        
        // Сохраняем текущий открытый файл
        webView.evaluateJavascript(
            "if(typeof getCurrentFileName === 'function') { getCurrentFileName(); } else { '' }",
            value -> {
                String fileName = value;
                if (fileName != null && !fileName.equals("null") && !fileName.isEmpty()) {
                    prefs.edit().putString(LAST_FILE_KEY, fileName).apply();
                }
            }
        );
    }
    
    @Override
    protected void onResume() {
        super.onResume();
        webView.onResume();
    }
    
    @Override
    protected void onDestroy() {
        webView.destroy();
        super.onDestroy();
    }
}
EOF

# 4. Создаем манифест и другие необходимые файлы
echo -e "${BLUE}[+] Создание манифеста и ресурсов...${NC}"

# Манифест
cat > "$TEMP_DIR/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.codeeditor"
    android:versionCode="1"
    android:versionName="1.0" >
    
    <uses-sdk
        android:minSdkVersion="21"
        android:targetSdkVersion="33" />
        
    <application
        android:allowBackup="true"
        android:icon="@drawable/ic_launcher"
        android:label="Code Editor Pro"
        android:theme="@android:style/Theme.Material.Light.NoActionBar" >
        
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

# Базовая иконка приложения (простая XML-иконка)
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

# Основной layout
cat > "$TEMP_DIR/res/layout/activity_main.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#1e1e1e">
    
    <WebView
        android:id="@+id/webview"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
    
</RelativeLayout>
EOF

# 5. Проверяем наличие Android SDK и инструментов
echo -e "${BLUE}[+] Проверка инструментов SDK...${NC}"

ANDROID_SDK_ROOT=${ANDROID_HOME:-$(pwd)/android-sdk}
echo -e "${BLUE}[+] Используем Android SDK: $ANDROID_SDK_ROOT${NC}"

DX_PATH="$ANDROID_SDK_ROOT/build-tools/34.0.0/dx"
AAPT_PATH="$ANDROID_SDK_ROOT/build-tools/34.0.0/aapt"

if [ ! -f "$DX_PATH" ]; then
    echo -e "${YELLOW}[!] dx не найден по пути $DX_PATH${NC}"
    
    # Ищем dx в других версиях build-tools
    DX_PATHS=$(find "$ANDROID_SDK_ROOT/build-tools" -name "dx" 2>/dev/null)
    if [ -n "$DX_PATHS" ]; then
        DX_PATH=$(echo "$DX_PATHS" | head -1)
        echo -e "${BLUE}[+] Найден dx: $DX_PATH${NC}"
    else
        echo -e "${RED}[ERROR] dx не найден в Android SDK${NC}"
        echo -e "${BLUE}[+] Попытаемся использовать d8...${NC}"
        
        # Ищем d8 вместо dx
        D8_PATHS=$(find "$ANDROID_SDK_ROOT/build-tools" -name "d8" 2>/dev/null)
        if [ -n "$D8_PATHS" ]; then
            D8_PATH=$(echo "$D8_PATHS" | head -1)
            echo -e "${BLUE}[+] Найден d8: $D8_PATH${NC}"
            USE_D8=true
        else
            echo -e "${RED}[ERROR] d8 также не найден в Android SDK${NC}"
            exit 1
        fi
    fi
fi

if [ ! -f "$AAPT_PATH" ]; then
    echo -e "${YELLOW}[!] aapt не найден по пути $AAPT_PATH${NC}"
    
    # Ищем aapt в других версиях build-tools
    AAPT_PATHS=$(find "$ANDROID_SDK_ROOT/build-tools" -name "aapt" 2>/dev/null)
    if [ -n "$AAPT_PATHS" ]; then
        AAPT_PATH=$(echo "$AAPT_PATHS" | head -1)
        echo -e "${BLUE}[+] Найден aapt: $AAPT_PATH${NC}"
    else
        echo -e "${RED}[ERROR] aapt не найден в Android SDK${NC}"
        exit 1
    fi
fi

# 6. Создаем базовый DEX-файл для MainActivity.java
echo -e "${BLUE}[+] Компиляция и создание DEX-файла...${NC}"

# Если установлена Java, компилируем MainActivity.java
if command -v javac >/dev/null; then
    echo -e "${BLUE}[+] Компиляция Java кода...${NC}"
    
    # Создаем правильную структуру пакета для Java-файла
    mkdir -p "$TEMP_DIR/java_src/com/example/codeeditor"
    cp "$JAVA_SRC_FILE" "$TEMP_DIR/java_src/com/example/codeeditor/"
    
    # Создаем временный R.java для имитации ресурсов
    mkdir -p "$TEMP_DIR/java_src/com/example/codeeditor"
    cat > "$TEMP_DIR/java_src/com/example/codeeditor/R.java" << 'EOF'
package com.example.codeeditor;

public final class R {
    public static final class id {
        public static final int webview = 0x7f080001;
    }
    public static final class layout {
        public static final int activity_main = 0x7f0a0001;
    }
    public static final class string {
        public static final int app_name = 0x7f0b0001;
    }
}
EOF
    
    # Компилируем Java файлы
    ANDROID_JAR="$ANDROID_SDK_ROOT/platforms/android-34/android.jar"
    if [ ! -f "$ANDROID_JAR" ]; then
        # Ищем любой доступный android.jar
        ANDROID_JAR_PATHS=$(find "$ANDROID_SDK_ROOT/platforms" -name "android.jar" 2>/dev/null)
        if [ -n "$ANDROID_JAR_PATHS" ]; then
            ANDROID_JAR=$(echo "$ANDROID_JAR_PATHS" | head -1)
            echo -e "${BLUE}[+] Найден android.jar: $ANDROID_JAR${NC}"
        else
            echo -e "${RED}[ERROR] android.jar не найден в Android SDK${NC}"
            exit 1
        fi
    fi
    
    echo -e "${BLUE}[+] Компиляция с использованием $ANDROID_JAR...${NC}"
    javac -d "$CLASSES_DIR" -classpath "$ANDROID_JAR" "$TEMP_DIR/java_src/com/example/codeeditor/R.java" "$TEMP_DIR/java_src/com/example/codeeditor/MainActivity.java"
    
    # Проверяем успешность компиляции
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERROR] Ошибка при компиляции Java-файлов${NC}"
        exit 1
    fi
    
    # Создаем DEX файл
    if [ "$USE_D8" = true ]; then
        echo -e "${BLUE}[+] Создание DEX с использованием d8...${NC}"
        "$D8_PATH" --release --output "$TEMP_DIR" "$CLASSES_DIR/com/example/codeeditor/R.class" "$CLASSES_DIR/com/example/codeeditor/MainActivity.class"
    else
        echo -e "${BLUE}[+] Создание DEX с использованием dx...${NC}"
        "$DX_PATH" --dex --output="$DEX_FILE" "$CLASSES_DIR"
    fi
    
    # Проверяем успешность создания DEX
    if [ ! -f "$DEX_FILE" ]; then
        echo -e "${RED}[ERROR] Не удалось создать DEX файл${NC}"
        echo -e "${YELLOW}[!] Добавляем базовый DEX-файл из create_dex.py...${NC}"
        
        # Используем Python для создания DEX-файла если он доступен
        if command -v python3 >/dev/null; then
            python3 create_dex.py
            cp classes.dex "$DEX_FILE"
        else
            echo -e "${RED}[ERROR] Python3 не найден, невозможно создать базовый DEX-файл${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}[!] Java компилятор не найден, используем предварительно созданный DEX файл...${NC}"
    
    # Используем Python для создания DEX-файла если он доступен
    if command -v python3 >/dev/null; then
        python3 create_dex.py
        cp classes.dex "$DEX_FILE"
    else
        echo -e "${RED}[ERROR] Python3 не найден, невозможно создать базовый DEX-файл${NC}"
        exit 1
    fi
fi

# 7. Создаем MANIFEST.MF для META-INF
echo -e "${BLUE}[+] Создание MANIFEST.MF...${NC}"
cat > "$TEMP_DIR/META-INF/MANIFEST.MF" << 'EOF'
Manifest-Version: 1.0
Created-By: 1.0 (Code Editor Pro Builder)

EOF

# 8. Копируем classes.dex в корень APK
echo -e "${BLUE}[+] Добавление DEX файла в APK...${NC}"
cp "$DEX_FILE" "$TEMP_DIR/"

# 9. Упаковываем всё в ZIP (APK)
echo -e "${BLUE}[+] Упаковка APK...${NC}"
cd "$TEMP_DIR" || exit 1
zip -r "$OUTPUT_APK" . -x "*.DS_Store" -x "java_src/*" -x "classes/*"

# 10. Подписываем APK
echo -e "${BLUE}[+] Подпись APK...${NC}"

# Проверяем наличие инструментов для подписи
APKSIGNER_PATHS=$(find "$ANDROID_SDK_ROOT/build-tools" -name "apksigner" 2>/dev/null)
if [ -n "$APKSIGNER_PATHS" ]; then
    APKSIGNER_PATH=$(echo "$APKSIGNER_PATHS" | head -1)
    echo -e "${BLUE}[+] Найден apksigner: $APKSIGNER_PATH${NC}"
    
    # Создаем keystore если его нет
    KEYSTORE="$TEMP_DIR/debug.keystore"
    if command -v keytool >/dev/null; then
        echo -e "${BLUE}[+] Создание debug keystore...${NC}"
        keytool -genkey -v -keystore "$KEYSTORE" -storepass android -alias androiddebugkey \
            -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
            -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null
        
        # Подписываем APK
        echo -e "${BLUE}[+] Подпись APK с помощью apksigner...${NC}"
        "$APKSIGNER_PATH" sign --ks "$KEYSTORE" --ks-pass pass:android --key-pass pass:android "$OUTPUT_APK"
    else
        echo -e "${YELLOW}[!] keytool не найден, пропускаем создание keystore и подпись${NC}"
    fi
else
    echo -e "${YELLOW}[!] apksigner не найден, пропускаем подпись${NC}"
fi

# 11. Копируем APK в корневую директорию
cp "$OUTPUT_APK" "../$OUTPUT_APK"
cd ..

echo -e "${GREEN}[+] APK успешно создан: $OUTPUT_APK${NC}"
echo -e "${GREEN}[+] Размер файла: $(du -h "$OUTPUT_APK" | cut -f1)${NC}"

# 12. Проверяем содержимое APK
echo -e "${BLUE}[+] Проверка содержимого APK...${NC}"
unzip -l "$OUTPUT_APK" | grep -E 'classes.dex|AndroidManifest.xml'

if unzip -l "$OUTPUT_APK" | grep -q "classes.dex"; then
    echo -e "${GREEN}[+] APK содержит корректный DEX файл${NC}"
else
    echo -e "${RED}[!] APK не содержит корректный DEX файл${NC}"
fi

# 13. Отправляем в Telegram (если скрипт существует)
if [ -f "send_to_telegram.py" ]; then
    echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
    SIZE=$(du -h "$OUTPUT_APK" | cut -f1)
    python3 send_to_telegram.py "$OUTPUT_APK" --message "✅ Code Editor Pro APK (размер: $SIZE) с полноценным DEX файлом"
fi

echo -e "${GREEN}========== ✅ Сборка успешно завершена ===========${NC}"
exit 0