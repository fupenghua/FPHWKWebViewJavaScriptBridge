//
//  FPHWKWebViewJSBridge.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by 付朋华 on 2020/7/30.
//
import UIKit
import WebKit
import Foundation

fileprivate let bridgeLoaded = "bridgeLoaded"

public class WKWebViewJSBridge: NSObject, WKScriptMessageHandler {
        
    /// message 队列
    fileprivate var startupMessageQueue: [JSMessage]? = [JSMessage]()
    
    fileprivate lazy var messageHandlers: [String: JSBridgeHandler] = {
        var handlers = [String: JSBridgeHandler]()
        let bridgeLoadedHandler: JSBridgeHandler = { [weak self]
            (data, response) in
            self?.registerJavaScript()
            self?.sendMessageQueue()
        }
        handlers[bridgeLoaded] = bridgeLoadedHandler
        return handlers
    }()
    
    fileprivate lazy var responseCallbacks = [String: JSBridgeResponseCallBack]()
    
    fileprivate var _uniqueId = 0
    
    fileprivate weak var webView: WKWebView?
    deinit {
        startupMessageQueue = nil
    }
    
    //MARK:---open method
    
    open func setWebView(_ webView: WKWebView) {
        self.webView = webView
        webView.bridge.addMessageHandler(self)
    }
    
    open func registerHandler(name: String, handler: JSBridgeHandler?) {
        if let handler = handler {
            self.messageHandlers[name] = handler
        }
    }
    
    open func removeHandler(name: String) {
        self.messageHandlers.removeValue(forKey: name)
    }
    
    open func callHandler(name: String,
                          data: Any? = nil,
                          responseCallback: JSBridgeResponseCallBack? = nil) {
        sendData(name: name, data: data, responseCallback: responseCallback)
    }
    
    
    //MARK:---WKScriptMessageHandler delegate
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = message.name
        if messageName == scriptMessageName {
            var body: JSMessage?
            if let b = message.body as? JSMessage  {
                body = b
            } else if let str = message.body as? String {
                body = self.message(from: str)
            }
            
            guard let body = body else { return }
            if let responseId = body["responseId"] as? String {
                let responseData = body["responseData"]
                bridgeCallback(responseId, responseData)
            } else {
                performHanlder(body: body)
            }
            
        }
    }
    fileprivate func bridgeCallback(_ responseId: String, _ responseData: Any?) {
        if let handler = self.responseCallbacks[responseId] {
            handler(responseData)
            self.responseCallbacks.removeValue(forKey: responseId)
        }
    }
    
    fileprivate func performHanlder(body: JSMessage) {
        if let handlerName = body["handlerName"] as? String {
            if let handler = self.messageHandlers[handlerName] {
                let params: JSMessage? = body["data"] as? JSMessage
                var responseCallback: JSBridgeResponseCallBack?
                if let callbackId: String = body["callbackId"] as? String {
                    responseCallback = {[weak self] responseData in
                        var message: JSMessage = ["responseId": callbackId]
                        if let responseData = responseData {
                            message.updateValue(responseData, forKey: "responseData")
                        }
                        self?.queueMessage(message)
                    }
                }
                handler(params, responseCallback)
            }
        }
        
    }
}

fileprivate extension WKWebViewJSBridge {
    func sendMessageQueue() {
        if let queue = startupMessageQueue {
            startupMessageQueue = nil
            queue.forEach{ sendJavaScriptCommand($0) }
        }
    }
    
    func sendData(name: String, data: Any?, responseCallback: JSBridgeResponseCallBack?) {
        var message = JSMessage()
        message["handlerName"] = name
        message["data"] = data
        if let responseCallback = responseCallback {
            _uniqueId = _uniqueId + 1
            let callbackId = "objc_cb_\(_uniqueId)"
            self.responseCallbacks[callbackId] = responseCallback
            message["callbackId"] = callbackId
        }
        queueMessage(message)
    }
    
    func queueMessage(_ message: JSMessage) {
        if startupMessageQueue != nil {
            startupMessageQueue!.append(message)
        } else {
            sendJavaScriptCommand(message)
        }
    }
}

extension WKWebViewJSBridge: FJavaScriptMessageDispatch {
    func evaluateJavascript(_ javascriptCommand: String) {
        webView?.evaluateJavaScript(javascriptCommand, completionHandler: nil)
    }
}

