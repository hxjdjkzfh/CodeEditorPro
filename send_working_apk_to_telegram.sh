#!/bin/bash
# Скрипт для отправки рабочего APK в Telegram

# Проверяем существование APK
if [ ! -f "code-editor.apk" ]; then
    echo "Ошибка: APK не найден"
    exit 1
fi

# Получаем размер файла
APK_SIZE=$(du -h code-editor.apk | cut -f1)

# Отправляем APK в Telegram
python3 send_to_telegram.py code-editor.apk --message "✅ ФИНАЛЬНЫЙ APK Code Editor Pro размером $APK_SIZE с корректным DEX файлом, готов для установки."

echo "APK успешно отправлен в Telegram"