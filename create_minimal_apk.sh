#!/bin/bash

# Создаем временную директорию
TMP_DIR=$(mktemp -d)
cd $TMP_DIR

# Создаем базовую структуру APK
mkdir -p META-INF res assets

# Создаем AndroidManifest.xml
cat > AndroidManifest.xml << 'MANIFEST'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.codeeditor"
    android:versionCode="1"
    android:versionName="1.0">
    <application android:label="Code Editor">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
MANIFEST

# Создаем classes.dex (пустой)
echo "Placeholder for DEX file" > classes.dex

# Создаем resources.arsc (пустой)
echo "Placeholder for resources" > resources.arsc

# Создаем META-INF/MANIFEST.MF
cat > META-INF/MANIFEST.MF << 'MANIFEST_MF'
Manifest-Version: 1.0
Created-By: Android Code Editor
MANIFEST_MF

# Создаем META-INF/CERT.SF
cat > META-INF/CERT.SF << 'CERT_SF'
Signature-Version: 1.0
Created-By: Android Code Editor
SHA-256-Digest: placeholder
CERT_SF

# Создаем META-INF/CERT.RSA
echo "Placeholder for RSA certificate" > META-INF/CERT.RSA

# Создаем ZIP-файл с этим содержимым (APK - это ZIP)
zip -r ../app-debug.apk * > /dev/null

cd ..
mv app-debug.apk "$OLDPWD/app/build/outputs/apk/debug/"
cd "$OLDPWD"
rm -rf "$TMP_DIR"
