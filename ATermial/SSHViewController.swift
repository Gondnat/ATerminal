//
//  ViewController.swift
//  ATermial
//
//  Created by Daniel Tan on 10/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit
import NMSSH

class SSHViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let session = NMSSHSession.connect(toHost: "192.168.2.4", withUsername: "odie") {
        if session.isConnected {
            if session.authenticate(byPassword: "d") {
                do {
                    let response = try session.channel.execute("ls -al")
                    print(response)

                } catch  {
                    print(error)
                }
            }
        }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

