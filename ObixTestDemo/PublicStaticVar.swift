//
//  PublicStaticVar.swift
//  ObixTestDemo
//
//  Created by wangyuanyuan on 02/11/2016.
//  Copyright © 2016 wangyuanyuan. All rights reserved.
//

import Foundation

import Alamofire

class PublicStaticVar {
    
    static let username = "admin"
    static let password = "test12345"
    static var headers: HTTPHeaders? = nil
    public static func getHeaders() -> HTTPHeaders? {
        // HTTP Basic Authorization
        if headers == nil {
            headers = [:]
            if let authorizationHeader = Request.authorizationHeader(user: self.username, password: self.password) {
                headers![authorizationHeader.key] = authorizationHeader.value
                return headers
            } else {
                return nil
            }
        } else {
            return headers
        }
    }
    
    
    public static func ShowAlert(atViewController: UIViewController, withMsg: String) {
        let alertController = UIAlertController(title: "Attation", message: withMsg, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(alertAction)
        atViewController.present(alertController, animated: true, completion: nil)
    }
}
