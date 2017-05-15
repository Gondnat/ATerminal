//
//  SideMenu.swift
//  ATerminal
//
//  Created by Daniel Tan on 15/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit
import SideMenu

class MenuViewController: UIViewController, Menu {
    @IBOutlet var menuItems = [UIView]()
    @IBOutlet var exit:UIView!
    @IBOutlet var copyRight:UIView!
    @IBOutlet var host:UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 100, height: 0)
        menuItems.append(exit)
        menuItems.append(copyRight)
        menuItems.append(host)
    }
}
