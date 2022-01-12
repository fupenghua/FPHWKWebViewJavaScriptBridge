//
//  FJavaScriptMessageDispatch.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by penghua fu on 2022/1/12.
//

import Foundation

protocol FJavaScriptMessageDispatch {
    func evaluateJavascript(_ javascriptCommand: String)
}

extension FJavaScriptMessageDispatch where Self: WKWebViewJSBridge {
    func sendJavaScriptCommand(_ message: JSMessage) {
        var messageJson = serializeMessage(message: message)
        messageJson = messageJson.replacingOccurrences(of: "\\u0000", with: "")
        messageJson = messageJson.replacingOccurrences(of: "\\", with: "\\\\")
        messageJson = messageJson.replacingOccurrences(of: "\"", with: "\\\"")
        messageJson = messageJson.replacingOccurrences(of: "\'", with: "\\\'")
        messageJson = messageJson.replacingOccurrences(of: "\n", with: "\\n")
        messageJson = messageJson.replacingOccurrences(of: "\r", with: "\\r")
        let javascriptCommand = "WebViewJavascriptBridge._handleMessageFromNative(\"\(messageJson)\");"
        if Thread.current.isMainThread {
            evaluateJavascript(javascriptCommand)
        } else {
            DispatchQueue.main.async { self.evaluateJavascript(javascriptCommand) }
        }
    }
    
    func registerJavaScript() {
        let bundle = Bundle(for: Self.self)
        let curBundleDirectory = "JSBridge.bundle"
        let path = bundle.path(forResource: "WebViewJavaScriptBridge", ofType: "js", inDirectory: curBundleDirectory)
        var handlerJS: String = ""
        do {
            try handlerJS = String(contentsOfFile: path!, encoding: .utf8)
        } catch {}
        handlerJS = handlerJS.replacingOccurrences(of: "\n", with: "")
        evaluateJavascript(handlerJS)
    }

    func message(from jsString: String) -> JSMessage {
        var obj: JSMessage
        do {
            try obj = JSONSerialization.jsonObject(with: jsString.data(using: .utf8)!, options: .mutableContainers) as! JSMessage
        } catch  {
            obj = JSMessage()
        }
        return obj
    }
    
    fileprivate func serializeMessage(message: JSMessage) -> String {
        let data = try? JSONSerialization.data(withJSONObject: message, options: [])
        let str = String(data: data!, encoding: String.Encoding.utf8)
        return str ?? ""
    }
}
