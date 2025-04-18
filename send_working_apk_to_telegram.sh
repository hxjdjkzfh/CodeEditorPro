#!/bin/bash
# Скрипт для создания нового APK и немедленной отправки в Telegram

# Создаем новый APK
./create_full_working_apk.sh

# Обнаружение созданного APK
APK_FILES=(*.apk)

echo "Найденные APK файлы:"
for apk in "${APK_FILES[@]}"; do
    SIZE=$(du -h "$apk" | cut -f1)
    echo "$apk (размер: $SIZE)"
    
    # Проверка на наличие DEX файла
    if unzip -l "$apk" | grep -q "classes.dex"; then
        echo "✅ $apk содержит DEX файл"
        
        # Копируем файл как codeeditor-final.apk для гарантии
        cp "$apk" "codeeditor-final.apk"
        
        # Отправляем в Telegram
        if [ -f "send_to_telegram.py" ]; then
            echo "Отправка $apk в Telegram..."
            python3 send_to_telegram.py "$apk" --message "✅ Code Editor Pro APK с рабочим DEX файлом (размер: $SIZE)"
            python3 send_to_telegram.py "codeeditor-final.apk" --message "✅ ФИНАЛЬНЫЙ Code Editor Pro APK (размер: $SIZE) - содержит корректный DEX файл"
        fi
    else
        echo "❌ $apk НЕ содержит DEX файл"
    fi
done

echo "Завершено!"