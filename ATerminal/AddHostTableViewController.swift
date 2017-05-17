//
//  AddHostViewController.swift
//  ATerminal
//
//  Created by Daniel Tan on 16/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit

class AddHostTableViewController: UITableViewController{
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    var tableLabelList: [String] {
        return ["Name","IP Address", "Port", "User", "Password"]
    }
    
    func setStatusBarColor(color:UIColor) {
        if let statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView {
            statusBar.backgroundColor = color
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        setStatusBarColor(color: navigationBar.barTintColor!)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: Any) {
    }
//    override var prefersStatusBarHidden: Bool {
//        return true
//    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - tableView DataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableLabelList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "labelAndText") as? LabelAndTextTableViewCell
        if nil == cell {
            cell = LabelAndTextTableViewCell()
        }
        cell?.label.text = tableLabelList[indexPath.row]
        return cell!
    }
}
