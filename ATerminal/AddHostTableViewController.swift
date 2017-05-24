//
//  AddHostViewController.swift
//  ATerminal
//
//  Created by Daniel Tan on 16/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit

enum CELLTYPE:Int {
    case name = 0
    case IP, user, passwd

    func labelText() -> String {
        switch self {
        case .name:
            return "Name"
        case .IP:
            return "IP Address"
        case .user:
            return "User Name"
        case .passwd:
            return "Password"
        }
    }
    func keyboardType() ->  UIKeyboardType{
        switch self {
        case .name:
            return .asciiCapable
        case .IP:
            return .numbersAndPunctuation
        case .user:
            return .alphabet
        case .passwd:
            return .alphabet
        }
    }
    func returnKeyType() -> UIReturnKeyType {
        switch self {
        case .name, .IP, .user:
            return .next
        case .passwd:
            return .done
        }
    }
    func placeholder() -> String {
        switch self {
        case .name:
            return "Alias"
        case .IP:
            return "EXP: 192.168.1.1:22"
        case .user:
            return "Login user name"
        case .passwd:
            return ""
        }
    }

}

extension Notification.Name {
    public static let AddNewServer = NSNotification.Name("com.thnuth.hostTableViewController.addNewServer")

}

class AddHostTableViewController: UITableViewController{


    var tableLabelList: [CELLTYPE] {
        return [.name, .IP, .user, .passwd]
    }
    
    func setStatusBarColor(color:UIColor) {
        if let statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView {
            statusBar.backgroundColor = color
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()

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
        var newServerInfo = SSHServer()
        for var i in 0..<tableLabelList.count {
            if let cell = self.tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? LabelAndTextTableViewCell {
                if let cellType = CELLTYPE(rawValue: cell.tag) {
                    switch cellType {
                    case CELLTYPE.name:
                        newServerInfo.alias = cell.textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    case CELLTYPE.IP:
                        newServerInfo.host = cell.textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    case CELLTYPE.user:
                        newServerInfo.user = cell.textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    case CELLTYPE.passwd:
                        newServerInfo.passwd = cell.textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                }
            }
        }
        NotificationCenter.default.post(name: .AddNewServer, object: newServerInfo)
        self.dismiss(animated: true, completion: nil)
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
        let cellInfo = tableLabelList[indexPath.row]
        cell?.tag = cellInfo.rawValue
        cell?.label.text = cellInfo.labelText()
        cell?.textField.keyboardType = cellInfo.keyboardType()
        cell?.textField.returnKeyType = cellInfo.returnKeyType()
        cell?.textField.placeholder = cellInfo.placeholder()
        cell?.selectionStyle = .none
        return cell!
    }
}
