//
//  LoginManager.swift
//  Stormpath Demo
//
//  Created by Steven Berard on 10/10/15.
//  Copyright © 2015 Byteware LLC. All rights reserved.
//

import UIKit

protocol LoginManagerDelegate {
    func accountAuthorizationDidSucceed(didSucceed: Bool, message: String)
}

class LoginManager: StormpathManager {
    
    let _email : String
    let _password : String
    var delegate : LoginManagerDelegate?
    var task : NSURLSessionDataTask?
    
    init(email: String, password: String) {
        _email = email
        _password = password
    }
    
    func attemptToAuthenticateUser() {
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 60.0
        
        sessionConfig.HTTPAdditionalHeaders = ["Accept" : "application/json", "Content-Type" : "application/json"]
        
        // The session needs to know delegate for authentication
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
        // This is setting the URL request to the loginAttempsURL from Stormpath
        let request = NSMutableURLRequest(URL: NSURL(string: self.loginAttemptsURL)!)
        
        request.HTTPMethod = "POST"
        
        // Take the username and password and base64 encode them
        let loginString = NSString(format: "%@:%@", _email, _password)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        
        let params = ["type": "basic","value": base64LoginString]
        
        do {
        
            try request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions(rawValue: 0))
        }
        catch {
            print("Something went wrong")
        }
        
        task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            
            // Completion block for NSURLSessionDataTask
            
            // First make sure there's actually data (Timeouts do not have data)
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
                    
                    if let account = json["account"] as! NSDictionary? {
                        print("Account Authorized!")
                        
                        let accountSite = account["href"] as! String
                        print("Account: \(accountSite)")
                        
                        if let d = self.delegate as LoginManagerDelegate? {
                            dispatch_async(dispatch_get_main_queue(), {
                                d.accountAuthorizationDidSucceed(true, message: accountSite)
                            })
                        }
                    }
                    else {
                        if let failMessage = json["message"] as! String? {
                            
                            print("Fail Message: \(failMessage)")
                            
                            if let d = self.delegate as LoginManagerDelegate? {
                                dispatch_async(dispatch_get_main_queue(), {
                                    d.accountAuthorizationDidSucceed(false, message: failMessage)
                                })
                            }
                        }
                        else {
                            print("Major error!  The site didn't return a login fail message!")
                            
                            if let d = self.delegate as LoginManagerDelegate? {
                                dispatch_async(dispatch_get_main_queue(), {
                                    d.accountAuthorizationDidSucceed(false, message: "Major error!  The site didn't return a login fail message!")
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
        
        task!.resume()
    }
    
    func cancelAuthRequest() {
        
        if let t = task {
            t.cancel()
        }
    }
}
