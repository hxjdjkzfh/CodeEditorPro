#!/bin/bash
# Скрипт для сборки полноценного APK только через Android SDK

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Выходной путь
OUTPUT_APK="code-editor.apk"

echo -e "${BLUE}========== ✅ Сборка полноценного Android APK через SDK ===========${NC}"

# 1. Создание базовой структуры Android-проекта
echo -e "${BLUE}[+] Создание структуры Android-проекта...${NC}"
mkdir -p android-app/app/src/main/assets
mkdir -p android-app/app/src/main/java/com/example/codeeditor
mkdir -p android-app/app/src/main/res/layout
mkdir -p android-app/app/src/main/res/values
mkdir -p android-app/app/src/main/res/drawable

# 2. Копирование веб-приложения в assets
echo -e "${BLUE}[+] Копирование веб-приложения в assets...${NC}"
cp -r web-app/* android-app/app/src/main/assets/

# 3. Создание ресурсов приложения
echo -e "${BLUE}[+] Создание ресурсов и файлов приложения...${NC}"

# Иконка приложения
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

# Манифест приложения
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

# Строковые ресурсы
cat > android-app/app/src/main/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Code Editor Pro</string>
    <string name="theme_dark">Dark Theme</string>
    <string name="theme_light">Light Theme</string>
    <string name="font_size">Font Size</string>
    <string name="auto_save">Auto Save</string>
    <string name="show_line_numbers">Show Line Numbers</string>
    <string name="drawer_position">Drawer Position</string>
    <string name="position_top">Top</string>
    <string name="position_bottom">Bottom</string>
    <string name="position_left">Left</string>
    <string name="position_right">Right</string>
    <string name="show_drawer_handle">Show Drawer Handle</string>
    <string name="cancel">Cancel</string>
    <string name="save">Save</string>
    <string name="settings">Settings</string>
    <string name="about">About</string>
</resources>
EOF

# Стили
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

# Layout файл
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

# Основная активность
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

# Файлы для сборки
echo -e "${BLUE}[+] Создание файлов сборки Gradle...${NC}"

# build.gradle для приложения
cat > android-app/app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
}

android {
    namespace "com.example.codeeditor"
    compileSdk 34
    
    defaultConfig {
        applicationId "com.example.codeeditor"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
    
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    
    buildFeatures {
        viewBinding true
    }
    
    packagingOptions {
        resources {
            excludes += ['META-INF/LICENSE', 'META-INF/LICENSE.txt', 'META-INF/NOTICE', 'META-INF/NOTICE.txt']
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.webkit:webkit:1.8.0'
}
EOF

# Корневой build.gradle
cat > android-app/build.gradle << 'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.3.0'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# settings.gradle
cat > android-app/settings.gradle << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "CodeEditorPro"
include ':app'
EOF

# gradle.properties
cat > android-app/gradle.properties << 'EOF'
# Project-wide Gradle settings
org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8 -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError

# AndroidX settings
android.useAndroidX=true
android.enableJetifier=true

# Gradle settings
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.daemon=false
android.builder.sdkDownload=true
EOF

# 4. Установка лицензий Android SDK
echo -e "${BLUE}[+] Настройка Android SDK и лицензий...${NC}"

# Определение ANDROID_HOME
ANDROID_HOME=${ANDROID_HOME:-$(pwd)/android-sdk}
mkdir -p $ANDROID_HOME/licenses
echo -e "${BLUE}[+] Используем ANDROID_HOME: $ANDROID_HOME${NC}"

# Создаем файлы лицензий
cat > $ANDROID_HOME/licenses/android-sdk-license << 'EOF'
24333f8a63b6825ea9c5514f83c2829b004d1fee
EOF

# local.properties для проекта
cat > android-app/local.properties << EOF
sdk.dir=$ANDROID_HOME
EOF

# 5. Сборка APK через Gradle
echo -e "${BLUE}[+] Запуск сборки через Gradle...${NC}"

# Переходим в директорию проекта
cd android-app || exit 1

# Создаем gradle wrapper если нужно
if [ ! -f "./gradlew" ]; then
    echo -e "${BLUE}[+] Создаем Gradle wrapper...${NC}"
    gradle wrapper
    chmod +x gradlew
fi

# Запускаем сборку
echo -e "${BLUE}[+] Выполняем сборку APK...${NC}"
./gradlew clean assembleDebug --no-daemon --console=plain

# Проверяем результат сборки
DEBUG_APK="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$DEBUG_APK" ]; then
    echo -e "${GREEN}[+] APK успешно собран: $DEBUG_APK${NC}"
    
    # Копируем APK в корневую директорию
    cp "$DEBUG_APK" "../$OUTPUT_APK"
    echo -e "${GREEN}[+] APK скопирован в ../$OUTPUT_APK${NC}"
    
    # Отправляем в Telegram если возможно
    if [ -f "../send_to_telegram.py" ]; then
        cd .. || exit 1
        echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
        python3 send_to_telegram.py "$OUTPUT_APK" --message "✅ Code Editor Pro APK успешно собран через полноценный Android SDK (размер: $(du -h "$OUTPUT_APK" | cut -f1))"
    fi
    
    exit 0
else
    cd .. || exit 1
    echo -e "${RED}[ERROR] Не удалось собрать APK через Gradle${NC}"
    echo -e "${RED}[ERROR] Проверьте логи сборки выше${NC}"
    exit 1
fi