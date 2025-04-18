#!/bin/bash
# Скрипт для сборки полноценного APK через Android SDK и отправки в Telegram

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Сообщение для коммита
COMMIT_MESSAGE="${1:-"Обновление APK через чистую сборку Android SDK"}"

echo -e "${BLUE}========== 🚀 Сборка и отправка APK через полный Android SDK ===========${NC}"

# 1. Собираем APK через полный SDK (без fallback)
echo -e "${BLUE}[+] Запуск сборки через полный Android SDK...${NC}"
./build_full_sdk_apk.sh

# Проверяем результат сборки
if [ ! -f "code-editor.apk" ]; then
    echo -e "${RED}[ERROR] Сборка APK через полный Android SDK не удалась${NC}"
    exit 1
fi

# 2. Уведомляем о успешной сборке
echo -e "${GREEN}[+] APK успешно собран через полный Android SDK${NC}"
APK_SIZE=$(du -h code-editor.apk | cut -f1)
echo -e "${GREEN}[+] Размер APK: $APK_SIZE${NC}"

# 3. Отправляем в Telegram
if [ -f "send_to_telegram.py" ]; then
    echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
    python3 send_to_telegram.py code-editor.apk --message "✅ Code Editor Pro APK успешно собран через полноценный Android SDK (размер: $APK_SIZE)"
else
    echo -e "${YELLOW}[!] Скрипт отправки в Telegram не найден${NC}"
fi

# 4. Действия с GitHub если доступны переменные
if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPOSITORY" ]; then
    echo -e "${BLUE}[+] Подготовка к пушу в GitHub...${NC}"
    
    # Настраиваем Git
    git config --global user.name "GitHub Actions"
    git config --global user.email "actions@github.com"
    
    # Добавляем файлы и коммитим
    git add .
    git commit -m "$COMMIT_MESSAGE"
    
    # Создаем тег с датой
    TAG="v1.0.$(date +%Y%m%d%H%M)"
    git tag -a "$TAG" -m "Release $TAG"
    
    # Пушим изменения
    GITHUB_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    git push "$GITHUB_URL" HEAD:main
    git push "$GITHUB_URL" --tags
    
    echo -e "${GREEN}[+] Изменения успешно отправлены в GitHub${NC}"
    
    # Опционально: создаем релиз через API
    if command -v curl > /dev/null; then
        echo -e "${BLUE}[+] Создание релиза в GitHub...${NC}"
        
        # Формируем JSON для создания релиза
        JSON_TMP=$(mktemp)
        cat > "$JSON_TMP" << EOF
{
  "tag_name": "$TAG",
  "name": "Code Editor Pro - $TAG",
  "body": "Полноценный APK собранный через Android SDK",
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
            echo -e "${BLUE}[+] Загрузка APK в релиз...${NC}"
            
            # Загружаем APK файл
            curl -s -X POST \
              -H "Accept: application/vnd.github.v3+json" \
              -H "Authorization: token $GITHUB_TOKEN" \
              -H "Content-Type: application/vnd.android.package-archive" \
              --data-binary @"code-editor.apk" \
              "${UPLOAD_URL}?name=code-editor.apk"
            
            echo -e "${GREEN}[+] APK успешно загружен в релиз GitHub${NC}"
        else
            echo -e "${RED}[ERROR] Не удалось создать релиз в GitHub${NC}"
        fi
        
        # Удаляем временный файл
        rm -f "$JSON_TMP"
    fi
else
    echo -e "${YELLOW}[!] Переменные GitHub не найдены, пропускаем отправку в GitHub${NC}"
fi

echo -e "${GREEN}========== ✅ Процесс сборки и отправки успешно завершен ===========${NC}"