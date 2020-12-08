//
//  FPHWKWebViewJSBridge.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by 付朋华 on 2020/7/30.
//
import UIKit
import WebKit
import Foundation

fileprivate let scriptMessageName = "Bridge"
fileprivate let bridgeLoaded = "bridgeLoaded"

public typealias jsMessage = Dictionary<String, Any?>

public typealias JSBridgeResponseCallBack = (Any?) -> Void

public typealias JSBridgeHandler = (jsMessage?, JSBridgeResponseCallBack?) -> Void

public class WKWebViewJSBridge: NSObject, WKScriptMessageHandler {
        
    private(set) lazy var webConfig: WKWebViewConfiguration? = WKWebViewConfiguration()
    fileprivate var userController: WKUserContentController? = WKUserContentController()
    
    /// message 队列
    fileprivate var startupMessageQueue: Array<jsMessage>?
    
    fileprivate var messageHandlers: Dictionary<String, JSBridgeHandler?>?
    
    fileprivate lazy var responseCallbacks: Dictionary<String, Any?>? = Dictionary()
    
    fileprivate var _uniqueId = 0
    
    fileprivate weak var webView: WKWebView?
    deinit {
        messageHandlers = nil
        responseCallbacks = nil
        startupMessageQueue = nil
        webConfig = nil
        userController?.removeScriptMessageHandler(forName: scriptMessageName)
        userController = nil
    }
    override init() {
        super.init()
        self.initConfig()
    }
    
    fileprivate func initConfig() {
        startupMessageQueue = Array()
        userController?.add(self, name: scriptMessageName)
        webConfig?.userContentController = self.userController!
        if messageHandlers == nil {
            messageHandlers = Dictionary()
            let bridgeLoadedHandler: JSBridgeHandler = {
                (data, response) in
                self.dealWithMessageQuene()
            }
            messageHandlers![bridgeLoaded] = bridgeLoadedHandler
        }
    }
    
    //MARK:---open method
    
    public func setWebView(_ webView: WKWebView) {
        self.webView = webView
    }
    
    public func registerHandler(name: String, handler: JSBridgeHandler?) {
        self.messageHandlers?[name] = handler
    }
    
    public func removeHandler(name: String) {
        self.messageHandlers?.removeValue(forKey: name)
    }
    
    public func callHandler(name: String) {
        callHandler(name: name, data: nil, responseCallback: nil)
    }
    
    public func callHandler(name: String, data: Any?) {
        callHandler(name: name, data: data, responseCallback: nil)
    }
    
    public func callHandler(name: String, data: Any?, responseCallback: JSBridgeResponseCallBack?) {
        sendData(name: name, data: data, responseCallback: responseCallback)
    }
    
    
    //MARK:---WKScriptMessageHandler delegate
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = message.name
        if messageName == scriptMessageName {
            var body:jsMessage
            if message.body is jsMessage {
                body = message.body as! jsMessage
            } else {
                body = self.objectFromJSONString(jsString: message.body as! String)
            }
            let responseId: String? = body["responseId"] as? String
            if responseId != nil {
                let responseData: Any? = body["responseData"] as Any?
                self.performCallback(responseId!, responseData)
            } else {
                performHanlder(body: body)
            }
            
        }
    }
    fileprivate func performCallback(_ responseId: String, _ responseData: Any?) {
        let handler: JSBridgeResponseCallBack? = self.responseCallbacks?[responseId] as? JSBridgeResponseCallBack
        handler?(responseData as Any?)
        self.responseCallbacks?.removeValue(forKey: responseId)
    }
    
    fileprivate func performHanlder(body: Dictionary<String, Any?>) {
        if let handlerName: String = body["handlerName"] as? String {
            let handler: JSBridgeHandler? = self.messageHandlers?[handlerName] as? JSBridgeHandler
            if handler != nil {
                let params: jsMessage? = body["data"] as? jsMessage
                var responseCallback: JSBridgeResponseCallBack = {
                    responseData in
                }
                
                if let callbackId: String = body["callbackId"] as? String {
                    responseCallback = { responseData in
                        let message = [
                            "responseId": callbackId,
                            "responseData":responseData
                        ]
                        self.queueMessage(message: message)
                    }
                }
                handler!(params, responseCallback)
            }
        }
        
    }
}

