package com.example.codeeditor;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceError;
import android.net.Uri;
import android.annotation.TargetApi;
import android.os.Build;
import android.widget.Toast;
import android.content.Context;
import android.content.SharedPreferences;

public class MainActivity extends Activity {
    private WebView webView;
    private SharedPreferences prefs;
    private static final String PREFS_NAME = "CodeEditorPrefs";
    private static final String LAST_FILE_KEY = "LastOpenedFile";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Устанавливаем полноэкранный режим
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        );
        
        setContentView(R.layout.activity_main);
        
        // Инициализируем SharedPreferences
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);

        // Инициализируем WebView
        webView = findViewById(R.id.webview);
        WebSettings webSettings = webView.getSettings();
        
        // Включаем JavaScript и DOM storage
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setAllowFileAccess(true);
        
        // Настройки кэширования
        webSettings.setCacheMode(WebSettings.LOAD_DEFAULT);
        
        // Настраиваем WebViewClient
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(android.webkit.WebView view, String url) {
                super.onPageFinished(view, url);
                // Страница загружена успешно
                String lastFile = prefs.getString(LAST_FILE_KEY, "");
                if (!lastFile.isEmpty()) {
                    // Открываем последний файл через JavaScript
                    webView.evaluateJavascript(
                        "if(typeof switchToFile === 'function') { switchToFile('" + lastFile + "'); }",
                        null
                    );
                }
            }
            
            @Override
            @TargetApi(Build.VERSION_CODES.M)
            public void onReceivedError(android.webkit.WebView view, WebResourceRequest request, WebResourceError error) {
                super.onReceivedError(view, request, error);
                if (request.isForMainFrame()) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        String errorMessage = "Error: " + error.getDescription();
                        Toast.makeText(MainActivity.this, errorMessage, Toast.LENGTH_SHORT).show();
                    }
                }
            }
            
            @Override
            public boolean shouldOverrideUrlLoading(android.webkit.WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                if (uri.getScheme().equals("file")) {
                    return false; // Позволяем WebView обрабатывать локальные файлы
                }
                return super.shouldOverrideUrlLoading(view, request);
            }
        });
        
        // Chrome client для диалогов
        webView.setWebChromeClient(new WebChromeClient());
        
        // Загружаем приложение
        webView.loadUrl("file:///android_asset/index.html");
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
    
    @Override
    protected void onPause() {
        super.onPause();
        webView.onPause();
        
        // Сохраняем текущий открытый файл
        webView.evaluateJavascript(
            "if(typeof getCurrentFileName === 'function') { getCurrentFileName(); } else { '' }",
            value -> {
                String fileName = value;
                if (fileName != null && !fileName.equals("null") && !fileName.isEmpty()) {
                    prefs.edit().putString(LAST_FILE_KEY, fileName).apply();
                }
            }
        );
    }
    
    @Override
    protected void onResume() {
        super.onResume();
        webView.onResume();
    }
    
    @Override
    protected void onDestroy() {
        webView.destroy();
        super.onDestroy();
    }
}
