//
//  HostTableViewController.swift
//  ATermial
//
//  Created by Daniel Tan on 11/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit

struct SSHServer {
    var host:String!
    var user:String!
    var passwd:String!
    var alias:String?

}

class HostTableViewController:  UITableViewController, UIViewControllerTransitioningDelegate {
    
    
    lazy var sshServers = [SSHServer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        sshServers.append(SSHServer(host: "192.168.2.4", user: "odie", passwd: "d", alias: "odiecloud"))
        NotificationCenter.default.addObserver(self, selector: #selector(addNewSSHServer(_:)), name: .AddNewServer, object: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }

    // MARK: Notification method
    @objc func addNewSSHServer(_ notification:Notification) {
        if let newServer = notification.object as? SSHServer {
            if !newServer.host.isEmpty {
                sshServers.append(newServer)
                tableView.reloadData()
            }
        }
    }

    // MARK: IBAction

    @IBAction func quickConnect(_ sender: UIBarButtonItem) {
        let hostAddress = UIAlertController(title: "Connect to SSH", message: "Please input host address and port", preferredStyle: UIAlertControllerStyle.alert)
        hostAddress.addTextField { (address:UITextField) in
            address.resignFirstResponder()
            address.keyboardType = .numbersAndPunctuation
            address.placeholder =  "example: 192.168.0.1:22"
            address.returnKeyType = .next
        }
        hostAddress.addTextField { (user:UITextField) in
            user.returnKeyType = .next
            user.keyboardType = .asciiCapable
            user.placeholder = "User name"
        }
        hostAddress.addTextField { (passwd:UITextField) in
            passwd.returnKeyType = .go
            passwd.keyboardType = .asciiCapable
            passwd.placeholder = "Password"
        }
        let connect = UIAlertAction(title: "Connect", style: UIAlertActionStyle.default) { (UIAlertAction) in
            if let textFields = hostAddress.textFields {

                self.showSSHView(host: textFields[0].text!, username: textFields[1].text!, passwd: textFields[2].text!)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (UIAlertAction) in
        }
        hostAddress.addAction(connect)
        hostAddress.addAction(cancel)
        self.present(hostAddress, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }

    // MARK: tableview datasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sshServers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hostCell")
        if nil != cell {
            if indexPath.row < sshServers.count {
                let host = sshServers[indexPath.row]
                if !(host.alias?.isEmpty)!{
                    cell?.textLabel?.text = host.alias
                } else {
                    cell?.textLabel?.text = String(format: "%@@%@", host.user, host.host)
                }
            }
        }
        return cell!
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            sshServers.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
        case .insert: break
        default: break
        }
    }

    // MARK: tableview delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < sshServers.count {
            let sshServer = sshServers[indexPath.row]
            showSSHView(host: sshServer.host, username: sshServer.user, passwd: sshServer.passwd)
        }
    }



    // MARK: show terminal view
    func showSSHView(host:String, username:String, passwd:String) {
        if let SSHVC = self.storyboard?.instantiateViewController(withIdentifier: "SSHView") as? SSHViewController {
            SSHVC.host = host
            SSHVC.user = username
            SSHVC.passwd = passwd
            self.tableView.reloadData()
            self.navigationController?.pushViewController(SSHVC, animated: true)
        }
    }
}
