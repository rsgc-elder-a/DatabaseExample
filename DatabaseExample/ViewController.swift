//
//  ViewController.swift
//  DatabaseExample
//
//  Created by Russell Gordon on 11/8/16.
//  Copyright © 2016 Russell Gordon. All rights reserved.
//

import UIKit

struct Contact {
    var name : String
    var address: String
    var phone: String
    init(name: String, address: String, phone: String){
        self.name = name
        self.address = address
        self.phone = phone
    }
}



class ViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var address: UITextField!
    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var searchField: UITextField!
    
    @IBOutlet weak var buttonNext: UIButton!
    
    // Object to store reference to DB
    var contactDB : FMDatabase?
    
    
    // Object to store results retreived from DB
    var results : FMResultSet?
    
    // Will save path to database file
    var databasePath = NSString()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //handle the text field for name....its user imput will be dealt with through callback to methods below
        name.delegate = self
        
        // Identify the app's Documents directory and build a path to "contacts.db"
        let fileManager = FileManager.default
        let directoryPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = directoryPaths[0]
        databasePath = documentsDirectory.appending("contacts.db") as NSString
        
        // Initialize (create) the database if it doesn't already exist
        if !fileManager.fileExists(atPath: databasePath as String) {
            
            // Create the database
            if let contactDB = FMDatabase(path: databasePath as String) {
                
                // Try to open the empty database and create the table structure required
                if contactDB.open() {
                    
                    // Define the SQL statement to be run
                    let SQL = "CREATE TABLE IF NOT EXISTS CONTACTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, ADDRESS TEXT, PHONE TEXT)"
                    
                    // Attempt to run the SQL statement
                    if !contactDB.executeStatements(SQL) {
                        print("Error: \(contactDB.lastErrorMessage())")
                    }
                    
                    // Close the database connection
                    contactDB.close()
                    
                } else {
                    
                    // We couldn't open the database, so throw an error
                    print("Error: \(contactDB.lastErrorMessage())")
                    
                }
                
            }
            
        } else {
            print("Error: Could not create DB.")
        }
        
    }
    
    //MARK: Actions
    @IBAction func saveData(_ sender: Any) {
        
        // Establish path to database through FMDatabase wrapper
        if let contactDB = FMDatabase(path: databasePath as String) {
            
            // We know database should exist now (since viewDidLoad runs at startup)
            // Now, open the database and insert data from the view (the user interface)
            if contactDB.open() {
                
                // Get data from the form fields on the view (user interface)
                guard let nameValue : String = name.text else {
                    status.text = "Hey, we need a name here."
                    return
                }
                guard let addressValue : String = address.text else {
                    status.text = "Hey, we need an address!"
                    return
                }
                guard let phoneValue : String = phone.text else {
                    status.text = "Please provide a phone number."
                    return
                }
                
                // Create SQL statement to insert data
                let SQL = "INSERT INTO CONTACTS (name, address, phone) VALUES ('\(nameValue)', '\(addressValue)', '\(phoneValue)')"
                
                // Try to run the statement
                let result = contactDB.executeUpdate(SQL, withArgumentsIn: nil)
                
                // See what happened and react accordingly
                if !result {
                    status.text = "Failed to add contact"
                } else {
                    status.text = "Contact added"
                    
                    // Clear out the form fields
                    name.text = ""
                    address.text = ""
                    phone.text = ""
                }
                
            }
            
        } else {
            
            // We couldn't open the database, so throw an error
            print("Error: Could not save data to database.")
            
        }
        
    }
   
    
    @IBAction func findContact(_ sender: Any) {
        
        // Establish path to database through FMDatabase wrapper
        if let contactDB = FMDatabase(path: databasePath as String) {
            
            // We know database should exist now (since viewDidLoad runs at startup)
            // Now, open the database and insert data from the view (the user interface)
            if contactDB.open() {
                
                // Get form field value
                guard let searchString : String = searchField.text else {
                    status.text = "Please provide a name."
                    return
                }
                
                // Create SQL statement to find data
                let SQL = "SELECT name, address, phone FROM CONTACTS WHERE name LIKE '%\(searchString)%' OR address LIKE '%\(searchString)%' OR phone LIKE '%\(searchString)%'"
                
                // Run query
                do {
                    
                    // Try to run the query
                    let results : FMResultSet? = try contactDB.executeQuery(SQL, values: nil)
                    
                    // We know database should exist now (since viewDidLoad runs at startup)
                    // Now, open the database and select data using value given for name in the view (user interface)
                    if results?.next() == true {    // Something was found for this query
                        
                        guard let nameValue : String = results?.string(forColumn: "name") else {
                            print("Nil value rerunted from adress thats odd ")
                            return
                        }
                        
                        guard let addressValue : String = results?.string(forColumn: "address") else {
                            print("Nil value returned from query for the address, that's odd.")
                            return
                        }
                        guard let phoneValue : String = results?.string(forColumn: "phone") else {
                            print("Nil value returned from query for the phone number, that's odd.")
                            return
                        }
                        
                        // Load the results in the view (user interface)
                        name.text = nameValue
                        address.text = addressValue
                        phone.text = phoneValue
                        status.text = "Record found!"
                        
                    } else {
                        
                        // Nothing was found for this query
                        status.text = "Record not found"
                        address.text = ""
                        phone.text = ""
                    }
                    
                    // Close the database
                    //contactDB.close()
                    
                } catch {
                    
                    // Query did not run, so report an error
                    print("Error: \(contactDB.lastErrorMessage())")
                }
                
            }
            
        } else {
            
            // Database could not be opened, report an error
            print("Error: Database could not be opened.")
            
        }
        
    }
    
    
    @IBAction func startEdit(_ sender: Any) {
        if let searchVal : String = searchField.text {
            print(searchVal)
            
            
        }
        
        // Invoke the findContact method.
        if let searchString = searchField.text {
            if searchString == "" {
                resetFields()
                status.text = ""
                // buttonNext.isEnabled = false
                // buttonPrior.isEnabled = false
            } else {
                findContact(sender)
            }
        }
    }
    
    func resetFields() {
        name.text = ""
        address.text = ""
        phone.text = ""
    }
    
    
    @IBAction func scrollLeft(_ sender: UIButton) {
        print("back")
        
    }
    
    @IBAction func scrollRight(_ sender: UIButton) {
        print("foward")
        
           displayResult()
        
    }
    
    func displayResult() {
        
        if results?.hasAnotherRow() == true {
            
            guard let nameValue : String = results?.string(forColumn: "name") else {
                print("Nil value returned from query for the address, that's odd.") //
                return
            }
            guard let addressValue : String = results?.string(forColumn: "address") else {
                print("Nil value returned from query for the address, that's odd.")
                return
            }
            guard let phoneValue : String = results?.string(forColumn: "phone") else {
                print("Nil value returned from query for the phone number, that's odd.")
                return
            }
            
            // Load the results in the view (user interface)
            name.text = nameValue
            address.text = addressValue
            phone.text = phoneValue
            status.text = "Record found!"
            
            // Enable the next result button if there is another result
            if results?.next() == true {
                if results?.hasAnotherRow() == true {
                    buttonNext.isEnabled = true
                }
            } else {
                buttonNext.isEnabled = false
                
                // Close the database
                if contactDB?.close() == true {
                    print("DB closed")
                }
                
            }
            
        }
        /*Add a fumcton for when the prior
         make sure to check if there is a prior result
         then if there is go back to prevois result
         
         Make a stuct to hold reuslts
         struct Contact {
         */
        
        print("Another row?")
        print(results?.hasAnotherRow())
        print("contents of next row")
        print(results?.resultDictionary())
    }
    
    
    @IBAction func searchField(_ sender: Any) {
        
        if let searchResult = searchField.text {
            print(searchResult)
            
        }
        
    }
    //MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print(name.text)
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        print(name.text)
    }
    
    
    
    
    
}


