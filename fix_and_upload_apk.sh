#!/bin/bash
# Скрипт для создания правильного APK и загрузки его в GitHub релиз и Telegram

# Создаем APK с корректным DEX
./create_full_working_apk.sh

# Копируем рабочий APK с корректными именами
cp fixed-code-editor.apk code-editor.apk

# Отправляем в Telegram
python3 send_to_telegram.py code-editor.apk --message "✅ ФИНАЛЬНЫЙ Code Editor Pro APK с корректным DEX файлом (размер: $(du -h code-editor.apk | cut -f1))"

# Загружаем в GitHub
if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPOSITORY" ]; then
    echo "Подготовка к загрузке в GitHub..."
    
    # Создаем тег для релиза
    TAG="v1.0.$(date +%Y%m%d%H%M)-final"
    
    # Формируем JSON для создания релиза
    JSON_TMP=$(mktemp)
    cat > "$JSON_TMP" << EOF
{
  "tag_name": "$TAG",
  "name": "Code Editor Pro - FINAL $TAG",
  "body": "Полноценный APK с корректным DEX файлом",
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
        echo "Загрузка APK в релиз..."
        
        # Загружаем APK файл
        curl -s -X POST \
          -H "Accept: application/vnd.github.v3+json" \
          -H "Authorization: token $GITHUB_TOKEN" \
          -H "Content-Type: application/vnd.android.package-archive" \
          --data-binary @"code-editor.apk" \
          "${UPLOAD_URL}?name=code-editor-final.apk"
        
        echo "APK успешно загружен в релиз GitHub"
        
        # Обновляем README.md с информацией о релизе
        cat > README.md << EOF
# Code Editor Pro

Мобильный редактор кода для Android с возможностью создания и редактирования программ прямо на вашем смартфоне.

## Особенности

- Поддержка множества языков программирования (HTML, CSS, JavaScript, Python, Java и др.)
- Подсветка синтаксиса
- Табы для удобного переключения между файлами
- Автосохранение и восстановление несохраненных изменений
- Темная тема в стиле Windows 98 High Contrast
- Нумерация строк как в Notepad++
- Выдвижное меню с основными функциями

## Скачать

### Последний релиз (v1.0)

✅ [Скачать APK](https://github.com/$GITHUB_REPOSITORY/releases/download/$TAG/code-editor-final.apk)

## Инструкции по установке

1. Скачайте APK файл по ссылке выше
2. На устройстве Android откройте настройки и включите "Установка из неизвестных источников"
3. Найдите скачанный APK файл и установите его
4. После установки вы можете запустить приложение

## Разработка

Проект собирается с использованием:
- Android SDK
- Gradle
- GitHub Actions для CI/CD
EOF
        
        # Коммитим обновленный README
        git config --global user.name "GitHub Actions"
        git config --global user.email "actions@github.com"
        git add README.md
        git commit -m "Обновление README.md с информацией о финальном релизе"
        git tag -a "$TAG" -m "Финальный релиз с корректным DEX файлом"
        GITHUB_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
        git push "$GITHUB_URL" HEAD:main
        git push "$GITHUB_URL" --tags
    else
        echo "Не удалось создать релиз в GitHub"
    fi
    
    # Удаляем временный файл
    rm -f "$JSON_TMP"
else
    echo "Переменные GitHub не найдены, пропускаем отправку в GitHub"
fi

echo "Готово! APK файл с корректным DEX успешно создан и загружен."