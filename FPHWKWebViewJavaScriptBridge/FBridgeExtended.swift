//
//  FBridgeExtended.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by 付朋华 on 2020/12/21.
//

import Foundation

public struct FBridgeExtension<ExtendedType> {
    public private(set) var type: ExtendedType
    
    fileprivate init(_ type: ExtendedType) {
        self.type = type
    }
}

public protocol FBridgeExtended {
    associatedtype ExtendedType
        
    var bridge: FBridgeExtension<ExtendedType> { get set }
    
}

extension FBridgeExtended {
    
    public var bridge: FBridgeExtension<Self> {
        get { FBridgeExtension(self) }
        set {}
    }
}

