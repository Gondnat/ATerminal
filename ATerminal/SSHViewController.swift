//
//  ViewController.swift
//  ATermial
//
//  Created by Daniel Tan on 10/05/2017.
//  Copyright © 2017 Thnuth. All rights reserved.
//

import UIKit
import NMSSH

class SSHViewController: UIViewController, UITextViewDelegate, NMSSHSessionDelegate, NMSSHChannelDelegate {
    @IBOutlet var textView: UITextView!
    
    private var lastCommand:String = ""
    private var lastLinePrefix:String = "~$"
    
    private var session:NMSSHSession!
    private var queue:DispatchQueue {
        return DispatchQueue(label: "SSHVIEW.queue")
    }
    private var semaphore:DispatchSemaphore?
    
//    private var lastText:String = ""
    
    public var host:String!
    public var user:String!
    public var passwd:String!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.session = NMSSHSession.connect(toHost: self.host, withUsername: self.user)
        self.session.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // keyboard notification
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        
        
        queue.async {
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
                        self.textView.isEditable = true
                    })
                    self.session.channel.delegate = self
                    self.session.channel.requestPty = true
                    self.session.channel.ptyTerminalType = .VT100
                }
                
                do {
                    try self.session.channel.startShell()
                } catch  {
                    DispatchQueue.main.async(execute: {
                        self.textView.isEditable = false
                        self.append(error.localizedDescription)
                    })
                }
            } else {
                DispatchQueue.main.async(execute: {
                    self.append("can't connect to"+self.host)
                })
        }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK: IBAction
    @IBAction func disconnect(_ sender: UIBarButtonItem) {
        queue.async {
            self.session.disconnect()
        }
    }
    
    // MARK:
    func append(_ other:String) {
        self.textView.text.append(other)
        if let text = textView.text {
            if let range = text.range(of: "\n", options: .backwards, range: text.startIndex..<text.index(before: text.endIndex)) {
                lastLinePrefix = text[range.upperBound..<text.endIndex]
            }
        }
    }
    
    func performCommand() {
        if nil != semaphore {
            passwd = self.lastCommand.substring(to: lastCommand.index(before: lastCommand.endIndex))
            semaphore?.signal()
        } else {
            let command = self.lastCommand
            queue.async(execute: { 
                self.session.channel.write(command, error: nil, timeout: 10)
            })
            self.lastCommand = ""
        }
    }
    
    // MARK: NMSSHSession
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
            self.append(message)
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
    
    // MARK: UITextView delegate
    func textViewDidChange(_ textView: UITextView) {
        textView.scrollRangeToVisible(NSMakeRange((textView.text as NSString).length-1, 1))
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.selectedRange.location < (textView.text as NSString).length - (self.lastCommand as NSString).length - 1 {
            textView.scrollRangeToVisible(NSMakeRange((textView.text as NSString).length, 0))
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty {
            if !self.lastCommand.isEmpty {
                lastCommand.remove(at: lastCommand.index(before: lastCommand.endIndex))
                
                return true
            } else {
                return false
            }
        }
        self.lastCommand.append(text)
        if text == "\n" {
            if let text = textView.text {
                if let range = text.range(of: "\n", options: .backwards, range: text.startIndex..<text.index(before: text.endIndex)) {
                    let lastLine = text[range.upperBound..<text.endIndex]
                    lastCommand = lastLine[lastLinePrefix.endIndex..<lastLine.endIndex]
                    lastCommand.append("\n")
                }
            }

            performCommand()
        }
        return true
    }
    
    // MARK: Notification
    func keyboardWillShow(notification: NSNotification) {
        let ownFrame = self.view.window!.convert(textView.frame, from: textView.superview)
        if let userInfo = notification.userInfo {
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
            var coveredFrame = ownFrame.intersection(keyboardFrame)
            coveredFrame = self.view.window!.convert(coveredFrame, to: textView.superview)
            textView.contentInset = UIEdgeInsetsMake(textView.contentInset.top, 0, coveredFrame.size.height, 0)
            textView.scrollIndicatorInsets = textView.contentInset
        }
    }
    func keyboardWillHide(notification:NSNotification) {
        textView.contentInset = UIEdgeInsetsMake(textView.contentInset.top, 0, 0, 0)
        textView.scrollIndicatorInsets = textView.contentInset
    }
}

