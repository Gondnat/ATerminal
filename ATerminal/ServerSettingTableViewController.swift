//
//  AddHostViewController.swift
//  ATerminal
//
//  Created by Daniel Tan on 16/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit
import CoreData

class ServerSettingTableViewController: UITableViewController, UITextFieldDelegate{

    weak var server:Server?
    @IBOutlet weak var saveButton: UIBarButtonItem!

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!


//    var tableLabelList: [CELLTYPE] {
//        return [.name, .IP, .user, .passwd]
//    }

    func setStatusBarColor(color:UIColor) {
        if let statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView {
            statusBar.backgroundColor = color
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        saveButton.isEnabled = false
        nameTextField.delegate = self
        ipTextField.delegate = self
        userNameTextField.delegate = self
        passwordTextField.delegate = self
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let serverInfo = server {
            ipTextField.text = serverInfo.hostname
            nameTextField.text = serverInfo.name
            userNameTextField.text = serverInfo.username
            passwordTextField.text = serverInfo.password

        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: Any) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        var newServer = server
        if nil == server {
            newServer = NSEntityDescription.insertNewObject(forEntityName: "Server", into: context) as? Server
            newServer?.addtime = Int64(time(nil))
        }
        newServer?.name = nameTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        newServer?.hostname = ipTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        newServer?.username = userNameTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        newServer?.password = passwordTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        do {
            try context.save()
        } catch {
            fatalError("Failure to save context:\(error)")
        }
        self.dismiss(animated: true, completion: nil)
    }

//    override var prefersStatusBarHidden: Bool {
//        return true
//    }

    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let textInNS = textField.text! as NSString
        let newString = textInNS.replacingCharacters(in: range, with: string)
//        let pattern = "(\\d+.){1,3}\\d+"
//        do {
//            let regualrExpression = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
//            let numberOfMatch = regualrExpression.numberOfMatches(in: newString, options: .anchored, range: NSRange(location: 0, length: (newString as NSString).length) )
//            if 0 == numberOfMatch {
//                return false
//            }
//        } catch {
//
//        }
        saveButton.isEnabled = !(newString.isEmpty)
        return true
    }

}
