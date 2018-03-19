//
//  ViewController.swift
//  ATermial
//
//  Created by Daniel Tan on 10/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit
import NMSSH

class SSHViewController: UIViewController, NMSSHSessionDelegate, NMSSHChannelDelegate, UIKeyInput {
    @IBOutlet var textView: UITextView!

    private var lastCommand:String = ""
//    private var lastLinePrefix:String = "~$"

    var session:NMSSHSession! {
        didSet {
            session.delegate = self
        }
    }
    private var queue:DispatchQueue {
        return DispatchQueue(label: "SSHVIEW.queue")
    }
    private var semaphore:DispatchSemaphore?
    
//    private var lastText:String = ""
    
//    public var host:String!
//    public var user:String!
    public var passwd:String!

    var isConnected: Bool {
        return session.isConnected
    }

//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view, typically from a nib.
//        session = NMSSHSession(host: host, andUsername: user)
////        session = NMSSHSession.connect(toHost: host, withUsername: user)
//        session.delegate = self
//
//    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.becomeFirstResponder()
        navigationItem.title = session.host
        // keyboard notification
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        
        
        queue.async {
            if self.session.isConnected && self.session.isAuthorized {
                return
            }
            if !self.session.isConnected {
                self.session.connect(withTimeout: 2)
            }
            if self.session.isConnected {
                if !self.passwd.isEmpty{
                    self.session.authenticate(byPassword: self.passwd)
                } else {
                    self.session.authenticateByKeyboardInteractive()
                }

                if !self.session.isAuthorized {
                    DispatchQueue.main.async(execute: {
                        self.append("Authentication error")
                        self.textView.isEditable = false
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        self.textView.isEditable = false
                    })
                    self.session.channel.delegate = self
                    self.session.channel.requestPty = true
//                    self.session.channel.ptyTerminalType = .xterm
                }
                
                do {
                    try self.session.channel.startShell()
                } catch  {
                    DispatchQueue.main.async(execute: {
                        self.append(error.localizedDescription)
                    })
                }
            } else {
                DispatchQueue.main.async(execute: {
                    self.append("can't connect to"+self.session.host)
                })
        }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        // keyboard notification
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK: - IBAction
    @IBAction func disconnect(_ sender: UIBarButtonItem) {
        queue.async {
            if self.session.isConnected {
                self.session.disconnect()
            }
        }
    }
    
    // MARK: -
    func append(_ other:String) {
        self.textView.text.append(other)
        textView.scrollRangeToVisible(NSMakeRange((textView.text as NSString).length, 0))
    }
    
    func performCommand() {
        if nil != semaphore {
            passwd = String(self.lastCommand[...(self.lastCommand.endIndex)]);
            semaphore?.signal()
        } else {
            let command = self.lastCommand
            queue.async(execute: { 
                self.session.channel.write(command, error: nil, timeout: 10)
            })
            self.lastCommand = ""
        }
    }
    
    // MARK: - NMSSHSession
    func session(_ session: NMSSHSession!, keyboardInteractiveRequest request: String!) -> String! {
        DispatchQueue.main.async(execute: {
            self.append(request)
            self.textView.isEditable = false
        })
        semaphore = DispatchSemaphore(value: 0)
        semaphore?.wait()
        semaphore = nil
        return self.passwd
    }
    func session(_ session: NMSSHSession!, didDisconnectWithError error: Error!) {
        DispatchQueue.main.async(execute: {
            self.append(error.localizedDescription)
            self.textView.isEditable = false
        })
    }
    // MARK: NMSSHChannel
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        DispatchQueue.main.async(execute: {
            if ((message as NSString).character(at: 0) == 0x08) { // delete
                self.textView.text.removeLast()
            } else {
                self.append(message)
            }
        })
    }
    func channel(_ channel: NMSSHChannel!, didReadError error: String!) {
        DispatchQueue.main.async(execute: {
            self.append(error)
        })
    }
    func channelShellDidClose(_ channel: NMSSHChannel!) {
        DispatchQueue.main.async(execute: {
            self.append("\nShell closed\n")
            self.textView.isEditable = false
        })
    }

    // MARK: -
    override var canBecomeFirstResponder: Bool {
        return true
    }

    // MARK: - UIKeyInput
    var hasText: Bool {
        return true
    }
    func insertText(_ text: String) {
        queue.async(execute: {
            self.session.channel.write(text, error: nil, timeout: 10)
        })
    }

    func deleteBackward() {
        queue.async {
            do {
                try self.session.channel.write(String(bytes: [127], encoding: String.Encoding.ascii))
            } catch {

            }
        }
    }

    // MARK: - Notification
    @objc func keyboardWillShow(notification: NSNotification) {
        let ownFrame = self.view.window!.convert(textView.frame, from: textView.superview)
        if let userInfo = notification.userInfo {
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
            var coveredFrame = ownFrame.intersection(keyboardFrame)
            coveredFrame = self.view.window!.convert(coveredFrame, to: textView.superview)
            textView.contentInset = UIEdgeInsetsMake(textView.contentInset.top, 0, coveredFrame.size.height, 0)
            textView.scrollIndicatorInsets = textView.contentInset
        }
    }
    @objc func keyboardWillHide(notification:NSNotification) {
        textView.contentInset = UIEdgeInsetsMake(textView.contentInset.top, 0, 0, 0)
        textView.scrollIndicatorInsets = textView.contentInset
    }

    // MARK: - Arrow key
   override var keyCommands: [UIKeyCommand]? {
    return [UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: UIKeyModifierFlags(rawValue: 0), action: #selector(arrowKeys(keyCommand:))),
            UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: UIKeyModifierFlags(rawValue: 0), action: #selector(arrowKeys(keyCommand:))),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: UIKeyModifierFlags(rawValue: 0), action: #selector(arrowKeys(keyCommand:))),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: UIKeyModifierFlags(rawValue: 0), action: #selector(arrowKeys(keyCommand:)))]
    }

    @objc func arrowKeys(keyCommand:UIKeyCommand) {
        NSLog("%@ arrow pressed", keyCommand.input ?? "")
//        do {
//        switch keyCommand.input {
//        case UIKeyInputUpArrow?:
//            try session.channel.write("")
//        case UIKeyInputDownArrow?:
//            try session.channel.write("")
//        default:
//            break
//        }
//        }catch {
//
//        }
    }
}

