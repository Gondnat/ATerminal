//
//  CopyrightViewController.swift
//  ATerminal
//
//  Created by Daniel Tan on 30/06/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit

class CopyrightViewController: UIViewController {

    var copyright:String!

    @IBOutlet private weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.dataDetectorTypes = .link
        let offset = textView.contentOffset
        textView.text = copyright
        OperationQueue.main .addOperation {
            self.textView.contentOffset = offset;
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
