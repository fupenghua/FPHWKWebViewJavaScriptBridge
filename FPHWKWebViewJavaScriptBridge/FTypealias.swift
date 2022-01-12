//
//  FTypeAlias.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by penghua fu on 2022/1/12.
//

import Foundation

public typealias JSMessage = [String: Any]

public typealias JSBridgeResponseCallBack = (Any?) -> Void

public typealias JSBridgeHandler = (JSMessage?, JSBridgeResponseCallBack?) -> Void
