//
//  LoginViewController.swift
//  Stormpath Demo
//
//  Created by Steven Berard on 10/10/15.
//  Copyright © 2015 Byteware LLC. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, LoginManagerDelegate, UITextFieldDelegate {

    @IBOutlet weak var windowView: UIView!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var _blurView : UIVisualEffectView?
    var _allowAutorotation = true
    var _isKeyboardOnScreen = false
    var _loginManager : LoginManager?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // WindowView setup
        windowView.layer.shadowRadius = 2.0
        windowView.layer.shadowOpacity = 0.5
        windowView.layer.shadowOffset = CGSize.init(width: 0.0, height: 0.0)
        windowView.layer.cornerRadius = 3
        
        
        // LogInButton setup
        logInButton.backgroundColor = UIColor.clearColor()
        
        // Top half of button
        let topButtonLayer = CALayer()
        topButtonLayer.frame = CGRect(x: logInButton.bounds.origin.x, y: logInButton.bounds.origin.y, width: logInButton.bounds.width, height: logInButton.bounds.height/2)
        topButtonLayer.backgroundColor = UIColor(red: 0.0, green: 0.77, blue: 0.0, alpha: 1.0).CGColor
        logInButton.layer.insertSublayer(topButtonLayer, atIndex: 0)
        
        // Bottom half of button
        let bottomButtonLayer = CALayer()
        bottomButtonLayer.frame = CGRect(x: logInButton.bounds.origin.x, y: logInButton.bounds.origin.y + logInButton.bounds.height/2, width: logInButton.bounds.width, height: logInButton.bounds.height/2)
        bottomButtonLayer.backgroundColor = UIColor(red: 0.0, green: 0.73, blue: 0.0, alpha: 1.0).CGColor
        logInButton.layer.insertSublayer(bottomButtonLayer, atIndex: 0)
        
        // Rounding the corners
        let maskButtonLayer = CAShapeLayer()
        maskButtonLayer.frame = logInButton.bounds
        maskButtonLayer.backgroundColor = UIColor.whiteColor().CGColor
        maskButtonLayer.cornerRadius = 5
        
        logInButton.layer.mask = maskButtonLayer
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text! = ""
        passwordTextField.text! = ""
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.navigationBarHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func cancelLogInAttempt() {
        if let bv = _blurView as UIVisualEffectView? {
            if let lm = _loginManager {
                lm.cancelAuthRequest()
            }
            bv.removeFromSuperview()
            _allowAutorotation = true
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return _allowAutorotation
    }

    @IBAction func dismissKeyboard(sender: AnyObject?) {
        view.endEditing(true)
    }
    
    @IBAction func attemptToLogIn(sender: AnyObject?) {
        
        dismissKeyboard(nil)
        
        // Create blur view
        
        _blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
        _blurView!.frame = view.bounds
        
        // Add the ability to cancel the login attempt
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: "cancelLogInAttempt")
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
        
        _loginManager = LoginManager(email: self.emailTextField.text!, password: self.passwordTextField.text!)
        
        _loginManager!.delegate = self
        
        _loginManager!.attemptToAuthenticateUser()
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
    
    // MARK: LoginManagerDelegate Methods
    
    func accountAuthorizationDidSucceed(didSucceed: Bool, message: String) {
        
        print("Received response from server: \(didSucceed)")
        
        cancelLogInAttempt()
        
        if didSucceed {
            
            if let storyboard = UIStoryboard(name: "Main", bundle: nil) as UIStoryboard? {
                if let successVC = storyboard.instantiateViewControllerWithIdentifier("SuccessViewController") as UIViewController? {
                    self.navigationController?.pushViewController(successVC, animated: true)
                    self.navigationController?.navigationBarHidden = false
                }
            }
        }
        
        else {
            
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let closeAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
            
            alert.addAction(closeAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
    }
    
    // MARK: UITextFieldDelegate Methods
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        dismissKeyboard(nil)
        attemptToLogIn(nil)
        
        return true
    }
    
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
