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
    private static final String HOME = "https://otkat628.github.io/otkat-games/apps/index.html";
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
                injectMobileControls(view, url);
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

    private void injectMobileControls(WebView view, String url) {
        if (!url.contains("/prototype-3d/")) return;
        String js = "(function(){if(document.getElementById('otkat-touch-pad'))return;" +
            "var style=document.createElement('style');style.textContent='#otkat-touch-pad{position:fixed;z-index:999999;left:10px;right:10px;bottom:12px;display:flex;justify-content:space-between;align-items:end;pointer-events:none;font:700 13px system-ui}#otkat-touch-pad .cluster{display:grid;grid-template-columns:repeat(3,48px);gap:5px;pointer-events:auto}#otkat-touch-pad button{height:46px;border:1px solid #f4e34b99;border-radius:12px;background:#101827dd;color:#f4e34b;font-weight:900;touch-action:none;user-select:none}#otkat-touch-pad .actions{display:flex;gap:6px;pointer-events:auto}#otkat-touch-pad .actions button{min-width:50px}';document.head.appendChild(style);" +
            "var pad=document.createElement('div');pad.id='otkat-touch-pad';pad.innerHTML='<div class=cluster><span></span><button data-k=w>▲</button><span></span><button data-k=a>◀</button><button data-k=s>▼</button><button data-k=d>▶</button></div><div class=actions><button data-k=' '>ПРЫЖОК</button><button data-k=e>ДЕЙСТВИЕ</button><button data-k=q>СКРЫТЬСЯ</button></div>';document.body.appendChild(pad);" +
            "pad.querySelectorAll('button').forEach(function(b){var key=b.getAttribute('data-k');function down(e){e.preventDefault();b.style.background='#7b6a18';window.dispatchEvent(new KeyboardEvent('keydown',{key:key===' '?' ':key,bubbles:true}));}function up(e){e.preventDefault();b.style.background='#101827dd';window.dispatchEvent(new KeyboardEvent('keyup',{key:key===' '?' ':key,bubbles:true}));}b.addEventListener('pointerdown',down);b.addEventListener('pointerup',up);b.addEventListener('pointercancel',up);b.addEventListener('contextmenu',function(e){e.preventDefault()})});})();";
        view.evaluateJavascript(js, null);
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
