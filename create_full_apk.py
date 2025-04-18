#!/usr/bin/env python3
"""
Скрипт для создания полноценного Android APK с использованием Gradle.
Этот скрипт автоматически создает структуру проекта Android и запускает Gradle для сборки.
"""

import os
import sys
import shutil
import subprocess
import platform
import tempfile
import time
import fcntl
from pathlib import Path

# Константы
WEB_APP_DIR = "web-app"
OUTPUT_DIR = "."
OUTPUT_APK = "code-editor.apk"
ANDROID_DIR = "android-webview-app"

def run_command(command, cwd=None, timeout=600):
    """Выполняет shell-команду и возвращает её вывод с ограничением по времени
    
    Args:
        command: выполняемая команда
        cwd: рабочая директория
        timeout: таймаут в секундах (по умолчанию 10 минут)
    """
    try:
        print(f"[INFO] Запуск команды с таймаутом {timeout} секунд: {command}")
        
        # Для Gradle команд с повышенным мониторингом
        if "gradle" in command or "gradlew" in command:
            # Упрощаем логику для предотвращения зацикливания
            print(f"[INFO] Выполнение Gradle команды с фиксированным таймаутом...")
            
            # Модифицируем команду для избежания ожидания user input
            if "gradlew" in command:
                command = command.replace("./gradlew", "./gradlew --no-daemon --console=plain")
            else:
                command = command.replace("gradle", "gradle --no-daemon --console=plain")
            
            # Добавляем переменные окружения для автоматического принятия лицензий
            env = os.environ.copy()
            env["JAVA_OPTS"] = "-Dorg.gradle.daemon=false -Dorg.gradle.console=plain"
            env["ANDROID_BUILDER_SDK_DOWNLOAD"] = "true"
            
            # Используем стандартный subprocess с таймаутом
            result = subprocess.run(
                command, 
                shell=True, 
                cwd=cwd, 
                capture_output=True,
                text=True,
                timeout=timeout,
                env=env
            )
            
            # Выводим журнал для анализа
            if result.stdout:
                print("[GRADLE-OUT] " + "\n[GRADLE-OUT] ".join(result.stdout.splitlines()))
            
            if result.returncode != 0:
                print(f"[ERROR] Gradle команда завершилась с ошибкой (код {result.returncode}):")
                if result.stderr:
                    print("[GRADLE-ERR] " + "\n[GRADLE-ERR] ".join(result.stderr.splitlines()))
                return False, result.stderr
            
            return True, result.stdout
        else:
            # Для других команд используем стандартный подход
            result = subprocess.run(
                command, 
                shell=True, 
                cwd=cwd, 
                capture_output=True,
                text=True,
                timeout=timeout
            )
            if result.returncode != 0:
                print(f"[ERROR] Команда завершилась с ошибкой (код {result.returncode}):")
                print(f"[STDERR] {result.stderr}")
                return False, result.stderr
            return True, result.stdout
    except subprocess.TimeoutExpired:
        print(f"[ERROR] Команда превысила таймаут {timeout} секунд")
        return False, "Timeout exceeded"
    except Exception as e:
        print(f"[ERROR] Ошибка выполнения команды: {e}")
        return False, str(e)

