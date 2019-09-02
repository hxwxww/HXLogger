//
//  AppDelegate.swift
//  HXLogDemo
//
//  Created by HongXiangWen on 2019/8/23.
//  Copyright © 2019 WHX. All rights reserved.
//

import UIKit
import HXLog

let logger = HXLogger.shared

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        logger.format = .all
        return true
    }

}

