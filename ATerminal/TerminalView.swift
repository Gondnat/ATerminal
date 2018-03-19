//
//  TerminalView.swift
//  ATerminal
//
//  Created by Gondnat on 19/03/2018.
//  Copyright © 2018 Thnuth. All rights reserved.
//

import UIKit

class TerminalView: UITextView {

    override func becomeFirstResponder() -> Bool {
        return false
    }
    override var canBecomeFirstResponder: Bool {
        return false
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
