//
//  SafariExtensionViewController.swift
//  Hacker Smacker Extension
//
//  Created by Samuel Clay on 4/1/20.
//  Copyright © 2020 hackersmacker. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:320, height:240)
        return shared
    }()

}
