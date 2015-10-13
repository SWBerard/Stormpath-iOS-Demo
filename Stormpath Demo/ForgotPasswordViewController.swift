//
//  ForgotPasswordViewController.swift
//  Stormpath Demo
//
//  Created by Steven Berard on 10/12/15.
//  Copyright © 2015 Byteware LLC. All rights reserved.
//

import UIKit

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate, ForgotPasswordManagerDelegate {
    
    @IBOutlet weak var windowView: UIView!
    @IBOutlet weak var resetPasswordButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var _blurView : UIVisualEffectView?
    var _allowAutorotation = true
    var _isKeyboardOnScreen = false
    var _forgotPasswordManager : ForgotPasswordManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        // WindowView setup
        windowView.layer.shadowRadius = 2.0
        windowView.layer.shadowOpacity = 0.5
        windowView.layer.shadowOffset = CGSize.init(width: 0.0, height: 0.0)
        windowView.layer.cornerRadius = 3
        
        
        // resetPasswordButton setup
        resetPasswordButton.backgroundColor = UIColor.clearColor()
        
        // Top half of button
        let topButtonLayer = CALayer()
        topButtonLayer.frame = CGRect(x: resetPasswordButton.bounds.origin.x, y: resetPasswordButton.bounds.origin.y, width: resetPasswordButton.bounds.width, height: resetPasswordButton.bounds.height/2)
        topButtonLayer.backgroundColor = UIColor(red: 0.0, green: 0.77, blue: 0.0, alpha: 1.0).CGColor
        resetPasswordButton.layer.insertSublayer(topButtonLayer, atIndex: 0)
        
        // Bottom half of button
        let bottomButtonLayer = CALayer()
        bottomButtonLayer.frame = CGRect(x: resetPasswordButton.bounds.origin.x, y: resetPasswordButton.bounds.origin.y + resetPasswordButton.bounds.height/2, width: resetPasswordButton.bounds.width, height: resetPasswordButton.bounds.height/2)
        bottomButtonLayer.backgroundColor = UIColor(red: 0.0, green: 0.73, blue: 0.0, alpha: 1.0).CGColor
        resetPasswordButton.layer.insertSublayer(bottomButtonLayer, atIndex: 0)
        
        // Rounding the corners
        let maskButtonLayer = CAShapeLayer()
        maskButtonLayer.frame = resetPasswordButton.bounds
        maskButtonLayer.backgroundColor = UIColor.whiteColor().CGColor
        maskButtonLayer.cornerRadius = 5
        
        resetPasswordButton.layer.mask = maskButtonLayer
        
        emailTextField.delegate = self
    }
    
    @IBAction func dismissKeyboard(sender: AnyObject?) {
        view.endEditing(true)
    }

    override func shouldAutorotate() -> Bool {
        return _allowAutorotation
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
    
    @IBAction func attemptToLogIn(sender: AnyObject?) {
        
        dismissKeyboard(nil)
        
        // Create blur view
        
        _blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
        _blurView!.frame = view.bounds
        
        // Add the ability to cancel the login attempt
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: "cancelPasswordResetAttempt")
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
        
        _forgotPasswordManager = ForgotPasswordManager(email: self.emailTextField.text!)
        
        _forgotPasswordManager!.delegate = self
        
        _forgotPasswordManager!.sendPasswordResetRequest()
    }

    
    func cancelPasswordResetAttempt() {
        if let bv = _blurView as UIVisualEffectView? {
            if let fPM = _forgotPasswordManager {
                fPM.cancelRequest()
            }
            bv.removeFromSuperview()
            _allowAutorotation = true
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    
    // MARK: ForgotPasswordManagerDelegate Methods
    
    func passwordResetDidSucceed(didSucceed: Bool, message: String) {

        print("Received response from server: \(didSucceed)")
        
        cancelPasswordResetAttempt()
        
        if didSucceed {
            
            let alert = UIAlertController(title: "Success", message: "Your password has been reset.  You should receive an email soon that will explain what to do next.", preferredStyle: UIAlertControllerStyle.Alert)
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
