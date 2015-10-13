//
//  CreateAccountViewController.swift
//  Stormpath Demo
//
//  Created by Steven Berard on 10/11/15.
//  Copyright © 2015 Byteware LLC. All rights reserved.
//

import UIKit

class CreateAccountViewController: UIViewController, UITextFieldDelegate, NewAccountManagerDelegate {

    @IBOutlet weak var windowView: UIView!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var _isKeyboardOnScreen = false
    var _blurView : UIVisualEffectView?
    var _allowAutorotation = true
    var _newAccountManager : NewAccountManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // WindowView setup
        windowView.layer.shadowRadius = 2.0
        windowView.layer.shadowOpacity = 0.5
        windowView.layer.shadowOffset = CGSize.init(width: 0.0, height: 0.0)
        windowView.layer.cornerRadius = 3

        
        // createAccountButton setup
        createAccountButton.backgroundColor = UIColor.clearColor()
        
        // Top half of button
        let topButtonLayer = CALayer()
        topButtonLayer.frame = CGRect(x: createAccountButton.bounds.origin.x, y: createAccountButton.bounds.origin.y, width: createAccountButton.bounds.width, height: createAccountButton.bounds.height/2)
        topButtonLayer.backgroundColor = UIColor(red: 0.0, green: 0.77, blue: 0.0, alpha: 1.0).CGColor
        createAccountButton.layer.insertSublayer(topButtonLayer, atIndex: 0)
        
        // Bottom half of button
        let bottomButtonLayer = CALayer()
        bottomButtonLayer.frame = CGRect(x: createAccountButton.bounds.origin.x, y: createAccountButton.bounds.origin.y + createAccountButton.bounds.height/2, width: createAccountButton.bounds.width, height: createAccountButton.bounds.height/2)
        bottomButtonLayer.backgroundColor = UIColor(red: 0.0, green: 0.73, blue: 0.0, alpha: 1.0).CGColor
        createAccountButton.layer.insertSublayer(bottomButtonLayer, atIndex: 0)
        
        // Rounding the corners
        let maskButtonLayer = CAShapeLayer()
        maskButtonLayer.frame = createAccountButton.bounds
        maskButtonLayer.backgroundColor = UIColor.whiteColor().CGColor
        maskButtonLayer.cornerRadius = 5
        
        createAccountButton.layer.mask = maskButtonLayer
        
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
    }
    
    @IBAction func dismissKeyboard(sender: AnyObject?) {
        view.endEditing(true)
    }

    @IBAction func backToLogInPage(sender: AnyObject?) {
        
        dismissKeyboard(nil)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        // If the keyboard is on the screen we need to make the content size of the scrollView taller, so the user
        // can scroll to the all textviews
        
        if fromInterfaceOrientation == UIInterfaceOrientation.LandscapeLeft || fromInterfaceOrientation == UIInterfaceOrientation.LandscapeRight {
            if _isKeyboardOnScreen {
                scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height + 216)
            }
        }
        else {
            if _isKeyboardOnScreen {
                scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height + 162)
            }
        }
    }
    
    func cancelAccountCreationAttempt() {
        if let bv = _blurView as UIVisualEffectView? {
            if let nAM = _newAccountManager {
                nAM.cancelRequest()
            }
            bv.removeFromSuperview()
            _allowAutorotation = true
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    
    @IBAction func attemptToCreateAccount(sender: AnyObject) {
        
        dismissKeyboard(nil)
        
        var errorMessage : String?
        
        if firstNameTextField.text! == "" {
            errorMessage = "Please enter a first name."
        }
        else if lastNameTextField.text! == "" {
            errorMessage = "Please enter a last name."
        }
        else if emailTextField.text! == "" {
            errorMessage = "Please enter a valid email address."
        }
        else if passwordTextField.text! == "" {
            errorMessage = "Please enter a password."
        }
        else if confirmPasswordTextField.text! == "" {
            errorMessage = "Please confirm your password."
        }
        else if passwordTextField.text! != confirmPasswordTextField.text! {
            errorMessage = "Passwords do not match."
        }
        
        if let message = errorMessage {
            
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let closeAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
            alert.addAction(closeAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        
        
        // Create blur view
        
        _blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
        _blurView!.frame = view.bounds
        
        // Add the ability to cancel the login attempt
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: "cancelAccountCreationAttempt")
        _blurView!.addGestureRecognizer(tapGesture)
        
        // Add the activity spinner
        
        let spinner = UIActivityIndicatorView()
        spinner.center = _blurView!.center
        spinner.startAnimating()
        spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        _blurView?.contentView.addSubview(spinner)
        
        // Add the blur view to the main view
        
        view.addSubview(_blurView!)
        
        
        // Restrict autorotation since I don't want to set constraints for the blur view
        
        _allowAutorotation = false
        
        
        // TODO: add error checking...
        _newAccountManager = NewAccountManager(firstName: self.firstNameTextField.text!, lastName: self.lastNameTextField.text!, email: self.emailTextField.text!, password: self.passwordTextField.text!)
        
        _newAccountManager!.delegate = self
        
        _newAccountManager!.attemptToCreateNewAccount()
    }
    
    
    // MARK: NewAccountManagerDelegate Methods
    
    func accountCreationDidSucceed(didSucceed: Bool, message: String) {
        print("Received response from server: \(didSucceed)")
        
        cancelAccountCreationAttempt()
        
        if didSucceed {
            
            let alert = UIAlertController(title: "Success", message: "New account added. Please log in with your new username and password.", preferredStyle: UIAlertControllerStyle.Alert)
            let closeAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: {Void in
                self.backToLogInPage(nil)
            })
            
            alert.addAction(closeAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
            
        else {
            
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let closeAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
            
            alert.addAction(closeAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
        
    }

    // MARK: UITextFieldDelegate Methods
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeLeft || UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeRight {
            scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height + 162)
        }
        else {
            scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height + 216)
        }
        _isKeyboardOnScreen = true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeLeft || UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeRight {
            scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height - 162)
        }
        else {
            scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height - 216)
        }
        _isKeyboardOnScreen = false
    }
    



}