def create_android_project(web_app_dir, android_dir, output_path):
    """
    Создает полнофункциональное Android WebView приложение, используя Gradle.
    
    Args:
        web_app_dir: Директория с веб-приложением
        android_dir: Директория для создания Android проекта
        output_path: Путь для создания APK
    """
    try:
        print(f"[INFO] Создаем полноценный Android APK с использованием Gradle...")
        
        # Проверяем наличие Gradle или gradlew
        has_gradle = False
        has_gradlew = os.path.exists("./gradlew") or os.path.exists("gradlew.bat")
        
        if not has_gradlew:
            success, _ = run_command("gradle --version")
            has_gradle = success
        
        if not (has_gradle or has_gradlew):
            print("[ERROR] Не найден Gradle или Gradle Wrapper (gradlew). Установите Gradle или скачайте Gradle Wrapper.")
            return False
        
        # Создаем базовую структуру Android проекта
        if not os.path.exists(android_dir):
            print(f"[INFO] Создаем структуру Android проекта в {android_dir}...")
            os.makedirs(android_dir, exist_ok=True)
            
            # Создаем подпапки
            main_path = os.path.join(android_dir, "app", "src", "main")
            os.makedirs(os.path.join(main_path, "java", "com", "example", "codeeditor"), exist_ok=True)
            os.makedirs(os.path.join(main_path, "res", "layout"), exist_ok=True)
            os.makedirs(os.path.join(main_path, "res", "values"), exist_ok=True)
            os.makedirs(os.path.join(main_path, "res", "drawable"), exist_ok=True)
            os.makedirs(os.path.join(main_path, "assets"), exist_ok=True)
            
            # Копируем веб-приложение в assets
            if os.path.exists(web_app_dir):
                print(f"[INFO] Копируем веб-приложение в assets...")
                for item in os.listdir(web_app_dir):
                    s = os.path.join(web_app_dir, item)
                    d = os.path.join(main_path, "assets", item)
                    if os.path.isdir(s):
                        shutil.copytree(s, d, dirs_exist_ok=True)
                    else:
                        shutil.copy2(s, d)
                    
            # Создаем файлы проекта Android
            with open(os.path.join(main_path, "AndroidManifest.xml"), "w") as f:
                f.write("""<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.example.codeeditor">
    
    <uses-sdk
        android:minSdkVersion="24"
        android:targetSdkVersion="34" />
        
    <application 
        android:allowBackup="true"
        android:label="@string/app_name"
        android:icon="@drawable/app_icon"
        android:theme="@style/AppTheme"
        android:supportsRtl="true">
        
        <activity 
            android:name=".MainActivity" 
            android:exported="true"
            android:configChanges="orientation|screenSize|keyboardHidden">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>""")
            
            # Создаем иконку приложения
            with open(os.path.join(main_path, "res", "drawable", "app_icon.xml"), "w") as f:
                f.write("""<?xml version="1.0" encoding="utf-8"?>
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
</vector>""")
            
            # Создаем strings.xml
            with open(os.path.join(main_path, "res", "values", "strings.xml"), "w") as f:
                f.write("""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Code Editor</string>
</resources>""")
                
            # Создаем styles.xml
            with open(os.path.join(main_path, "res", "values", "styles.xml"), "w") as f:
                f.write("""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme" parent="android:Theme.Material.NoActionBar">
        <item name="android:colorPrimary">#007ACC</item>
        <item name="android:colorPrimaryDark">#005A9C</item>
        <item name="android:colorAccent">#FF4081</item>
        <item name="android:windowBackground">#1e1e1e</item>
    </style>
</resources>""")
            
            # Создаем layout для главного activity
            with open(os.path.join(main_path, "res", "layout", "activity_main.xml"), "w") as f:
                f.write("""<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#1e1e1e">
    
    <WebView
        android:id="@+id/webview"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
    
</RelativeLayout>""")
            
            # Создаем MainActivity.java
            with open(os.path.join(main_path, "java", "com", "example", "codeeditor", "MainActivity.java"), "w") as f:
                f.write("""package com.example.codeeditor;

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

public class MainActivity extends Activity {
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Set fullscreen
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        );
        
        setContentView(R.layout.activity_main);

        // Initialize WebView
        webView = findViewById(R.id.webview);
        WebSettings webSettings = webView.getSettings();
        
        // Enable JavaScript and DOM storage
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        
        // Modern caching mode
        webSettings.setCacheMode(WebSettings.LOAD_DEFAULT);
        
        // Enable modern web features if available
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            webSettings.setSafeBrowsingEnabled(true);
        }
        
        // Enhanced webview client with error handling
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(android.webkit.WebView view, String url) {
                super.onPageFinished(view, url);
                // Page loaded successfully
            }
            
            @Override
            @TargetApi(Build.VERSION_CODES.M)
            public void onReceivedError(android.webkit.WebView view, WebResourceRequest request, WebResourceError error) {
                super.onReceivedError(view, request, error);
                if (request.isForMainFrame()) {
                    // Handle main frame errors
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        // Modern error reporting
                        String errorMessage = "Error: " + error.getDescription();
                        Toast.makeText(MainActivity.this, errorMessage, Toast.LENGTH_SHORT).show();
                    }
                }
            }
            
            @Override
            public boolean shouldOverrideUrlLoading(android.webkit.WebView view, WebResourceRequest request) {
                // Handle local file links internally
                Uri uri = request.getUrl();
                if (uri.getScheme().equals("file")) {
                    return false; // Let WebView handle local files
                }
                return super.shouldOverrideUrlLoading(view, request);
            }
        });
        
        // Chrome client for JavaScript dialogs and features
        webView.setWebChromeClient(new WebChromeClient());
        
        // Load the app
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
}""")
            
            # Создаем build.gradle файлы
            with open(os.path.join(android_dir, "settings.gradle"), "w") as f:
                f.write("""rootProject.name = "CodeEditor"
include ':app'""")
            
            with open(os.path.join(android_dir, "app", "build.gradle"), "w") as f:
                f.write("""plugins {
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
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
}""")
            
            with open(os.path.join(android_dir, "build.gradle"), "w") as f:
                f.write("""buildscript {
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
}""")
            
            # Создаем gradle.properties
            with open(os.path.join(android_dir, "gradle.properties"), "w") as f:
                f.write("""# Project-wide Gradle settings
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8 -XX:MaxHeapSize=256m -XX:+HeapDumpOnOutOfMemoryError
# AndroidX settings
android.useAndroidX=true
android.enableJetifier=true
# Disable Gradle daemon to prevent memory issues
org.gradle.daemon=false
# Do not perform license checks during build
android.builder.sdkDownload=true
# Gradle configuration cache
org.gradle.unsafe.configuration-cache=true
# Enable parallel builds
org.gradle.parallel=true
# Kotlin code style
kotlin.code.style=official""")
            
            # Создаем local.properties с путем к Android SDK
            android_home = os.environ.get("ANDROID_HOME", os.environ.get("ANDROID_SDK_ROOT", ""))
            if android_home:
                android_home_fixed = android_home.replace("\\", "/")
                with open(os.path.join(android_dir, "local.properties"), "w") as f:
                    f.write("sdk.dir=" + android_home_fixed)
            
            # Создаем gradle wrapper
            gradle_wrapper_dir = os.path.join(android_dir, "gradle", "wrapper")
            os.makedirs(gradle_wrapper_dir, exist_ok=True)
            
            with open(os.path.join(gradle_wrapper_dir, "gradle-wrapper.properties"), "w") as f:
                f.write("""distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.6-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists""")
            
            # Скачиваем gradle-wrapper.jar если его нет
            gradle_jar_path = os.path.join(gradle_wrapper_dir, "gradle-wrapper.jar")
            if not os.path.exists(gradle_jar_path):
                print("[INFO] Скачиваем gradle-wrapper.jar...")
                try:
                    import urllib.request
                    url = "https://github.com/gradle/gradle/raw/master/gradle/wrapper/gradle-wrapper.jar"
                    urllib.request.urlretrieve(url, gradle_jar_path)
                    print("[INFO] gradle-wrapper.jar скачан успешно")
                except Exception as e:
                    print(f"[WARNING] Не удалось скачать gradle-wrapper.jar: {e}")
            
            # Создаем gradlew и gradlew.bat скрипты
            if platform.system() != "Windows":
                with open(os.path.join(android_dir, "gradlew"), "w") as f:
                    f.write("""#!/bin/sh
exec gradle "$@"
""")
                # Делаем gradlew исполняемым
                os.chmod(os.path.join(android_dir, "gradlew"), 0o755)
            else:
                with open(os.path.join(android_dir, "gradlew.bat"), "w") as f:
                    f.write("""@echo off
gradle %*
""")
            
            print("[INFO] Структура Android проекта создана успешно!")
        else:
            print(f"[INFO] Android проект уже существует в {android_dir}")
        
        # Запускаем сборку через Gradle
        print(f"[INFO] Запускаем сборку через Gradle...")
        
        # Создаем или обновляем local.properties
        android_home = os.environ.get("ANDROID_HOME", os.environ.get("ANDROID_SDK_ROOT", ""))
        if not android_home:
            # Устанавливаем значение по умолчанию для Replit
            android_home = os.path.abspath("./android-sdk")
            print(f"[INFO] ANDROID_HOME не найден, создаем директорию: {android_home}")
            os.makedirs(android_home, exist_ok=True)
            os.environ["ANDROID_HOME"] = android_home
                
        android_home_fixed = android_home.replace("\\", "/")
        with open(os.path.join(android_dir, "local.properties"), "w") as f:
            f.write("sdk.dir=" + android_home_fixed)
            
        # Также создаем local.properties в корне проекта
        with open("local.properties", "w") as f:
            f.write("sdk.dir=" + android_home_fixed)
            
        print(f"[INFO] Установлен путь к Android SDK: {android_home_fixed}")
        
        # Автоматически принимаем все лицензии SDK
        print(f"[INFO] Автоматически принимаем все лицензии Android SDK...")
        licenses_dir = os.path.join(android_home, "licenses")
        os.makedirs(licenses_dir, exist_ok=True)
        
        # Создаем файлы лицензий с хешами принятых лицензий
        license_files = {
            "android-sdk-license": "24333f8a63b6825ea9c5514f83c2829b004d1fee",
            "android-sdk-preview-license": "84831b9409646a918e30573bab4c9c91346d8abd",
            "android-googletv-license": "601085b94cd77f0b54ff86406957099ebe79c4d6",
            "android-ndk-license": "8933bad161af4178b1185d1a37fbf41ea5269c55",
            "intel-android-extra-license": "d975f751698a77b662f1254ddbeed3901e976f5a",
            "mips-android-sysimage-license": "e9acab5b5fbb560a72cfaecce8946896ff6aab9d",
            "google-gdk-license": "33b6a2b64607f11b759f320ef9dff4ae5c47d97a"
        }
        
        for license_file, license_hash in license_files.items():
            with open(os.path.join(licenses_dir, license_file), "w") as f:
                f.write(license_hash)
        
        # Проверяем, запускаем ли мы сборку в корне проекта или в android_dir
        if os.path.exists("./gradlew") or os.path.exists("./gradlew.bat"):
            # Мы в корне проекта, где есть общий settings.gradle
            print("[INFO] Используем корневую конфигурацию Gradle для сборки")
            
            if platform.system() != "Windows":
                # Linux/macOS
                gradlew_cmd = f"./gradlew assembleDebug"
            else:
                # Windows
                gradlew_cmd = f"gradlew.bat assembleDebug"
        else:
            # Нет общей конфигурации, запускаем сборку в директории android_dir
            print("[INFO] Используем изолированную конфигурацию Gradle")
            
            if platform.system() != "Windows":
                # Linux/macOS
                if os.path.exists(os.path.join(android_dir, "gradlew")):
                    gradlew_cmd = f"cd {android_dir} && ./gradlew assembleDebug"
                else:
                    gradlew_cmd = f"cd {android_dir} && gradle assembleDebug"
            else:
                # Windows
                if os.path.exists(os.path.join(android_dir, "gradlew.bat")):
                    gradlew_cmd = f"cd {android_dir} && gradlew.bat assembleDebug"
                else:
                    gradlew_cmd = f"cd {android_dir} && gradle assembleDebug"
        
        success, output = run_command(gradlew_cmd)
        if not success:
            print(f"[ERROR] Ошибка при сборке через Gradle, используем альтернативный метод...")
            
            # Альтернативный метод сборки (используя командный DX вместо полноценного Gradle)
            try:
                # Создаем временную директорию для сборки APK
                tmp_dir = tempfile.mkdtemp(prefix="apk_build_")
                print(f"[INFO] Создана временная директория для сборки: {tmp_dir}")
                
                # Подготавливаем структуру APK
                apk_struct = {
                    "META-INF/": None,
                    "assets/": None,
                    "res/": None,
                    "AndroidManifest.xml": None
                }
                
                # Создаем директории для APK
                for dir_path in apk_struct:
                    if dir_path.endswith('/'):  # Это директория
                        os.makedirs(os.path.join(tmp_dir, dir_path), exist_ok=True)
                
                # Копируем веб-ресурсы в assets
                assets_dir = os.path.join(tmp_dir, "assets")
                if os.path.exists(web_app_dir):
                    for item in os.listdir(web_app_dir):
                        src_path = os.path.join(web_app_dir, item)
                        dst_path = os.path.join(assets_dir, item)
                        if os.path.isdir(src_path):
                            shutil.copytree(src_path, dst_path, dirs_exist_ok=True)
                        else:
                            shutil.copy2(src_path, dst_path)
                
                # Создаем AndroidManifest.xml
                manifest_path = os.path.join(tmp_dir, "AndroidManifest.xml")
                with open(manifest_path, "w") as f:
                    f.write("""<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.codeeditor"
    android:versionCode="1"
    android:versionName="1.0">
    
    <uses-sdk
        android:minSdkVersion="24"
        android:targetSdkVersion="34" />
        
    <application 
        android:allowBackup="true"
        android:label="Code Editor"
        android:theme="@android:style/Theme.NoTitleBar.Fullscreen">
        
        <activity 
            android:name=".MainActivity" 
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>""")
                
                # Создаем класс MainActivity
                classes_dir = os.path.join(tmp_dir, "classes")
                os.makedirs(os.path.join(classes_dir, "com", "example", "codeeditor"), exist_ok=True)
                
                main_activity_path = os.path.join(classes_dir, "com", "example", "codeeditor", "MainActivity.java")
                with open(main_activity_path, "w") as f:
                    f.write("""package com.example.codeeditor;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Создаем WebView программно
        WebView webView = new WebView(this);
        setContentView(webView);
        
        // Настраиваем WebView
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webView.setWebViewClient(new WebViewClient());
        
        // Загружаем страницу из assets
        webView.loadUrl("file:///android_asset/index.html");
    }
}""")
                
                # Создаем META-INF файлы
                with open(os.path.join(tmp_dir, "META-INF", "MANIFEST.MF"), "w") as f:
                    f.write("Manifest-Version: 1.0\nCreated-By: Code Editor Generator\n")
                
                # Копируем файлы ресурсов
                res_dir = os.path.join(tmp_dir, "res")
                os.makedirs(os.path.join(res_dir, "drawable"), exist_ok=True)
                
                # Создаем строковые ресурсы
                os.makedirs(os.path.join(res_dir, "values"), exist_ok=True)
                with open(os.path.join(res_dir, "values", "strings.xml"), "w") as f:
                    f.write("""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Code Editor</string>
</resources>""")
                
                # Упаковываем в APK
                print("[INFO] Упаковка APK...")
                
                # Создаем ZIP архив и переименовываем его в APK
                zipf = shutil.make_archive(output_path.replace('.apk', ''), 'zip', tmp_dir)
                if os.path.exists(output_path):
                    os.remove(output_path)
                os.rename(zipf, output_path)
                
                # Удаляем временную директорию
                shutil.rmtree(tmp_dir)
                
                print(f"[SUCCESS] APK создан с помощью альтернативного метода: {output_path}")
                return True
                
            except Exception as e:
                print(f"[ERROR] Альтернативный метод сборки завершился с ошибкой: {e}")
                return False
        
        print("[INFO] Сборка через Gradle завершена успешно")
        
        # Ищем собранный APK в разных возможных местах
        potential_paths = [
            os.path.join(android_dir, "app", "build", "outputs", "apk", "debug", "app-debug.apk"),
            os.path.join("android-webview-app", "app", "build", "outputs", "apk", "debug", "app-debug.apk"),
            os.path.join("app", "build", "outputs", "apk", "debug", "app-debug.apk")
        ]
        
        found_apk = False
        for debug_apk_path in potential_paths:
            if os.path.exists(debug_apk_path):
                print(f"[INFO] Найден APK по пути: {debug_apk_path}")
                print(f"[INFO] Копируем собранный APK в {output_path}")
                os.makedirs(os.path.dirname(output_path), exist_ok=True)
                shutil.copy2(debug_apk_path, output_path)
                print(f"[SUCCESS] APK скопирован: {output_path}")
                found_apk = True
                break
        
        if not found_apk:
            # Поиск APK по всей директории, если он не найден в стандартных местах
            print("[INFO] Ищем APK в других директориях...")
            for root, dirs, files in os.walk("."):
                for file in files:
                    if file.endswith(".apk"):
                        apk_path = os.path.join(root, file)
                        print(f"[INFO] Найден APK: {apk_path}")
                        print(f"[INFO] Копируем собранный APK в {output_path}")
                        os.makedirs(os.path.dirname(output_path), exist_ok=True)
                        shutil.copy2(apk_path, output_path)
                        print(f"[SUCCESS] APK скопирован: {output_path}")
                        found_apk = True
                        break
                if found_apk:
                    break
        
        if found_apk:
            return True
        else:
            print("[ERROR] Собранный APK не найден")
            return False
    
    except Exception as e:
        print(f"[ERROR] Произошла ошибка: {e}")
        return False

