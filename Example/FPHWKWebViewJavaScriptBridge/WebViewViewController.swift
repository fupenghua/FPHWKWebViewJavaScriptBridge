//
//  WebViewViewController.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by 付朋华 on 2020/7/30.
//

import UIKit
import WebKit

class WebViewViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    var webView = FPHWKWebView.webView()
    
    deinit {
        print("controller deinit")
        self.webView.scrollView.delegate = nil
        self.webView.uiDelegate = nil
        self.webView.navigationDelegate = nil;
        self.webView.removeFromSuperview()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _configWebView()
        loadRequestHandler()
        self.title = "webView"
        // Do any additional setup after loading the view.
    }
    func loadRequestHandler() {
        let url = URL.init(string: "http://10.21.48.50:9527")
        let request = URLRequest(url: url!)
        _ = self.webView.load(request)
    }
    
    fileprivate func _configWebView() {
        self.webView.clipsToBounds = false
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        self.view.addSubview(self.webView)
        self.webView.frame = self.view.bounds
        self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }


}
