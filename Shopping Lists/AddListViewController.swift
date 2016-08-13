//
//  AddListViewController.swift
//  Shopping Lists
//
//  Created by Michael Henry on 9/13/15.
//  Copyright © 2015 Digital Javelina, LLC. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

protocol AddListViewControllerDelegate {
    func controller(controller: AddListViewController, didAddList list: CKRecord)
    func controller(controller: AddListViewController, didUpdateList list: CKRecord)
}

class AddListViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var delegate: AddListViewControllerDelegate?
    var newList: Bool = true
    var list: CKRecord?
    
    //MARK: -
    //MARK: Actions
    
    @IBAction func cancel(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func save(sender: AnyObject) {
        //Helpers
        let name = nameTextField.text
        
        //Fetch private database
        let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
        
        if list == nil {
            list = CKRecord(recordType: RecordTypeLists)
        }
        
        //Configure record
        list?.setObject(name, forKey: "name")
        
        //Show progress HUD
        SVProgressHUD.show()
        
        //Save record
        privateDatabase.saveRecord(list!) { (record, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //Dismiss progress HUD
                SVProgressHUD.dismiss()
                
                //Process response
                self.processResponse(record, error: error)
            })
        }
    }
    
    //MARK: -
    //MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        //Update helper
        newList = list == nil
        
        //Add observer
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "textFieldTextDidChange:", name: UITextFieldTextDidChangeNotification, object: nameTextField)
    }
    
    override func viewDidAppear(animated: Bool) {
        nameTextField.becomeFirstResponder()
    }
    
    //MARK: -
    //MARK: View Methods
    
    private func setupView() {
        updateNameTextField()
        updateSaveButton()
    }
    
    //MARK: -
    private func updateNameTextField() {
        if let name = list?.objectForKey("name") as? String {
            nameTextField.text = name
        }
    }
    
    //MARK: -
    private func updateSaveButton() {
        let text = nameTextField.text
        
        if let name = text {
            saveButton.enabled = !name.isEmpty
        } else {
            saveButton.enabled = false
        }
    }
    
    //MARK: -
    //MARK: Helper Methods
    
    private func processResponse(record: CKRecord?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We are not able to save your list."
        } else if record == nil {
            message = "We are not able to save your list."
        }
        
        if message.isEmpty {
            //Initialize alert controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
            
            //Present alert controller
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            //Notify delegate
            if newList {
                delegate?.controller(self, didAddList: list!)
            } else {
                delegate?.controller(self, didUpdateList: list!)
            }
            
            //Pop view controller
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    //MARK: -
    //MARK: Notification Handling
    
    func textFieldTextDidChange(notification: NSNotification) {
        updateSaveButton()
    }
    
}
