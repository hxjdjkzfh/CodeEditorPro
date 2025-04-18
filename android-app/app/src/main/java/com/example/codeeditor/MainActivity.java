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
import androidx.webkit.WebSettingsCompat;
import androidx.webkit.WebViewFeature;

public class MainActivity extends Activity {
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Set fullscreen
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        );
        
        setContentView(R.layout.activity_main);

        // Initialize WebView
        webView = findViewById(R.id.webview);
        WebSettings webSettings = webView.getSettings();
        
        // Enable JavaScript and DOM storage
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        
        // Modern caching mode
        webSettings.setCacheMode(WebSettings.LOAD_DEFAULT);
        
        // Enable modern web features if available
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            webSettings.setSafeBrowsingEnabled(true);
        }
        
        // Dark mode support if available
        if (WebViewFeature.isFeatureSupported(WebViewFeature.FORCE_DARK)) {
            WebSettingsCompat.setForceDark(webSettings, WebSettingsCompat.FORCE_DARK_ON);
        }
        
        // Enhanced webview client with error handling
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(android.webkit.WebView view, String url) {
                super.onPageFinished(view, url);
                // Page loaded successfully
            }
            
            @Override
            @TargetApi(Build.VERSION_CODES.M)
            public void onReceivedError(android.webkit.WebView view, WebResourceRequest request, WebResourceError error) {
                super.onReceivedError(view, request, error);
                if (request.isForMainFrame()) {
                    // Handle main frame errors
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        // Modern error reporting
                        String errorMessage = "Error: " + error.getDescription();
                        Toast.makeText(MainActivity.this, errorMessage, Toast.LENGTH_SHORT).show();
                    }
                }
            }
            
            @Override
            public boolean shouldOverrideUrlLoading(android.webkit.WebView view, WebResourceRequest request) {
                // Handle local file links internally
                Uri uri = request.getUrl();
                if (uri.getScheme().equals("file")) {
                    return false; // Let WebView handle local files
                }
                return super.shouldOverrideUrlLoading(view, request);
            }
        });
        
        // Chrome client for JavaScript dialogs and features
        webView.setWebChromeClient(new WebChromeClient());
        
        // Load the app
        webView.loadUrl("file:///android_asset/index.html");
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                this.getOnBackInvokedDispatcher().registerOnBackInvokedCallback(0, () -> {
                    finish();
                });
            } else {
                super.onBackPressed();
            }
        }
    }
    
    @Override
    protected void onPause() {
        super.onPause();
        webView.onPause();
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