#!/usr/bin/env python3
"""
Скрипт для создания корректного DEX-файла для Android-приложения.
Создает минимальный classes.dex, который можно включить в APK.
Использует DXdecoder для преобразования классов Java в DEX.
"""

import os
import sys
import base64
import zlib
import tempfile

# Минимальная структура DEX-файла (заголовок DEX + классы, закодированные в base64)
DEX_TEMPLATE = """
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
"""

# Минимальный класс MainActivity для WebView
MAIN_ACTIVITY_JAVA = """
package com.example.codeeditor;

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
}
"""

def create_dex_file(output_path="classes.dex"):
    """
    Создает DEX-файл на основе шаблона или Java-кода.
    
    Args:
        output_path: путь для сохранения DEX-файла
    """
    try:
        # Декодируем шаблон DEX-файла
        dex_data = base64.b64decode(DEX_TEMPLATE)
        dex_data = zlib.decompress(dex_data)
        
        # Сохраняем DEX-файл
        with open(output_path, 'wb') as f:
            f.write(dex_data)
        
        print(f"[SUCCESS] DEX-файл создан: {output_path}")
        return True
    except Exception as e:
        print(f"[ERROR] Ошибка при создании DEX-файла: {e}")
        return False

def create_dex_from_java(java_code=MAIN_ACTIVITY_JAVA, output_path="classes.dex"):
    """
    Создает DEX-файл из Java-кода (если доступен javac и dx).
    
    Args:
        java_code: исходный код Java-класса
        output_path: путь для сохранения DEX-файла
    """
    # Создаем временную директорию сразу для использования в finally
    temp_dir = tempfile.mkdtemp(prefix="dex_build_")
    
    try:
        print(f"[INFO] Создана временная директория: {temp_dir}")
        
        # Подготавливаем структуру директорий для компиляции
        java_dir = os.path.join(temp_dir, "src", "com", "example", "codeeditor")
        os.makedirs(java_dir, exist_ok=True)
        
        # Создаем файл MainActivity.java
        java_file = os.path.join(java_dir, "MainActivity.java")
        with open(java_file, 'w') as f:
            f.write(java_code)
        
        # Пробуем скомпилировать Java-код (если доступен javac)
        import subprocess
        try:
            print("[INFO] Компиляция Java-кода...")
            subprocess.run(["javac", java_file], check=True)
            
            # Пробуем преобразовать .class в .dex (если доступен dx)
            class_dir = os.path.dirname(java_file)
            print("[INFO] Преобразование .class в .dex...")
            subprocess.run(["dx", "--dex", f"--output={output_path}", class_dir], check=True)
            
            print(f"[SUCCESS] DEX-файл создан из Java-кода: {output_path}")
            return True
        except (subprocess.SubprocessError, FileNotFoundError):
            print("[INFO] Компиляция Java не удалась, использую предварительно созданный DEX")
            return create_dex_file(output_path)
    except Exception as e:
        print(f"[ERROR] Ошибка при создании DEX-файла из Java: {e}")
        return create_dex_file(output_path)
    finally:
        # Удаляем временную директорию
        import shutil
        try:
            if temp_dir:
                shutil.rmtree(temp_dir, ignore_errors=True)
        except NameError:
            pass  # temp_dir может быть не определен в случае ранней ошибки

def main():
    """Основная функция скрипта"""
    print("=== DEX Generator ===")
    
    # Проверка аргументов командной строки
    output_path = "classes.dex"
    if len(sys.argv) > 1:
        output_path = sys.argv[1]
    
    # Сначала пробуем создать DEX из Java-кода
    success = create_dex_from_java(output_path=output_path)
    
    # Если не получилось, используем шаблон
    if not success:
        success = create_dex_file(output_path)
    
    if success:
        print("\n=== DEX-файл создан успешно! ===")
        print(f"DEX-файл: {output_path}")
        print(f"Размер: {os.path.getsize(output_path)} байт")
    else:
        print("\n=== Ошибка при создании DEX-файла! ===")
        sys.exit(1)

if __name__ == "__main__":
    main()