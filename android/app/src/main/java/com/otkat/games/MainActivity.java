package com.otkat.games;

import android.app.Activity;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.graphics.Color;
import android.view.Gravity;

public class MainActivity extends Activity {
    private static final String HOME = "https://otkat628.github.io/otkat-games/games/index.html";
    private WebView web;
    private TextView status;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(Color.rgb(8, 9, 16));
        getWindow().setNavigationBarColor(Color.rgb(8, 9, 16));
        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.rgb(8, 9, 16));
        web = new WebView(this);
        web.setBackgroundColor(Color.rgb(8, 9, 16));
        web.getSettings().setJavaScriptEnabled(true);
        web.getSettings().setDomStorageEnabled(true);
        web.getSettings().setDatabaseEnabled(true);
        web.getSettings().setMediaPlaybackRequiresUserGesture(false);
        web.setWebChromeClient(new WebChromeClient());
        web.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                String url = request.getUrl().toString();
                return !(url.startsWith("https://otkat628.github.io/otkat-games/"));
            }
            @Override public void onPageFinished(WebView view, String url) {
                if (status != null) status.setVisibility(View.GONE);
            }
            @Override public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                if (request.isForMainFrame() && status != null) {
                    status.setText("Не удалось загрузить каталог. Проверь интернет и нажми здесь, чтобы повторить.");
                    status.setVisibility(View.VISIBLE);
                }
            }
        });
        root.addView(web, new FrameLayout.LayoutParams(-1, -1));
        status = new TextView(this);
        status.setText("Загрузка OTKAT Games…");
        status.setTextColor(Color.rgb(245, 226, 72));
        status.setTextSize(16);
        status.setGravity(Gravity.CENTER);
        status.setPadding(28, 28, 28, 28);
        status.setBackgroundColor(Color.rgb(8, 9, 16));
        status.setOnClickListener(v -> web.loadUrl(HOME));
        root.addView(status, new FrameLayout.LayoutParams(-1, -1));
        setContentView(root);
        if (state == null) web.loadUrl(HOME);
        else web.restoreState(state);
    }

    @Override protected void onSaveInstanceState(Bundle out) {
        if (web != null) web.saveState(out);
        super.onSaveInstanceState(out);
    }

    @Override public void onBackPressed() {
        if (web != null && web.canGoBack()) web.goBack();
        else super.onBackPressed();
    }

    @Override protected void onDestroy() {
        if (web != null) { web.destroy(); web = null; }
        super.onDestroy();
    }
}
