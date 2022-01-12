//
//  File.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by 付朋华 on 2020/7/30.
//

import UIKit
import WebKit
import Foundation

class JSBridgeManager {
    deinit {
        print("bridgeManager deinit")
    }
    init() {
        config()
    }
    
    fileprivate lazy var bridge: FWKWebViewJSBridge = {
        let bridge = FWKWebViewJSBridge()
        return bridge
    }()
    private weak var _currentController: UIViewController?
    private func config() {
        registerJavaScriptBridge()
    }
    
    private func addNotificationCenter() {
        
    }
    
    private func registerJavaScriptBridge() {
        self.registerShare()
    }
    
    
    //MARK:---public method
    
    open func setWebView(_ webView: WKWebView) {
        self.bridge.setWebView(webView)
    }
    
    /// 设置当前webview所有者
    /// - Parameter controller: 当前控制器
    func setHolderController(_ controller: UIViewController?) {
        _currentController = controller
    }
    
    /// native 调用 H5
    /// - Parameters:
    ///   - name: 方法名
    ///   - data: 参数
    func callHandler(name: String, data: Any?) {
        self.bridge.callHandler(name: name, data: data)
    }
}

extension JSBridgeManager {
    fileprivate func registerShare() {
        self.bridge.registerHandler(name: "share") { (data, callback) in
            
        }
    }
}
