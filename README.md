# FPHWKWebViewJavaScriptBridge

[![CI Status](https://img.shields.io/travis/fupenghua/FPHWKWebViewJavaScriptBridge.svg?style=flat)](https://travis-ci.org/fupenghua/FPHWKWebViewJavaScriptBridge)
[![Version](https://img.shields.io/cocoapods/v/FPHWKWebViewJavaScriptBridge.svg?style=flat)](https://cocoapods.org/pods/FPHWKWebViewJavaScriptBridge)
[![License](https://img.shields.io/cocoapods/l/FPHWKWebViewJavaScriptBridge.svg?style=flat)](https://cocoapods.org/pods/FPHWKWebViewJavaScriptBridge)
[![Platform](https://img.shields.io/cocoapods/p/FPHWKWebViewJavaScriptBridge.svg?style=flat)](https://cocoapods.org/pods/FPHWKWebViewJavaScriptBridge)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

FPHWKWebViewJavaScriptBridge is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FPHWKWebViewJavaScriptBridge'
```

## Author

fupenghua, 390908980@qq.com

## License

### usage
`
 let bridge = WKWebViewJSBridge()
 bridge.setWebView(webView)
`
### register  js调用native
`
bridge.registerHandler(name: "funcName") { (data, callback) in 
    
}
`
### callHanlder native调用js

`
bridge.callHandler(name: "funcName", data: data)
`
在webView的deinit中一定要调用`self.bridge.removeMessageHandler()`，不然bridge会释放不掉

