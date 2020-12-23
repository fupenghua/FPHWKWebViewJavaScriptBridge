//
//  FPHWKWebView.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by 付朋华 on 2020/7/30.
//

import UIKit
import WebKit

class FPHWKWebView: WKWebView {
    private lazy var bridgeManager: JSBridgeManager = {
        let manager = JSBridgeManager()
        return manager
    }()
    
    private var _pageData: Any?
    
    deinit {
        self.bridge.removeMessageHandler()
        print("webView deinit")
    }
    
    class func webView(_ frame: CGRect = .zero) -> FPHWKWebView {
        return FPHWKWebView(frame: frame)
    }
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        configWebView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configWebView() {
        configuration.suppressesIncrementalRendering = true
        configuration.allowsInlineMediaPlayback = true
        configuration.processPool = WKProcessPool.shared
        if #available(iOS 10.0, *) {
            configuration.mediaTypesRequiringUserActionForPlayback = .all
        } else {
            configuration.requiresUserActionForMediaPlayback = false
        }
        configuration.processPool = WKProcessPool.shared
        bridgeManager.setWebView(self)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        backgroundColor = UIColor.white
        isOpaque = false
    }
    
    
    //MARK:---pageData
    func dataForPageData_CallHandler(_ data: Any?) {
        _pageData = data
    }
    
    func callHandler(name: String, data:Any?) {
        bridgeManager.callHandler(name: name, data: data)
    }
    
    //MARK:---重写 load
    
    override func load(_ request: URLRequest) -> WKNavigation? {
        if _pageData != nil {
            bridgeManager.callHandler(name: "pageData", data: _pageData)
        }
        print("load url: \(request.url!.absoluteString)")
        return super.load(request)
    }

    /// 设置当前webview所有者
    /// - Parameter controller: 当前控制器
    func setHolderController(_ controller: UIViewController?) {
        self.bridgeManager.setHolderController(controller)
    }

}

extension WKProcessPool {
    static let shared: WKProcessPool = WKProcessPool()
}
