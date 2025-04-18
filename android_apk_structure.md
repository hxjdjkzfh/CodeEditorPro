# Структура Android APK файла

Данный документ описывает правильную структуру APK файла для совместимости с новейшими версиями Android.

## Основные компоненты APK файла

Корректная структура APK файла включает следующие ключевые компоненты:

1. **AndroidManifest.xml** - обязательный файл, содержащий:
   - Метаданные приложения (имя, версия и т.д.)
   - Разрешения приложения
   - Объявления компонентов (активити, сервисы и т.д.)
   - Минимальная и целевая версия SDK

2. **classes.dex** - скомпилированный байт-код приложения
   - Содержит весь Java/Kotlin код приложения, преобразованный в DEX формат
   - Может быть несколько DEX файлов (classes2.dex, classes3.dex и т.д.) для больших приложений

3. **resources.arsc** - бинарная таблица ресурсов
   - Содержит ссылки на все ресурсы приложения
   - Обеспечивает доступ к ресурсам по их идентификаторам

4. **res/** - директория с ресурсами
   - layout/ - XML макеты экранов
   - drawable/ - изображения и другие графические ресурсы
   - values/ - строки, стили, цвета и другие ресурсы
   - xml/ - XML конфигурации и другие ресурсы

5. **assets/** - директория с произвольными файлами приложения
   - Могут быть HTML/CSS/JS файлы
   - Шрифты, аудио, видео и другие ресурсы
   - Доступ к этим файлам осуществляется через AssetManager API

6. **META-INF/** - метаданные и файлы для подписи APK
   - MANIFEST.MF - список всех файлов APK и их хэшей
   - CERT.SF - список подписей файлов, перечисленных в MANIFEST.MF
   - CERT.RSA (или .DSA, .EC) - публичный ключ и сертификат для проверки подписи

7. **lib/** - (опционально) нативные библиотеки для разных архитектур
   - armeabi-v7a/ - для ARM процессоров
   - arm64-v8a/ - для 64-bit ARM процессоров
   - x86/ - для Intel/AMD x86 процессоров
   - x86_64/ - для 64-bit Intel/AMD процессоров

## Совместимость с Android API уровней

Для обеспечения правильной работы на новейших версиях Android (API level 30+) убедитесь, что:

1. В AndroidManifest.xml явно указаны:
   ```xml
   <manifest ... >
       <uses-sdk
           android:minSdkVersion="24"
           android:targetSdkVersion="34" />
       ...
   </manifest>
   ```

2. Для всех активити установлен атрибут `android:exported`:
   ```xml
   <activity
       android:name=".MainActivity"
       android:exported="true">
       <!-- Для главной активити с интент-фильтром MAIN -->
   </activity>
   ```

3. При использовании WebView включен безопасный режим для Android 8.0+:
   ```java
   if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
       webSettings.setSafeBrowsingEnabled(true);
   }
   ```

## Подпись APK файла

Все APK файлы должны быть подписаны для установки на устройства. Для корректной подписи:

1. Создайте ключ с помощью `keytool`:
   ```bash
   keytool -genkey -v -keystore my-release-key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Подпишите APK файл с помощью `apksigner`:
   ```bash
   apksigner sign --ks my-release-key.keystore --ks-key-alias alias_name my-app.apk
   ```

3. Проверьте подпись:
   ```bash
   apksigner verify --verbose my-app.apk
   ```

## Проверка структуры APK

Вы можете проверить структуру APK файла с помощью:

1. Утилиты `aapt` или `aapt2`:
   ```bash
   aapt dump badging my-app.apk
   ```

2. Распаковки APK как ZIP-архива:
   ```bash
   unzip -l my-app.apk
   ```

## Решение проблемы "Problem parsing the package"

Ошибка "Problem parsing the package" обычно возникает по следующим причинам:

1. Несовместимость APK с версией Android устройства
2. Поврежденный или неправильно подписанный APK файл
3. Некорректный AndroidManifest.xml

Для решения:
1. Убедитесь, что minSdkVersion в манифесте соответствует версии Android на устройстве
2. Проверьте, что APK правильно подписан
3. Проверьте AndroidManifest.xml на наличие синтаксических ошибок
4. Используйте официальную сборку через Gradle вместо ручного создания APK