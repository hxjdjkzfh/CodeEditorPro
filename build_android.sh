#!/bin/bash
#
# Основной скрипт для сборки Android-приложения
# Может использовать различные подходы в зависимости от доступного окружения

# Делаем скрипт исполняемым
chmod +x create_minimal_apk.sh
chmod +x create_minimal_apk.py

# Проверяем, какой метод сборки доступен
if command -v ./gradlew &> /dev/null; then
    echo "=== Using Gradle build system ==="
    # Используем стандартный процесс сборки с Gradle
    chmod +x gradlew
    ./gradlew assembleDebug
else
    echo "=== Using minimal APK generator ==="
    # Используем наш собственный генератор APK
    ./create_minimal_apk.sh
fi

# Проверяем результат
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo "✓ APK created successfully!"
    echo "  Size: $(du -h app/build/outputs/apk/debug/app-debug.apk | cut -f1)"
    echo "  Path: app/build/outputs/apk/debug/app-debug.apk"
    
    # Создаем копию для удобства
    cp app/build/outputs/apk/debug/app-debug.apk ./code-editor.apk
    echo "✓ APK copied to ./code-editor.apk"
    
    echo ""
    echo "To install the APK on your device:"
    echo "1. Enable Developer options on your Android device"
    echo "2. Enable USB debugging"
    echo "3. Connect your device to computer"
    echo "4. Run: adb install -r ./code-editor.apk"
else
    echo "✗ Failed to build APK!"
    exit 1
fi