#!/usr/bin/env python3
"""
Скрипт для отправки файлов (APK) в Telegram чат или канал.
Использует Telegram Bot API для отправки сообщений и файлов.

Для использования требуются секреты:
- TELEGRAM_TOKEN - токен бота Telegram
- TELEGRAM_TO - ID чата для отправки (может быть ID пользователя, группы или канала)

Переменные должны быть заданы как переменные окружения или как секреты в GitHub Actions.
"""

import os
import sys
import requests
import datetime
import argparse

def send_to_telegram(file_path, message, token=None, chat_id=None):
    """
    Отправляет файл в Telegram с сопроводительным сообщением.
    
    Args:
        file_path: Путь к файлу для отправки
        message: Сопроводительное сообщение
        token: Telegram Bot API токен (опционально, если задан в окружении)
        chat_id: ID чата для отправки (опционально, если задан в окружении)
        
    Returns:
        bool: True если отправка успешна, False в случае ошибки
    """
    # Получаем API токен и ID чата
    token = token or os.environ.get("TELEGRAM_TOKEN")
    chat_id = chat_id or os.environ.get("TELEGRAM_TO")
    
    # Проверяем наличие необходимых параметров
    if not token:
        print("[ERROR] Не найден Telegram API токен. Установите переменную окружения TELEGRAM_TOKEN.")
        return False
    
    if not chat_id:
        print("[ERROR] Не найден ID чата. Установите переменную окружения TELEGRAM_TO.")
        return False
    
    # Проверяем наличие файла
    if not os.path.exists(file_path):
        print(f"[ERROR] Файл не найден: {file_path}")
        return False
    
    # Добавляем время к сообщению
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    full_message = f"{message}\n\nВремя: {now}"
    
    # Добавляем информацию о GitHub репозитории, если доступно
    github_repo = os.environ.get("GITHUB_REPOSITORY")
    github_run = os.environ.get("GITHUB_RUN_NUMBER")
    github_sha = os.environ.get("GITHUB_SHA")
    
    if github_repo:
        full_message += f"\n\nРепозиторий: {github_repo}"
        
    if github_run:
        full_message += f"\nСборка: #{github_run}"
        
    if github_sha and len(github_sha) >= 7:
        short_sha = github_sha[:7]
        full_message += f"\nКоммит: {short_sha}"
    
    # Добавляем информацию о размере файла
    if os.path.exists(file_path):
        size_kb = os.path.getsize(file_path) / 1024
        full_message += f"\n\nРазмер файла: {size_kb:.2f} KB"
    
    # Отправляем файл
    try:
        print(f"[INFO] Отправка файла {file_path} в Telegram...")
        
        # URL для отправки документа через Bot API
        url = f"https://api.telegram.org/bot{token}/sendDocument"
        
        # Подготавливаем файл и параметры запроса
        with open(file_path, 'rb') as file:
            files = {'document': file}
            data = {'chat_id': chat_id, 'caption': full_message}
            
            # Отправляем запрос
            response = requests.post(url, files=files, data=data)
            
        # Проверяем результат
        if response.status_code == 200 and response.json().get('ok'):
            print("[SUCCESS] Файл успешно отправлен в Telegram!")
            return True
        else:
            print(f"[ERROR] Ошибка при отправке: {response.text}")
            return False
            
    except Exception as e:
        print(f"[ERROR] Произошла ошибка при отправке: {str(e)}")
        return False

def main():
    """Основная функция скрипта"""
    # Создаем парсер аргументов командной строки
    parser = argparse.ArgumentParser(description='Отправка файла в Telegram чат.')
    parser.add_argument('file', help='Путь к файлу для отправки')
    parser.add_argument('--message', '-m', default="✅ Файл создан успешно!", 
                        help='Сопроводительное сообщение (по умолчанию: "✅ Файл создан успешно!")')
    parser.add_argument('--token', '-t', help='Telegram Bot API токен (опционально)')
    parser.add_argument('--chat', '-c', help='ID чата для отправки (опционально)')
    
    # Парсим аргументы
    args = parser.parse_args()
    
    # Отправляем файл
    if send_to_telegram(args.file, args.message, args.token, args.chat):
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()