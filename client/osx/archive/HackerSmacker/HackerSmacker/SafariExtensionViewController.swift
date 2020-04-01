//
//  SafariExtensionViewController.swift
//  HackerSmacker
//
//  Created by Samuel Clay on 9/19/19.
//  Copyright © 2019 hackersmacker. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:320, height:240)
        return shared
    }()

}