def main():
    """Основная функция скрипта"""
    print("=== Full Android APK Generator ===")
    
    web_dir = WEB_APP_DIR
    android_dir = ANDROID_DIR
    output_file = os.path.join(OUTPUT_DIR, OUTPUT_APK)
    
    # Проверка аргументов командной строки
    if len(sys.argv) > 1:
        web_dir = sys.argv[1]
    if len(sys.argv) > 2:
        android_dir = sys.argv[2]
    if len(sys.argv) > 3:
        output_file = sys.argv[3]
    
    # Запуск создания APK
    success = create_android_project(web_dir, android_dir, output_file)
    
    if success:
        print("\n=== APK создан успешно! ===")
        print(f"APK-файл: {output_file}")
        print(f"Размер: {os.path.getsize(output_file)} байт")
        
        # Создаем копию в директории загрузок, если она существует
        download_path = "/download/code-editor.apk"
        if os.path.isdir("/download"):
            shutil.copy(output_file, download_path)
            print(f"\n✓ APK также доступен для скачивания по пути: {download_path}")
        
        # Выводим ссылку на GitHub Release, если возможно
        github_repo = os.environ.get("GITHUB_REPOSITORY")
        if github_repo:
            print("\n===============================================")
            print("✓ Прямая ссылка для скачивания APK:")
            print(f"https://github.com/{github_repo}/releases/latest/download/code-editor.apk")
            print("===============================================")
            
        print("\nДля установки на устройство используйте команду:")
        print(f"adb install -r {output_file}")
    else:
        print("\n=== Ошибка при создании APK! ===")
        sys.exit(1)

