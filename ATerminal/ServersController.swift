//
//  ServersController.swift
//  ATerminal
//
//  Created by Daniel Tan on 06/07/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit
import CoreData

class ServersController: NSObject {
    static open let persistentContainer: NSPersistentContainer = {
        return (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        }()!
}
