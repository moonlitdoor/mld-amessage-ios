//
//  ViewController.swift
//  amessage
//
//  Created by Brian Amesbury on 7/17/19.
//  Copyright © 2019 Moonlit Door. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var build: UILabel!
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func showBuildInfo(_ sender: Any) {
        button.isEnabled = false
        version.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        build.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}

