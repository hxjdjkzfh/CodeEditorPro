#!/bin/bash
# Скрипт для очистки проекта от мусора и создания нового APK

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========== 🧹 Очистка проекта и создание полноценного APK через SDK ===========${NC}"

# 1. Очистка проекта от мусора
echo -e "${BLUE}[+] Очистка проекта от временных файлов...${NC}"

# Удаляем временные файлы и ненужные APK
find . -type f -name "*.apk" ! -name "code-editor.apk" -delete
rm -f *.dex tmp_*.dex
rm -rf download/demo.apk temp_apk/*
rm -rf android-webview-app/build
rm -rf build/outputs

# Список скриптов, которые мы хотим сохранить
KEEP_SCRIPTS=(
    "build_android.sh"
    "clean_and_build.sh"
    "send_to_telegram.py"
)

# Удаляем неиспользуемые скрипты
echo -e "${BLUE}[+] Удаление неиспользуемых скриптов...${NC}"
for script in *.sh; do
    if [[ ! " ${KEEP_SCRIPTS[@]} " =~ " ${script} " ]]; then
        rm -f "$script"
        echo "    Удален: $script"
    fi
done

# 2. Обновление и проверка основных файлов
echo -e "${BLUE}[+] Обновление github workflow для сборки через SDK...${NC}"

mkdir -p .github/workflows

# Создаем обновленный workflow файл
cat > .github/workflows/build_app.yml << 'EOF'
name: Build Android App

# Add permissions needed for actions
permissions:
  contents: write
  packages: write

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build-app:
    name: Build Android APK
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: '17'
        
    - name: Make all scripts executable
      run: |
        chmod +x *.sh
        chmod +x gradlew
        find . -name "gradlew" -exec chmod +x {} \;
        
    - name: Build Android APK (Full SDK method)
      run: |
        ./build_android.sh sdk
        
    - name: Verify APK
      run: |
        ls -lah code-editor.apk
        unzip -l code-editor.apk | grep classes.dex
        
    - name: Upload APK as artifact
      uses: actions/upload-artifact@v4
      with:
        name: code-editor-pro
        path: code-editor.apk
        
    - name: Send APK to Telegram
      env:
        TELEGRAM_TOKEN: ${{ secrets.TELEGRAM_TOKEN }}
        TELEGRAM_TO: ${{ secrets.TELEGRAM_TO }}
      run: |
        python3 send_to_telegram.py code-editor.apk --message "✅ Финальная версия APK Code Editor Pro! Полноценное мобильное приложение для Android с поддержкой всех языков программирования."
        
    - name: Create GitHub Release
      if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master')
      uses: softprops/action-gh-release@v1
      with:
        name: Code Editor Pro - Latest Build
        tag_name: v1.0.${{ github.run_number }}
        files: |
          code-editor.apk
        body: |
          ## Code Editor Pro - Полная версия
          
          Полноценный Android-редактор кода с поддержкой множества языков программирования.
          
          ### Особенности:
          - Подсветка синтаксиса для множества языков
          - Интуитивный интерфейс с вкладками
          - Темная тема в стиле Windows 98 High Contrast
          - Автоматическое сохранение несохраненного кода
          - Панель с настройками и интерфейсом как в Notepad++
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF

# Убедимся, что основные файлы есть и обновим README.md
echo -e "${BLUE}[+] Обновление README.md...${NC}"

cat > README.md << 'EOF'
# Code Editor Pro

Профессиональный редактор кода для Android с поддержкой множества языков программирования.

## Особенности

- Поддержка множества языков программирования (HTML, CSS, JavaScript, Python, Java и др.)
- Подсветка синтаксиса
- Табы для удобного переключения между файлами
- Автосохранение и восстановление несохраненных изменений
- Темная тема в стиле Windows 98 High Contrast
- Нумерация строк как в Notepad++
- Выдвижное меню с основными функциями

## Скачать

### Последняя версия

✅ [Скачать APK](https://github.com/hxjdjkzfh/CodeEditorPro/releases/latest/download/code-editor.apk)

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
- Telegram Bot API для отправки сборок
EOF

# 3. Запуск сборки APK
echo -e "${BLUE}[+] Запуск сборки APK через полноценный Android SDK...${NC}"
chmod +x build_android.sh
./build_android.sh sdk

# 4. Пуш на GitHub и отправка в Telegram
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
    git add -A
    git commit -m "Обновленный APK с полноценной структурой через Android SDK"
    
    # Создаем тег с датой
    TAG="v1.0.$(date +%Y%m%d%H%M)-sdk"
    git tag -a "$TAG" -m "Release $TAG - Full SDK APK"
    
    # Пушим изменения
    echo -e "${BLUE}[+] Отправка изменений в GitHub...${NC}"
    GITHUB_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    git push "$GITHUB_URL" HEAD:main
    git push "$GITHUB_URL" --tags
    
    echo -e "${GREEN}[+] Изменения успешно отправлены в GitHub${NC}"
fi

# 5. Отправка APK в Telegram
echo -e "${BLUE}[+] Отправка APK в Telegram...${NC}"
python3 send_to_telegram.py code-editor.apk --message "✅ Финальная версия Code Editor Pro, собранная с помощью полноценного Android SDK. Включает подсветку синтаксиса, сохранение состояния, вкладки и темную тему."

echo -e "${GREEN}========== ✅ Процесс очистки и сборки успешно завершен ===========${NC}"