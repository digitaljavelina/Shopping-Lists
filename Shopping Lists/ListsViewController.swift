//
//  ListsViewController.swift
//  Shopping Lists
//
//  Created by Michael Henry on 9/13/15.
//  Copyright © 2015 Digital Javelina, LLC. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

let RecordTypeLists = "Lists"

class ListsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddListViewControllerDelegate {
    
    static let ListCell = "ListCell"
    let SegueListDetail = "SegueListDetail"
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var lists = [CKRecord]()
    var selection: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        fetchLists()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func fetchUserRecordID() {
        //Fetch default container
        let defaultContainer = CKContainer.defaultContainer()
        
        //Fetch user record
        defaultContainer.fetchUserRecordIDWithCompletionHandler { (recordID, error) -> Void in
            if let responseError = error {
                print(responseError)
            } else if let userRecordID = recordID {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.fetchUserRecord(userRecordID)
                })
            }
        }
    }
    
    private func fetchUserRecord(recordID: CKRecordID) {
        //Fetch default container
        let defaultContainer = CKContainer.defaultContainer()
        
        //Fetch private database
        let privateDatabase = defaultContainer.privateCloudDatabase
        
        //Fetch user record
        privateDatabase.fetchRecordWithID(recordID) { (record, error) -> Void in
            if let responseError = error {
                print(responseError)
            } else if let userRecord = record {
                print(userRecord)
            }
        }
    }
    
    //MARK: -
    //MARK: Table View Data Source Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //Dequeue reusable cell
        let cell = tableView.dequeueReusableCellWithIdentifier(ListsViewController.ListCell, forIndexPath: indexPath)
        
        //Configure cell
        cell.accessoryType = .DetailDisclosureButton
        
        //FetchRecord
        let list = lists[indexPath.row]
        
        if let listName = list.objectForKey("name") as? String {
            //Configure cell
            cell.textLabel?.text = listName
        } else {
            cell.textLabel?.text = "-"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard editingStyle == .Delete else { return }
        
        //Fetch record
        let list = lists[indexPath.row]
        
        //Delete record
        deleteRecord(list)
    }
    
    private func deleteRecord(list: CKRecord) {
        //Fetch private database
        let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
        
        //Show progress HUD
        SVProgressHUD.show()
        
        //Delete list
        privateDatabase.deleteRecordWithID(list.recordID) { (recordID, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //Dismiss progress HUD
                SVProgressHUD.dismiss()
                
                //Process response
                self.processResponseForDeleteRequest(list, recordID: recordID, error: error)
            })
        }
    }
    
    private func processResponseForDeleteRequest(record: CKRecord, recordID: CKRecordID?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We are unable to delete this list."
        } else if recordID == nil {
            message = "We are unable to delete this list."
        }
        
        if message.isEmpty {
            //Calculate row index
            let index = lists.indexOf(record)
            
            if let index = index {
                //Update data source
                lists.removeAtIndex(index)
                
                if lists.count > 0 {
                    //Update table view
                    tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Right)
                } else {
                    //Update message label
                    messageLabel.text = "No records found"
                    
                    //Update view
                    updateView()
                }
            }
        } else {
            //Initalize alert controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
            
            //Present alert controller
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    //MARK: -
    //MARK: View Methods
    
    private func setupView() {
        tableView.hidden = true
        messageLabel.hidden = true
        activityIndicatorView.startAnimating()
    }
    
    //MARK: -
    //MARK: Helper Methods
    
    private func fetchLists() {
        
        //Fetch private database
        let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
        
        //Initialize query
        let query = CKQuery(recordType: RecordTypeLists, predicate: NSPredicate(format: "TRUEPREDICATE"))
        
        //Configure query
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        //Perform query
        privateDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //Process response on main thread
                self.processResponseForQuery(records, error: error)
            })
        }
    }
    
    private func processResponseForQuery(records: [CKRecord]?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "Error Fetching Records"
        } else if let records = records {
            lists = records
            
            if lists.count == 0 {
                message = "No Records Found"
            }
        } else {
            message = "No Records Found"
        }
        
        if message.isEmpty {
            tableView.reloadData()
        } else {
            messageLabel.text = message
        }
        
        updateView()
    }
    
    private func updateView() {
        let hasRecords = lists.count > 0
        
        tableView.hidden = !hasRecords
        messageLabel.hidden = hasRecords
        activityIndicatorView.stopAnimating()
    }
    
    //MARK: -
    //MARK: AddListViewControllerDelegate Methods
    
    func controller(controller: AddListViewController, didAddList list: CKRecord) {
        //Add List to Lists
        lists.append(list)
        
        //Sort lists
        sortLists()
        
        //Update table view
        tableView.reloadData()
        
        //Update view
        updateView()
    }
    
    private func sortLists() {
        lists.sortInPlace {
            var result = false
            let name0 = $0.objectForKey("name") as? String
            let name1 = $1.objectForKey("name") as? String
            
            if let listName0 = name0, listName1 = name1 {
                result = listName0.localizedCaseInsensitiveCompare(listName1) == .OrderedAscending
            }
            
            return result
        }
    }
    
    func controller(controller: AddListViewController, didUpdateList list: CKRecord) {
        //Sort lists
        sortLists()
        
        //Update table view
        tableView.reloadData()
    }
    
    //MARK: -
    //MARK: Table View Delegate Methods
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        //Save selection
        selection = indexPath.row
        
        //Perform segue
        performSegueWithIdentifier(SegueListDetail, sender: self)
    }
    
    //MARK: -
    //MARK: Segue Life Cycle
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case SegueListDetail:
            //Fetch destination view controller
            let addListViewController = segue.destinationViewController as! AddListViewController
            
            //Configure view controller
            addListViewController.delegate = self
            
            if let selection = selection {
                //Fetch list
                let list = lists[selection]
                
                //Configure view controller
                addListViewController.list = list
            }
        default:
            break
        }
    }

}

