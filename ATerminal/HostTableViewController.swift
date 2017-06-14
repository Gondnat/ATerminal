//
//  HostTableViewController.swift
//  ATermial
//
//  Created by Daniel Tan on 11/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit
import CoreData

//struct SSHServer {
//    var host:String!
//    var user:String!
//    var passwd:String!
//    var alias:String?
//
//}

class HostTableViewController:  UITableViewController, UIViewControllerTransitioningDelegate,  NSFetchedResultsControllerDelegate {

    private var userChangeTheTable:Bool = false
    private var activeSSHVC = [Int64:SSHViewController]()
    

    static private let persistentContainer: NSPersistentContainer = {
        return (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    }()!

    private lazy var fetchedResultsController:NSFetchedResultsController = { () -> NSFetchedResultsController<Server> in
        let request:NSFetchRequest<Server> = Server.fetchRequest()
        let nameSort = NSSortDescriptor(key: "addtime", ascending: true)
        request.sortDescriptors = [nameSort]
        let moc = persistentContainer.viewContext
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }

    // MARK: IBAction

    @IBAction func quickConnect(_ sender: UIBarButtonItem) {
        let loginHostAlert = UIAlertController(title: "Connect to SSH", message: "Please input host address and port", preferredStyle: UIAlertControllerStyle.alert)
        loginHostAlert.addTextField { (address:UITextField) in
            address.resignFirstResponder()
            address.keyboardType = .numbersAndPunctuation
            address.placeholder =  "example: 192.168.0.1:22"
            address.returnKeyType = .next
        }
        loginHostAlert.addTextField { (user:UITextField) in
            user.returnKeyType = .next
            user.keyboardType = .asciiCapable
            user.placeholder = "User name"
        }
        loginHostAlert.addTextField { (passwd:UITextField) in
            passwd.returnKeyType = .go
            passwd.keyboardType = .asciiCapable
            passwd.placeholder = "Password"
        }
        let connect = UIAlertAction(title: "Connect", style: UIAlertActionStyle.default) { (UIAlertAction) in
            guard let textFields = loginHostAlert.textFields else {
                fatalError("No textFields")
            }
            self.showSSHView(host: textFields[0].text!, username: textFields[1].text!, passwd: textFields[2].text!)
        }
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (UIAlertAction) in
        }
        loginHostAlert.addAction(connect)
        loginHostAlert.addAction(cancel)
        self.present(loginHostAlert, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }

    // MARK: tableview datasource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return sshServers.count
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "hostCell") else {
            fatalError("Wrong cell type dequeued")
        }
        let object = self.fetchedResultsController.object(at: indexPath)
        if !(object.name?.isEmpty)!{
            cell.textLabel?.text = object.name
        } else {
            cell.textLabel?.text = String(format: "%@@%@", object.username!, object.hostname!)
        }
        cell.detailTextLabel?.text = "OnLine"
        return cell
    }

    // swipe action
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let context = HostTableViewController.persistentContainer.viewContext
            context.delete(fetchedResultsController.object(at: indexPath))
            do {
                try context.save()
            } catch {
                fatalError("Failure to save context:\(error)")
            }
        default:
            break
        }
    }

    // MARK: tableview delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sshServer = fetchedResultsController.object(at: indexPath)
        if let SSHVC = activeSSHVC[sshServer.addtime] {
            self.navigationController?.pushViewController(SSHVC, animated: true)
        } else {
            let SSHVC = showSSHView(host: sshServer.hostname!, username: sshServer.username!, passwd: sshServer.password!)
            activeSSHVC[sshServer.addtime] = SSHVC
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let sshServer = fetchedResultsController.object(at: indexPath)
        if let SSHVC = activeSSHVC[sshServer.addtime] {
            if SSHVC.isConnected {
                cell.detailTextLabel?.backgroundColor = UIColor.green
            } else {
                cell.detailTextLabel?.backgroundColor = UIColor.orange
            }
        } else {
            cell.detailTextLabel?.backgroundColor = UIColor.orange
        }
    }

    // MARK: show terminal view
    func showSSHView(host:String, username:String, passwd:String) -> SSHViewController {
        guard var SSHVC = self.storyboard?.instantiateViewController(withIdentifier: "SSHView") as? SSHViewController else {
            fatalError()
        }
        if username.isEmpty {
            let loginAlert = UIAlertController(title: "Login", message: "Connect to \"\(host)\"", preferredStyle: .alert)
            loginAlert.addTextField { (user:UITextField) in
                user.returnKeyType = .next
                user.keyboardType = .asciiCapable
                user.placeholder = "User name"
            }
            loginAlert.addTextField { (passwd:UITextField) in
                passwd.returnKeyType = .go
                passwd.keyboardType = .asciiCapable
                passwd.placeholder = "Password"
            }
            let connect = UIAlertAction(title: "Connect", style: UIAlertActionStyle.default) { (UIAlertAction) in
                guard let textFields = loginAlert.textFields else {
                    fatalError("No textFields")
                }
                SSHVC = self.showSSHView(host: host, username: textFields[0].text!, passwd: textFields[1].text!)
            }
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (UIAlertAction) in
            }
            loginAlert.addAction(connect)
            loginAlert.addAction(cancel)
            self.present(loginAlert, animated: true, completion: nil)

        } else if passwd.isEmpty {
            let loginAlert = UIAlertController(title: "Password", message: "Please input password for \"\(username)\"", preferredStyle: .alert)
            loginAlert.addTextField { (passwd:UITextField) in
                passwd.returnKeyType = .go
                passwd.keyboardType = .asciiCapable
                passwd.placeholder = "Password"
            }
            let connect = UIAlertAction(title: "Connect", style: UIAlertActionStyle.default) { (UIAlertAction) in
                guard let textFields = loginAlert.textFields else {
                    fatalError("No textFields")
                }
                SSHVC = self.showSSHView(host: host, username: username, passwd: textFields[0].text!)
            }
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (UIAlertAction) in
            }
            loginAlert.addAction(connect)
            loginAlert.addAction(cancel)
            self.present(loginAlert, animated: true, completion: nil)
        } else {
            SSHVC.host = host
            SSHVC.user = username
            SSHVC.passwd = passwd
            self.tableView.reloadData()
            self.navigationController?.pushViewController(SSHVC, animated: true)
        }
        return SSHVC
    }


    // MARK: NSFetchedResultsControllerDelegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if userChangeTheTable {
            return
        }
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        if userChangeTheTable {
            return
        }
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .right)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .left)
        case .move:
            break
        case .update:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if userChangeTheTable {
            return
        }
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .right)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .left)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if userChangeTheTable {
            userChangeTheTable = false
            return
        }
        tableView.endUpdates()
    }
}
