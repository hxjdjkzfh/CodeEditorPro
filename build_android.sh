#!/bin/bash
#
# Основной скрипт для сборки Android-приложения
# Выбирает оптимальный метод сборки для корректного APK
# 
# Режимы:
# - sdk: использует полный Android SDK (по умолчанию и рекомендуется)
# - webview: использует улучшенный метод WebView (не рекомендуется, только для тестирования)
# - auto: пробует оба варианта (сначала SDK, затем webview если нужно)
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

# Функция для сборки через полный Android SDK
build_sdk() {
    echo -e "${BLUE}[+] Запуск метода сборки через полный Android SDK...${NC}"
    
    # Создаем базовую структуру Android-проекта
    mkdir -p android-app/app/src/main/assets
    mkdir -p android-app/app/src/main/java/com/example/codeeditor
    mkdir -p android-app/app/src/main/res/layout
    mkdir -p android-app/app/src/main/res/values
    mkdir -p android-app/app/src/main/res/drawable
    
    # Копируем веб-приложение в assets
    echo -e "${BLUE}[+] Копирование веб-приложения в проект${NC}"
    cp -r web-app/* android-app/app/src/main/assets/
    
    # Создаем иконку приложения
    echo -e "${BLUE}[+] Создание ресурсов приложения${NC}"
    cat > android-app/app/src/main/res/drawable/app_icon.xml << 'EOF'
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
    
    # Создаем AndroidManifest.xml
    cat > android-app/app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.codeeditor">
    
    <application
        android:allowBackup="true"
        android:icon="@drawable/app_icon"
        android:label="@string/app_name"
        android:theme="@style/AppTheme">
        
        <activity 
            android:name=".MainActivity" 
            android:exported="true"
            android:configChanges="orientation|screenSize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF
    
    # Создаем строковые ресурсы
    cat > android-app/app/src/main/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Code Editor Pro</string>
</resources>
EOF

    # Создаем стили
    cat > android-app/app/src/main/res/values/styles.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme" parent="android:Theme.Material.NoActionBar">
        <item name="android:colorPrimary">#007ACC</item>
        <item name="android:colorPrimaryDark">#005A9C</item>
        <item name="android:colorAccent">#FF4081</item>
        <item name="android:windowBackground">#1e1e1e</item>
    </style>
</resources>
EOF

    # Создаем файл layout
    cat > android-app/app/src/main/res/layout/activity_main.xml << 'EOF'
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

    # Создаем файл MainActivity.java
    cat > android-app/app/src/main/java/com/example/codeeditor/MainActivity.java << 'EOF'
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
        
        // Инициализируем SharedPreferences для сохранения состояния
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);

        // Инициализируем WebView
        webView = findViewById(R.id.webview);
        WebSettings webSettings = webView.getSettings();
        
        // Включаем JavaScript и DOM storage
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setAllowFileAccess(true);
        
        // Устанавливаем кэширование
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
        
        // Настраиваем WebChromeClient для диалогов JavaScript
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
    
    # Используем create_full_apk.py для создания полноценного APK
    echo -e "${BLUE}[+] Создание полноценного APK с использованием Android SDK${NC}"
    python3 create_full_apk.py
    
    # Проверяем, успешно ли создан APK
    if [ -f "code-editor-pro.apk" ]; then
        cp code-editor-pro.apk "$OUTPUT_APK"
        echo -e "${GREEN}[+] APK успешно собран через полный Android SDK и скопирован в $OUTPUT_APK${NC}"
        
        # Отправляем в Telegram
        echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
        if command -v python3 &> /dev/null && [ -f "send_to_telegram.py" ]; then
            python3 send_to_telegram.py "$OUTPUT_APK" --message "✅ Code Editor Pro APK успешно собран через полный Android SDK!"
        fi
        
        return 0
    else
        echo -e "${RED}[!] Не удалось создать APK через полный Android SDK${NC}"
        # Используем запасной вариант - create_minimal_apk.py
        echo -e "${YELLOW}[+] Использование запасного метода для создания APK...${NC}"
        python3 create_minimal_apk.py
        python3 fix_apk.py code-editor.apk "code-editor-sdk-fallback.apk"
        
        if [ -f "code-editor-sdk-fallback.apk" ]; then
            cp code-editor-sdk-fallback.apk "$OUTPUT_APK"
            echo -e "${YELLOW}[+] APK собран через запасной метод и скопирован в $OUTPUT_APK${NC}"
            return 0
        else
            return 1
        fi
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
    # Автоматический режим - только SDK, без WebView
    echo -e "${BLUE}[+] Автоматический режим: используем только полноценную сборку через SDK${NC}"
    build_sdk
    RESULT=$?
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