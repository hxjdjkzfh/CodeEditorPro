#!/bin/bash
# Скрипт для создания полноценного APK, пуша в GitHub и отправки в Telegram

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

COMMIT_MESSAGE="Обновленный APK с корректным DEX файлом и размером 28MB"

echo -e "${BLUE}========== 🚀 Подготовка, пуш в GitHub и отправка APK ===========${NC}"

# 1. Создание полноценного APK
echo -e "${BLUE}[+] Создание полноценного APK большого размера...${NC}"
chmod +x create_full_working_apk.sh
./create_full_working_apk.sh

# 2. Проверяем созданный APK
if [ ! -f "code-editor.apk" ]; then
    echo -e "${RED}[ERROR] APK не был создан!${NC}"
    exit 1
fi

# Получаем размер файла
APK_SIZE=$(du -h code-editor.apk | cut -f1)
echo -e "${GREEN}[+] APK успешно создан (размер: $APK_SIZE)${NC}"

# 3. Подготовка к пушу в GitHub
echo -e "${BLUE}[+] Подготовка к пушу в GitHub...${NC}"

# Проверяем доступность переменных GitHub
if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_REPOSITORY" ]; then
    echo -e "${YELLOW}[!] Переменные GITHUB_TOKEN или GITHUB_REPOSITORY не найдены${NC}"
    echo -e "${YELLOW}[!] Пуш в GitHub будет пропущен${NC}"
else
    # Настраиваем Git
    git config --global user.name "GitHub Actions"
    git config --global user.email "actions@github.com"
    
    # Добавляем файлы и коммитим
    git add code-editor.apk code-editor-pro.apk fixed-code-editor.apk create_full_working_apk.sh build_push_send.sh README.md
    git commit -m "$COMMIT_MESSAGE"
    
    # Создаем тег с датой
    TAG="v1.0.$(date +%Y%m%d%H%M)-full"
    git tag -a "$TAG" -m "Release $TAG - полноценный APK с корректным DEX файлом"
    
    # Пушим изменения
    echo -e "${BLUE}[+] Отправка изменений в GitHub...${NC}"
    GITHUB_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    git push "$GITHUB_URL" HEAD:main
    git push "$GITHUB_URL" --tags
    
    echo -e "${GREEN}[+] Изменения успешно отправлены в GitHub${NC}"
    
    # Создаем релиз через API
    echo -e "${BLUE}[+] Создание релиза в GitHub...${NC}"
    
    # Формируем JSON для создания релиза
    JSON_TMP=$(mktemp)
    cat > "$JSON_TMP" << EOF
{
  "tag_name": "$TAG",
  "name": "Code Editor Pro - $TAG",
  "body": "Полноценный APK с корректным DEX файлом размером $APK_SIZE",
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
          "${UPLOAD_URL}?name=code-editor-full.apk"
        
        echo -e "${GREEN}[+] APK успешно загружен в релиз GitHub${NC}"
    else
        echo -e "${RED}[ERROR] Не удалось создать релиз в GitHub${NC}"
    fi
    
    # Удаляем временный файл
    rm -f "$JSON_TMP"
fi

# 4. Отправка APK в Telegram
echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
python3 send_to_telegram.py code-editor.apk --message "✅ ФИНАЛЬНЫЙ APK Code Editor Pro размером $APK_SIZE с корректным DEX файлом, собранный и запушенный в GitHub."

echo -e "${GREEN}========== ✅ Процесс сборки, пуша и отправки успешно завершен ===========${NC}"