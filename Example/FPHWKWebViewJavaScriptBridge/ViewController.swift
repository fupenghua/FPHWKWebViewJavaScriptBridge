//
//  ViewController.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by 付朋华 on 2020/7/30.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "JSBridge"
        addButton()
        setWebViewUserAgent() 
        // Do any additional setup after loading the view.
    }
    func setWebViewUserAgent() {
        var webView: FPHWKWebView? = FPHWKWebView.webView()
        webView!.evaluateJavaScript("navigator.userAgent") { (result, error) in
            let newAgent = "\(result ?? "") BEAST/4.22.0 Resolution/1242x2208"
            let agentDic = ["UserAgent": newAgent]
            UserDefaults.standard.register(defaults: agentDic)
            webView = nil
        }
    }
    func addButton() {
        let btn = UIButton(type: .custom)
        self.view.addSubview(btn)
        btn.frame = CGRect(x: 20, y: 100, width: 100, height: 100)
        btn.setTitle("webview", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.addTarget(self, action: #selector(click), for: .touchUpInside)
    }
    
    @objc func click() {
        let vc = WebViewViewController()
        self.navigationController?.pushViewController(vc, animated: false)
        
    }

}

