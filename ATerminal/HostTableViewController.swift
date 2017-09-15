//
//  HostTableViewController.swift
//  ATermial
//
//  Created by Daniel Tan on 11/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit
import CoreData
import NMSSH

enum SortKeyWord:String {
    case date = "addtime"
    case name = "name"
}

class HostTableViewController:  UITableViewController, UIViewControllerTransitioningDelegate,  NSFetchedResultsControllerDelegate, UISearchResultsUpdating {

    lazy var cancelAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "button title, user used to cancel"), style: .cancel)
    lazy var okAlertAction = UIAlertAction(title: NSLocalizedString("OK", comment: "button title, user comfirm the status"), style: .default)



    private var cacheFolder:URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private var knowHostsFilePath:String {
        let path = URL(fileURLWithPath: "./know_hosts", relativeTo: cacheFolder).path
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }
        return path
    }
    private var searchController:UISearchController!
    private var activeSSHVC = [Int64:SSHViewController]()

    private var userChangeTheTable:Bool = false

    private var sortKeyWord:SortKeyWord = .date {
        didSet {
            fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortKeyWord.rawValue, ascending: true)]
            do {
                try fetchedResultsController.performFetch()
            } catch {
                fatalError("Failed to initialize FetchedResultsController: \(error)")
            }
            tableView.reloadData()
        }
    }
    private var searchWord:String? {
        didSet {
            if searchWord != nil && searchWord!.count > 0 {
                fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "name like[c] %@ OR  hostname like[c] %@ OR username like[c] %@", "*".appending(searchWord!.appending("*")), searchWord!.appending("*"), searchWord!.appending("*"))
            } else {
                fetchedResultsController.fetchRequest.predicate = nil
            }
            do {
                try fetchedResultsController.performFetch()
            } catch {
                fatalError("Failed to initialize FetchedResultsController: \(error)")
            }
            tableView.reloadData()
        }
    }

    private lazy var fetchedResultsController = { () -> NSFetchedResultsController<Server> in
        let request:NSFetchRequest<Server> = Server.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: SortKeyWord.date.rawValue, ascending: true)]
        let moc = ServersController.persistentContainer.viewContext
        let _fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        _fetchedResultsController.delegate = self
        do {
            try _fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
        return _fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(HostTableViewController.longPressAction(gesture:)))
        longPressGesture.minimumPressDuration = 1.0
        tableView.addGestureRecognizer(longPressGesture)

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = searchController
            self.navigationItem.searchController?.isActive = true
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        definesPresentationContext = true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showServerSetting" && sender is UITableViewCell{
            var serverSettingVC:ServerSettingTableViewController?
            if segue.destination is UINavigationController {
                serverSettingVC = (segue.destination as! UINavigationController).viewControllers[0] as? ServerSettingTableViewController
            } else {
                serverSettingVC = segue.destination as? ServerSettingTableViewController
            }
            guard let indexPath = tableView.indexPath(for:(sender as? UITableViewCell)!) else {
                return
            }
            serverSettingVC?.server = self.fetchedResultsController.object(at:indexPath)
        }
    }

    // MARK: -
    @objc func longPressAction(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: tableView)
            guard let indexPath = tableView.indexPathForRow(at: point) else {
                return
            }
            let serverEditSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            serverEditSheet.addAction(UIAlertAction(title: NSLocalizedString("Edit", comment: "edit server"), style: .default, handler: { (action:UIAlertAction) in
                self.performSegue(withIdentifier: "showServerSetting", sender: self.tableView.cellForRow(at: indexPath))
            }))

            serverEditSheet.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "delete server"), style: .default, handler: { (UIAlertAction) in
                self.deleteServer(at: indexPath)
            }))
            serverEditSheet.addAction(cancelAlertAction)
            self.present(serverEditSheet, animated: true)

        }
    }

    // MARK: - IBAction

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
            user.placeholder = PlaceHolder.username
        }
        loginHostAlert.addTextField { (passwd:UITextField) in
            passwd.returnKeyType = .go
            passwd.keyboardType = .asciiCapable
            passwd.placeholder = PlaceHolder.password
        }
        let connect = UIAlertAction(title: "Connect", style: UIAlertActionStyle.default) { (UIAlertAction) in
            guard let textFields = loginHostAlert.textFields else {
                fatalError("No textFields")
            }
            self.showSSHView(host: textFields[0].text!, username: textFields[1].text!, passwd: textFields[2].text!, time: -1)
        }
        loginHostAlert.addAction(connect)
        loginHostAlert.addAction(cancelAlertAction)
        self.present(loginHostAlert, animated: true, completion: nil)
    }



    // MARK: - tableview datasource

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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "hostCell") as? HostNameAndStatusTableViewCell else {
            fatalError("Wrong cell type dequeued")
        }
        let object = self.fetchedResultsController.object(at: indexPath)
        if !(object.name?.isEmpty)!{
            cell.name?.text = object.name
        } else {
            cell.name?.text = String(format: "%@@%@", object.username!, object.hostname!)
        }

        let sshServer = fetchedResultsController.object(at: indexPath)
        if let SSHVC = activeSSHVC[sshServer.addtime] {
            if SSHVC.isConnected {
                cell.statusImage.image = UIImage(named: "onLine")
            } else {
                cell.statusImage.image = UIImage(named: "offLine")
            }
        }

        return cell
    }

    // swipe action
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:

            let sshServer = fetchedResultsController.object(at: indexPath)
            activeSSHVC[sshServer.addtime]?.removeFromParentViewController()
            activeSSHVC.removeValue(forKey: sshServer.addtime)
            let context = ServersController.persistentContainer.viewContext
            context.delete(sshServer)
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
            showSSHView(host: sshServer.hostname!, username: sshServer.username ?? "", passwd: sshServer.password ?? "", time: sshServer.addtime)
        }
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("Delete", comment: "titleForDeleteConfirmationButton")
    }

    // MARK: - show terminal view
    func showSSHView(host:String, username:String, passwd:String = "", time:Int64 = -1){
        let SSHVC = self.storyboard?.instantiateViewController(withIdentifier: "SSHView") as? SSHViewController
        if username.isEmpty {
            let loginAlert = UIAlertController(title: "Login", message: "Connect to \"\(host)\"", preferredStyle: .alert)
            loginAlert.addTextField { (user:UITextField) in
                user.returnKeyType = .next
                user.keyboardType = .asciiCapable
                user.placeholder = PlaceHolder.username
            }
            loginAlert.addTextField { (passwd:UITextField) in
                passwd.returnKeyType = .go
                passwd.keyboardType = .asciiCapable
                passwd.placeholder = PlaceHolder.password
            }
            let connect = UIAlertAction(title: "Connect", style: UIAlertActionStyle.default) { (UIAlertAction) in
                guard let textFields = loginAlert.textFields else {
                    fatalError("No textFields")
                }
                self.showSSHView(host: host, username: textFields[0].text!, passwd: textFields[1].text!, time: time)
            }

            loginAlert.addAction(connect)
            loginAlert.addAction(cancelAlertAction)
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
                self.showSSHView(host: host, username: username, passwd: textFields[0].text!, time: time)
            }
            loginAlert.addAction(connect)
            loginAlert.addAction(cancelAlertAction)
            self.present(loginAlert, animated: true, completion: nil)
        } else if nil != SSHVC {

            if let session = NMSSHSession(host: host, andUsername: username) {

                if !session.connect() {
                    let connectFailedAlert = UIAlertController(title: NSLocalizedString("Connect failed", comment: "Connect failed"), message: NSLocalizedString("Can't connect to \(session.host!)", comment: "Can't connect to special IP Addres in %@"), preferredStyle: .alert)
                    connectFailedAlert.addAction(okAlertAction)
                    self.present(connectFailedAlert, animated: true)
                    return
                }

                let pushSSHVC = {
                    self.tableView.reloadData()
                    SSHVC?.session = session
                    SSHVC?.passwd = passwd
                    self.navigationController?.pushViewController(SSHVC!, animated: true)
                    if time != -1 {
                        self.activeSSHVC[time] = SSHVC
                    }
                }

                switch session.knownHostStatus(inFiles: [knowHostsFilePath]) {
                case .match:
                    pushSSHVC()
                case .failure, .mismatch:
                    return
                case .notFound:
                    let unknowFingerprint = String(format:NSLocalizedString("Fingerprint is %@", comment: "Alert for unknow fingerprint")
                        , session.fingerprint(.SHA1))
                    let hostKeyAlert = UIAlertController(title: NSLocalizedString("Unknow fingerprint", comment: "Title of host key alert"), message: unknowFingerprint, preferredStyle: .alert)
                    let connectAnyway = UIAlertAction(title: NSLocalizedString("Connect", comment: "Title for sheet alert user if connect"), style: .default, handler: { (UIAlertAction) in
                        session.addKnownHostName(session.host, port: session.port as! Int, toFile: self.knowHostsFilePath, withSalt: nil)
                        pushSSHVC()
                    })

                    hostKeyAlert.addAction(connectAnyway)
                    hostKeyAlert.addAction(cancelAlertAction)
                    self.present(hostKeyAlert, animated: true)
                }

            }
        }
    }


    // MARK: - NSFetchedResultsControllerDelegate
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

    // MARK: -
    func deleteServer(at indexPath: IndexPath) {
        let sshServer = fetchedResultsController.object(at: indexPath)
        activeSSHVC[sshServer.addtime]?.removeFromParentViewController()
        activeSSHVC.removeValue(forKey: sshServer.addtime)
        let context = ServersController.persistentContainer.viewContext
        context.delete(sshServer)
        do {
            try context.save()
        } catch {
            fatalError("Failure to save context:\(error)")
        }
    }

    // MARK: - search updater
    func updateSearchResults(for searchController: UISearchController) {
        searchWord = searchController.searchBar.text
    }
}