extension WKWebViewJSBridge {
    
    //MARK:---private method
    fileprivate func dealWithMessageQuene() {
        let js = handlerJs()
        evaluateJavascript(javascriptCommand: js)
        if self.startupMessageQueue != nil {
            let queue = self.startupMessageQueue
            self.startupMessageQueue = nil
            for message in queue! {
                _dispatchMessage(message: message)
            }
        }
    }
    
    fileprivate func sendData(name: String, data: Any?, responseCallback: JSBridgeResponseCallBack?) {
        var message = Dictionary<String, Any?>()
        message["handlerName"] = name
        message["data"] = data
        if responseCallback != nil {
            _uniqueId = _uniqueId + 1
            let callbackId = "objc_cb_\(_uniqueId)"
            self.responseCallbacks?[callbackId] = responseCallback
            message["callbackId"] = callbackId
        }
        queueMessage(message: message)
    }
    
    fileprivate func queueMessage(message: Dictionary<String, Any?>) {
        if self.startupMessageQueue != nil {
            self.startupMessageQueue?.append(message)
        } else {
            _dispatchMessage(message: message)
        }
    }
    
    fileprivate func _dispatchMessage(message: Dictionary<String, Any?>) {
        var messageJson = serializeMessage(message: message)
        messageJson = messageJson.replacingOccurrences(of: "\\u0000", with: "")
        messageJson = messageJson.replacingOccurrences(of: "\\", with: "\\\\")
        messageJson = messageJson.replacingOccurrences(of: "\"", with: "\\\"")
        messageJson = messageJson.replacingOccurrences(of: "\'", with: "\\\'")
        messageJson = messageJson.replacingOccurrences(of: "\n", with: "\\n")
        messageJson = messageJson.replacingOccurrences(of: "\r", with: "\\r")
        let javascriptCommand = "WebViewJavascriptBridge._handleMessageFromNative('\(messageJson)';"
        if Thread.current.isMainThread {
            evaluateJavascript(javascriptCommand: javascriptCommand)
        } else {
            DispatchQueue.main.async {
                self.evaluateJavascript(javascriptCommand: javascriptCommand)
            }
        }
    }
    
    fileprivate func evaluateJavascript(javascriptCommand: String) {
        webView?.evaluateJavaScript(javascriptCommand, completionHandler: nil)
    }
}

extension WKWebViewJSBridge {
    fileprivate func serializeMessage(message: jsMessage) -> String {
        var data: Data
            
            do {
                try data = JSONSerialization.data(withJSONObject: message, options: .fragmentsAllowed)
            } catch  {
                return ""
            }
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    fileprivate func handlerJs() -> String {
        let bundle = Bundle.main
        let curBundleDirectory = "JSBridge.bundle"
        let path = bundle.path(forResource: "WebViewJavaScriptBridge", ofType: "js", inDirectory: curBundleDirectory)
        var handlerJS: String = ""
        do {
            try handlerJS = String(contentsOfFile: path!, encoding: .utf8)
        } catch {
            
        }
        handlerJS = handlerJS.replacingOccurrences(of: "\n", with: "")
        return handlerJS
    }
    fileprivate func objectFromJSONString(jsString: String) -> Dictionary<String, Any?> {
        var obj = Dictionary<String, Any?>()
        
        do {
            try obj = JSONSerialization.jsonObject(with: jsString.data(using: .utf8)!, options: .mutableContainers) as! Dictionary<String, Any?>
        } catch  {
    
        }
        return obj
    }
}
