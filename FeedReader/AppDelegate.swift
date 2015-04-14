//
//  AppDelegate.swift
//  FeedReader
//
//  Created by praveen on 4/13/15.
//  Copyright (c) 2015 NYU. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    // MARK: Properties
    
    let GlobalTintColor = UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)
    
    var window: UIWindow?
    
    // MARK: UIApplicationDelegate
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        HNManager.sharedManager().startSession()
        configureUI()
        return true
    }
    
    // MARK: Functions
    
    func configureUI() {
        window?.tintColor = GlobalTintColor
        UISwitch.appearance().onTintColor = window?.tintColor
    }


}

