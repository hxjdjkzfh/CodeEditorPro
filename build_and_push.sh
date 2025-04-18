#!/bin/bash
# Скрипт для автоматической сборки APK, пуша коммитов и отправки в Telegram

# Цвета для вывода в консоль
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========== 🚀 Сборка и публикация Android APK ===========${NC}"

# Проверяем доступность секретов для Telegram и GitHub
if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_TO" ]; then
    echo -e "${YELLOW}[!] Отсутствуют секреты для отправки в Telegram${NC}"
    echo -e "${YELLOW}[!] Установите переменные окружения TELEGRAM_TOKEN и TELEGRAM_TO${NC}"
fi

if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_REPOSITORY" ]; then
    echo -e "${YELLOW}[!] Отсутствуют секреты для GitHub${NC}"
    echo -e "${YELLOW}[!] Установите переменные окружения GITHUB_TOKEN и GITHUB_REPOSITORY${NC}"
fi

# Опционально: Принимаем сообщение для коммита как аргумент
COMMIT_MESSAGE="${1:-"Обновление исходного кода и сборка APK"}"

# 1. Запускаем сборку APK через полный SDK
echo -e "${BLUE}[+] Запуск сборки APK через Android SDK...${NC}"
chmod +x build_android.sh
./build_android.sh sdk

# Проверяем результат сборки
if [ ! -f "code-editor.apk" ]; then
    echo -e "${RED}[!] Ошибка при сборке APK${NC}"
    exit 1
fi

echo -e "${GREEN}[+] APK успешно собран${NC}"

# 2. Отправка в Telegram, если секреты доступны
if [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_TO" ]; then
    echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
    python3 send_to_telegram.py code-editor.apk --message "✅ Code Editor Pro APK успешно собран через полный Android SDK!"
else
    echo -e "${YELLOW}[!] Пропускаем отправку в Telegram (отсутствуют секреты)${NC}"
fi

# 3. Создание тега для релиза
DATE_TAG=$(date +"%Y%m%d%H%M")
RELEASE_TAG="v1.0.${DATE_TAG}"
echo -e "${BLUE}[+] Создание тега релиза: ${RELEASE_TAG}${NC}"

# 4. Пуш изменений в GitHub, если работаем в GitHub репозитории
if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPOSITORY" ]; then
    echo -e "${BLUE}[+] Настройка Git для коммита...${NC}"
    git config --global user.name "GitHub Actions"
    git config --global user.email "actions@github.com"
    
    echo -e "${BLUE}[+] Добавление файлов и создание коммита...${NC}"
    git add .
    git commit -m "${COMMIT_MESSAGE}"
    
    echo -e "${BLUE}[+] Создание тега релиза...${NC}"
    git tag -a "${RELEASE_TAG}" -m "Релиз ${RELEASE_TAG}"
    
    echo -e "${BLUE}[+] Пуш изменений и тега в репозиторий...${NC}"
    
    # Используем токен для аутентификации
    GITHUB_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    git push "${GITHUB_URL}" HEAD:main
    git push "${GITHUB_URL}" --tags
    
    echo -e "${GREEN}[+] Изменения успешно отправлены в GitHub репозиторий${NC}"
    
    # Создание GitHub релиза через API
    if command -v curl > /dev/null; then
        echo -e "${BLUE}[+] Создание GitHub релиза через API...${NC}"
        
        # Создаем временный файл для JSON данных
        JSON_FILE=$(mktemp)
        cat > "${JSON_FILE}" << EOF
{
  "tag_name": "${RELEASE_TAG}",
  "name": "Code Editor Pro - ${RELEASE_TAG}",
  "body": "Релиз Code Editor Pro. Полноценный Android-редактор кода с поддержкой множества языков программирования.",
  "draft": false,
  "prerelease": false
}
EOF
        
        # Создаем релиз через GitHub API
        RELEASE_RESPONSE=$(curl -s -X POST \
          -H "Accept: application/vnd.github+json" \
          -H "Authorization: token ${GITHUB_TOKEN}" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases" \
          -d @"${JSON_FILE}")
        
        # Получаем URL для загрузки ассетов
        UPLOAD_URL=$(echo "${RELEASE_RESPONSE}" | grep -o '"upload_url": "[^"]*' | cut -d'"' -f4 | sed 's/{?name,label}//')
        
        if [ -n "${UPLOAD_URL}" ]; then
            echo -e "${BLUE}[+] Загрузка APK в релиз...${NC}"
            
            # Загружаем APK в релиз
            curl -s -X POST \
              -H "Accept: application/vnd.github+json" \
              -H "Authorization: token ${GITHUB_TOKEN}" \
              -H "X-GitHub-Api-Version: 2022-11-28" \
              -H "Content-Type: application/octet-stream" \
              "${UPLOAD_URL}?name=code-editor.apk" \
              --data-binary @"code-editor.apk"
            
            echo -e "${GREEN}[+] APK успешно загружен в GitHub релиз${NC}"
        else
            echo -e "${RED}[!] Ошибка при создании релиза в GitHub${NC}"
        fi
        
        # Удаляем временный файл
        rm -f "${JSON_FILE}"
    else
        echo -e "${YELLOW}[!] curl не найден, пропускаем создание релиза через API${NC}"
    fi
else
    echo -e "${YELLOW}[!] Пропускаем пуш в GitHub (отсутствуют секреты)${NC}"
fi

echo -e "${GREEN}========== ✅ Процесс сборки и публикации успешно завершен ===========${NC}"
echo ""
echo -e "${GREEN}APK доступен по пути: ${PWD}/code-editor.apk${NC}"

# Если APK был успешно отправлен в GitHub релиз, выводим прямую ссылку
if [ -n "$GITHUB_REPOSITORY" ] && [ -n "$RELEASE_TAG" ]; then
    echo -e "${GREEN}Прямая ссылка на скачивание: https://github.com/${GITHUB_REPOSITORY}/releases/download/${RELEASE_TAG}/code-editor.apk${NC}"
fi

exit 0