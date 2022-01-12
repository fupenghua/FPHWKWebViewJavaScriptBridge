//
//  WKWebviewExtension.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by penghua fu on 2022/1/12.
//

import Foundation
import WebKit
let scriptMessageName = "Bridge"

extension WKWebView: FBridgeExtended {}

extension FBridgeExtension where ExtendedType: WKWebView {
    
    public func removeMessageHandler() {
        self.type.configuration.userContentController.removeScriptMessageHandler(forName: scriptMessageName)
    }
    
    func addMessageHandler(_ handler: WKScriptMessageHandler) {
        self.type.configuration.userContentController.add(handler, name: scriptMessageName)
    }
}
