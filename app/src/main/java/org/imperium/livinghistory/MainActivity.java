package org.imperium.livinghistory;
import android.app.Activity; import android.os.Bundle; import android.webkit.*;
public class MainActivity extends Activity { WebView w; public void onCreate(Bundle b){super.onCreate(b);w=new WebView(this);WebSettings s=w.getSettings();s.setJavaScriptEnabled(true);s.setDomStorageEnabled(true);w.setWebViewClient(new WebViewClient());w.setWebChromeClient(new WebChromeClient());setContentView(w);w.loadUrl("file:///android_asset/index.html");} public void onBackPressed(){if(w!=null&&w.canGoBack())w.goBack();else super.onBackPressed();}}
