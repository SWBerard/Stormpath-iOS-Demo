//
//  StormpathManager.swift
//  Stormpath Demo
//
//  Created by Steven Berard on 10/12/15.
//  Copyright © 2015 Byteware LLC. All rights reserved.
//

import UIKit

class StormpathManager: NSObject, NSURLSessionTaskDelegate {
    
    // Put your apiKey and appSecret keys here.  You can get these by creating an account on https://api.stormpath.com/register
    
    let apiKey = // $YOUR_API_KEY_ID
    let appSecret = // $YOUR_API_KEY_SECRET
    
    // Your loginAttempts, accounts, and passwordResetTokens URLs here.  You can learn how to get this by following the instructions at http://docs.stormpath.com/rest/quickstart
    
    let loginAttemptsURL =  // "https://api.stormpath.com/v1/applications/$YOUR_APPLICATION_ID/loginAttempts"
    let accountsURL =  // "https://api.stormpath.com/v1/applications/$YOUR_APPLICATION_ID/accounts"
    let passwordResetTokensURL =  // "https://api.stormpath.com/v1/applications/$YOUR_APPLICATION_ID/passwordResetTokens"
    
    // MARK: NSURLSessionTaskDelegate Methods
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        print("didReceiveChallenge")
        
        if challenge.previousFailureCount > 0 {
            print("Alert Please check the credential")
            completionHandler(NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge, nil)
        } else {
            print("Sending task credential data")
            let credential = NSURLCredential(user:self.apiKey, password:self.appSecret, persistence: .ForSession)
            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential,credential)
        }
    }
}

extension NSMutableData {
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}
