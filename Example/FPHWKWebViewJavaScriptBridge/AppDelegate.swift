//
//  AppDelegate.swift
//  FPHWKWebViewJavaScriptBridge
//
//  Created by 付朋华 on 2020/7/30.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let rootViewController = UINavigationController(rootViewController: ViewController())
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.white
        self.window?.rootViewController = rootViewController
        self.window?.makeKeyAndVisible()
        if #available(iOS 13.0, *) {
            self.window?.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
        }
        return true
    }



}

