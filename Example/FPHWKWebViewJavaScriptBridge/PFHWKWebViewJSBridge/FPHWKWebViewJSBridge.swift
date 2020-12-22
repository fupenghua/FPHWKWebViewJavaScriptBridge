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

public typealias JSMessage = [String: Any]

public typealias JSBridgeResponseCallBack = (Any?) -> Void

public typealias JSBridgeHandler = (JSMessage?, JSBridgeResponseCallBack?) -> Void

extension WKWebView: FBridgeExtended {}
extension FBridgeExtension where ExtendedType: WKWebView {
    public func removeMessageHandler() {
        self.type.configuration.userContentController.removeScriptMessageHandler(forName: scriptMessageName)
    }
    func addMessageHandler(_ handler: WKScriptMessageHandler) {
        self.type.configuration.userContentController.add(handler, name: scriptMessageName)
    }
}

public class WKWebViewJSBridge: NSObject, WKScriptMessageHandler {
        
    /// message 队列
    fileprivate var startupMessageQueue: Array<JSMessage>?
    
    fileprivate lazy var messageHandlers:Dictionary<String, JSBridgeHandler?> = {
        var handlers = Dictionary<String, JSBridgeHandler?>()
        let bridgeLoadedHandler: JSBridgeHandler = { [weak self]
            (data, response) in
            self?.dealWithMessageQuene()
        }
        handlers[bridgeLoaded] = bridgeLoadedHandler
        return handlers
    }()
    
    fileprivate lazy var responseCallbacks = JSMessage()
    
    fileprivate var _uniqueId = 0
    
    fileprivate weak var webView: WKWebView?
    deinit {
        startupMessageQueue = nil
    }
    public override init() {
        super.init()
        self.initConfig()
    }

    
    fileprivate func initConfig() {
        startupMessageQueue = Array()
    }
    
    //MARK:---open method
    
    open func setWebView(_ webView: WKWebView) {
        self.webView = webView
        addScriptMessageHandler()
    }
    
    open func registerHandler(name: String, handler: JSBridgeHandler?) {
        self.messageHandlers[name] = handler
    }
    
    open func removeHandler(name: String) {
        self.messageHandlers.removeValue(forKey: name)
    }
    
    open func callHandler(name: String) {
        callHandler(name: name, data: nil, responseCallback: nil)
    }
    
    open func callHandler(name: String, data: Any?) {
        callHandler(name: name, data: data, responseCallback: nil)
    }
    
    open func callHandler(name: String, data: Any?, responseCallback: JSBridgeResponseCallBack?) {
        sendData(name: name, data: data, responseCallback: responseCallback)
    }
    
    
    //MARK:---WKScriptMessageHandler delegate
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = message.name
        if messageName == scriptMessageName {
            var body:JSMessage
            if message.body is JSMessage {
                body = message.body as! JSMessage
            } else {
                body = self.objectFromJSONString(jsString: message.body as! String) as JSMessage
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
        let handler: JSBridgeResponseCallBack? = self.responseCallbacks[responseId] as? JSBridgeResponseCallBack
        handler?(responseData as Any?)
        self.responseCallbacks.removeValue(forKey: responseId)
    }
    
    fileprivate func performHanlder(body: JSMessage) {
        if let handlerName = body["handlerName"] as? String {
            
            if let handler = self.messageHandlers[handlerName] {
                let params: JSMessage? = body["data"] as? JSMessage
                var responseCallback: JSBridgeResponseCallBack = {
                    responseData in
                }
                
                if let callbackId: String = body["callbackId"] as? String {
                    responseCallback = {[weak self] responseData in
                        let message = [
                            "responseId": callbackId,
                            "responseData":responseData
                        ]
                        self?.queueMessage(message: message as JSMessage)
                    }
                }
                handler!(params, responseCallback)
            }
        }
        
    }
}

extension WKWebViewJSBridge {
    
    fileprivate func addScriptMessageHandler() {
        self.webView?.bridge.addMessageHandler(self)
    }
    
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
        var message = JSMessage()
        message["handlerName"] = name
        message["data"] = data
        if responseCallback != nil {
            _uniqueId = _uniqueId + 1
            let callbackId = "objc_cb_\(_uniqueId)"
            self.responseCallbacks[callbackId] = responseCallback
            message["callbackId"] = callbackId
        }
        queueMessage(message: message)
    }
    
    fileprivate func queueMessage(message: JSMessage) {
        if self.startupMessageQueue != nil {
            self.startupMessageQueue?.append(message)
        } else {
            _dispatchMessage(message: message)
        }
    }
    
    fileprivate func _dispatchMessage(message: JSMessage) {
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
    fileprivate func serializeMessage(message: JSMessage) -> String {
        let data = try? JSONSerialization.data(withJSONObject: message, options: [])
        let str = String(data: data!, encoding: String.Encoding.utf8)
        return str ?? ""
    }
    
    fileprivate func handlerJs() -> String {
        let bundle = Bundle(for: Self.self)
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
    
    fileprivate func objectFromJSONString(jsString: String) -> JSMessage {
        
        let data = jsString.data(using: .utf8)
        if let dict = try? JSONSerialization.jsonObject(with: data!,
                                                        options: .mutableContainers) as? JSMessage {
            return dict
        }
        return JSMessage()
    }
}
