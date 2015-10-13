//
//  NewAccountManager.swift
//  Stormpath Demo
//
//  Created by Steven Berard on 10/12/15.
//  Copyright © 2015 Byteware LLC. All rights reserved.
//

import UIKit

protocol NewAccountManagerDelegate {
    func accountCreationDidSucceed(didSucceed: Bool, message: String)
}

class NewAccountManager: StormpathManager {
    
    let _firstName : String
    let _lastName : String
    let _email : String
    let _password : String
    
    var delegate : NewAccountManagerDelegate?
    var _task : NSURLSessionDataTask?
    
    init(firstName: String, lastName: String, email: String, password: String) {
        _firstName = firstName
        _lastName = lastName
        _email = email
        _password = password
    }
    
    func attemptToCreateNewAccount() {
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 60.0
        
        sessionConfig.HTTPAdditionalHeaders = ["Accept" : "application/json", "Content-Type" : "application/json"]
        
        // The session needs to know delegate for authentication
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
        // This is setting the URL request to the accountsURL from Stormpath
        let request = NSMutableURLRequest(URL: NSURL(string: self.accountsURL)!)
        
        request.HTTPMethod = "POST"
        
        // This is the parameters of the body of the HTTP
        let params = ["givenName": _firstName,
            "surname": _lastName,
            "username": _email,
            "email": _email,
            "password":_password]
        
        do {
            
            try request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions(rawValue: 0))
        }
        catch {
            print("Something went wrong")
        }
        
        _task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
            // Completion handler for NSURLSessionDataTask
            
            // First make sure there's actually data (Timeouts and cancels do not have data)
            if let data = data as NSData? {
                
                // Put the data into string format and print it to the log
                if let strData = NSString(data: data, encoding: NSUTF8StringEncoding) as String? {
                    print("Body: \(strData)")
                }
                else {
                    print("Body: Error! Could not be formatted to String")
                }
                
                do {
                    // Try to parse the data as a JSON file and put it into an NSDictionary
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as! NSDictionary
                    
                    if let status = json["status"] as? String? {
                        
                        if status! == "ENABLED" {
                            print("Account successfully created!")
                        }
                        
                        if let d = self.delegate as NewAccountManagerDelegate? {
                            dispatch_async(dispatch_get_main_queue(), {
                                d.accountCreationDidSucceed(true, message: status!)
                            })
                        }
                    }
                    else {
                        if let failMessage = json["message"] as! String? {
                            
                            print("Fail Message: \(failMessage)")
                            
                            if let d = self.delegate as NewAccountManagerDelegate? {
                                dispatch_async(dispatch_get_main_queue(), {
                                    d.accountCreationDidSucceed(false, message: failMessage)
                                })
                            }
                        }
                        else {
                            print("Major error!  The site didn't return a new account fail message!")
                            
                            if let d = self.delegate as NewAccountManagerDelegate? {
                                dispatch_async(dispatch_get_main_queue(), {
                                    d.accountCreationDidSucceed(false, message: "Major error!  The site didn't return a login fail message!")
                                })
                            }
                        }
                    }
                    
                }
                catch {
                    print("Could not parse json")
                }
            }
            else {
                // This is a timeout error or user cancelled the request
                
                // TODO: Figure out how to recognize Server Timeouts so I can send the error
                
                //                if let d = self.delegate as LoginManagerDelegate? {
                //                    dispatch_async(dispatch_get_main_queue(), {
                //                        d.accountAuthorizationDidSucceed(false, message: "Server Timeout")
                //                    })
                //                }
            }
        })
        
        _task!.resume()
    }
    
    func cancelRequest() {
        
        if let t = _task {
            t.cancel()
        }
    }
}