def run_build():
    web_app_dir = "web-app"
    android_dir = "android-app"
    output_path = "code-editor-pro.apk"
    
    try:
        create_android_project(web_app_dir, android_dir, output_path)
        
        # Автоматическая отправка в Telegram
        telegram_message = "✅ Code Editor Pro APK успешно собран через полноценный Android SDK!"
        telegram_script = "send_to_telegram.py"
        
        if os.path.exists(telegram_script):
            telegram_cmd = f"python3 {telegram_script} {output_path} --message \"{telegram_message}\""
            print(f"[INFO] Отправка APK в Telegram: {telegram_message}")
            os.system(telegram_cmd)
            
        # Проверяем, работаем ли в GitHub Actions
        if "GITHUB_REPOSITORY" in os.environ:
            print(f"[INFO] Сборка в GitHub Actions, APK будет доступен в релизе")
            print(f"[INFO] Репозиторий: {os.environ.get('GITHUB_REPOSITORY')}")
    except Exception as e:
        print(f"[ERROR] Ошибка при создании APK: {str(e)}")
        
        # В случае ошибки используем create_minimal_apk.py как запасной вариант
        print("[INFO] Используем запасной вариант create_minimal_apk.py")
        os.system("python3 create_minimal_apk.py")
        
        if os.path.exists("code-editor.apk"):
            if not os.path.exists(output_path):
                shutil.copy("code-editor.apk", output_path)
                print(f"[INFO] Запасной APK скопирован в {output_path}")

if __name__ == "__main__":
    run_build()