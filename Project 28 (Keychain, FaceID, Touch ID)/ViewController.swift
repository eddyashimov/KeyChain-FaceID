//
//  ViewController.swift
//  Project 28 (Keychain, FaceID, Touch ID)
//
//  Created by Edil Ashimov on 5/11/20.
//  Copyright © 2020 Edil Ashimov. All rights reserved.
//

import UIKit
import LocalAuthentication

enum GrantStatus {
    case isGranted
    case dontExist
    case incorrect
}

class ViewController: UIViewController {
    @IBOutlet var secret: UITextView!
    
    @IBOutlet var authenticate: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Nothing to see here"
        
        let notification = NotificationCenter.default
        notification.addObserver(self, selector: #selector(adjustForKeyboard(notication:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        notification.addObserver(self, selector: #selector(adjustForKeyboard(notication:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notification.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target:self, action: #selector(saveSecretMessage))
        
    }
    
    @objc func adjustForKeyboard(notication:NSNotification)  {
        guard let keyboardValue = notication.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {  return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notication.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        }
        secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    func unlockSecretMessage()  {
        secret.isHidden = false
        title = "Secret Stuff"
        
        if let text = KeychainWrapper.standard.string(forKey: "SecretMessage") {
            secret.text = text
        }
    }
    
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return }
        
        KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
        secret.resignFirstResponder()
        secret.isHidden = true
        title = "Nothing to See"
    }
    
    
    
    @IBAction func authenticateTapped(_ sender: Any) {
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            let reason = "Identify Yourself"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] (success, authenticationError) in
                DispatchQueue.main.async {
                    var ac = UIAlertController()
                    
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        
                        ac = UIAlertController(title: "Enter Password", message: "", preferredStyle: .alert)
                        ac.addTextField()
                        ac.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak self] _ in
                            guard let password = ac.textFields?[0].text else { return }
                            let grantStatus = self?.accessGranted(password)
                            
                            if grantStatus == GrantStatus.isGranted {
                                self?.unlockSecretMessage()
                                
                            } else if grantStatus == GrantStatus.dontExist {
                                ac.addTextField()
                                
                                if ac.textFields![1].text!.isEmpty {
                                    ac.title = "Enter you new password"
                                    ac.textFields![0].placeholder = "Enter Password"
                                    ac.textFields![1].placeholder = "Re-Enter Password"
                                    ac.textFields![1].delegate = self as? UITextFieldDelegate
                                    ac.textFields![0].selectedTextRange = ac.textFields![0].textRange(from: ac.textFields![0].beginningOfDocument, to: ac.textFields![0].endOfDocument)
                                    
                                    self?.dismiss(animated: false)
                                    self?.present(ac, animated: true)
                                    
                                } else if ac.textFields?[0].text == ac.textFields?[1].text {
                                    self?.createPassword(ac.textFields![0].text!)
                                    if self?.accessGranted(ac.textFields![0].text!) == GrantStatus.isGranted {
                                        self?.unlockSecretMessage()
                                    } else {
                                        
                                        self?.present(ac, animated: true)
                                        print("still no luck")
                                    }
                                    
                                }
                                
                            } else {
                                
                                ac.title = "Incorrect Passcode"
                                ac.textFields![0].becomeFirstResponder()
                                ac.textFields![0].selectedTextRange = ac.textFields![0].textRange(from: ac.textFields![0].beginningOfDocument, to: ac.textFields![0].endOfDocument)
                                self?.present(ac, animated: true)
                                
                                
                            }
                        }))
                        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        
                        self?.present(ac, animated: true)
                        
                    }
                }
            }
        } else {
            
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
            
        }
        
        
    }
    
    func accessGranted(_ password: String) -> GrantStatus {
        if let text = KeychainWrapper.standard.string(forKey: "password") {
            if text == password {
                return .isGranted
            } else if text != password {
                return .incorrect
            } else {
                return .dontExist
            }
        }
        
        
        return GrantStatus.dontExist
    }
    
    func createPassword(_ password: String) {
        KeychainWrapper.standard.set(password, forKey: "password")
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //highlights all text
        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
    }
    
}

