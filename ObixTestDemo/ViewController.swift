//
//  ViewController.swift
//  ObixTestDemo
//
//  Created by wangyuanyuan on 26/10/2016.
//  Copyright © 2016 wangyuanyuan. All rights reserved.
//

import UIKit

import Alamofire
import AEXML

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var textFieldURL: UITextField!
    @IBOutlet weak var tableViewShow: UITableView!
    @IBOutlet weak var pickerViewChoose: UIPickerView!
    @IBOutlet weak var parameterTextField: UITextField!
    @IBOutlet weak var MsgShowPanel: UITextView!
    
    let username="admin", password="test12345"
    var headers: HTTPHeaders = [:]       // HTTP Basic Authorization
    
    var baseURL = ""
    
    var tableViewDataArray: [String] = []
    
    var pickerViewMethodDataArray = [
        "GET", "POST"
    ]
    var pickerViewTypeDataArray = [
        "String", "Numeric", "Enum", "Boolean"
    ]
    var pickerViewDataArray: [[String]] = [[String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        textFieldURL.delegate = self
        parameterTextField.delegate = self
        
        tableViewShow.dataSource = self
        tableViewShow.delegate = self
        pickerViewChoose.delegate = self
        
        pickerViewDataArray.append(pickerViewMethodDataArray)
        pickerViewDataArray.append(pickerViewTypeDataArray)
        
        // HTTP Basic Authorization
        if let authorizationHeader = Request.authorizationHeader(user: self.username, password: self.password) {
            headers[authorizationHeader.key] = authorizationHeader.value
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        self.baseURL = textField.text!
        
        switch textField.restorationIdentifier! {
        case "URLID":
            GetFromURL()
        case "VALUEID":
            PostValue()
        default:
            self.ShowAlert(withMsg: "textFieldShouldReturn: Something Wrong!")
        }
        
        return true
    }
    
    func GetFromURL() {
        guard let url = self.textFieldURL.text, !url.isEmpty else {
            ShowAlert(withMsg: "Something Wrong with URL!")
            return
        }
        
        Alamofire.request(url, headers: headers).responseData { (response) in
            if let data = response.data {
                //AEXML
                do {
                    let xmlDoc = try AEXMLDocument(xml: data)
                    self.MsgShowPanel.text = xmlDoc.xml
                    
                    self.tableViewDataArray.removeAll()
                    if xmlDoc.children.count > 0 {
                        let children = xmlDoc.root.children
                        for child in children {
                            //self.tableViewDataArray.append("<\(child.name) name=\""+child.attributes["name"]!+"\" />")
                            self.tableViewDataArray.append(child.xml.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                        }
                    } else {
                        self.tableViewDataArray.append(xmlDoc.xml.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                    }
                    self.tableViewShow.reloadData()
                } catch {
                    self.ShowAlert(withMsg: "AEXML Parser XML Error:\(error)")
                }
            } else {
                self.ShowAlert(withMsg: "Alamofire:\(response.result.error)")
            }
        }
    }

    func PostValue() {
        
        guard let url = self.textFieldURL.text, !url.isEmpty else {
            ShowAlert(withMsg: "Something Wrong with URL!")
            return
        }
        
        guard let value = parameterTextField.text else {
            ShowAlert(withMsg: "Something Wrong with Parameters!")
            return
        }
        
        
        struct CustomXMLEncoding: ParameterEncoding {
            func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
                var urlRequest = try urlRequest.asURLRequest()
                guard let parameters = parameters else { return urlRequest }
                
                let xmlString = parameters["POST_PARAMETER"] as! String
                
                let data = xmlString.data(using: String.Encoding.utf8)
                
                //let data = try JSONSerialization.data(withJSONObject: parameters)
                
                if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                    urlRequest.setValue("application/xml", forHTTPHeaderField: "Content-Type")
                }
                
                urlRequest.httpBody = data
                
                return urlRequest
            }
        }
        
        let parameters = [
            "POST_PARAMETER": value
        ]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: CustomXMLEncoding(), headers: headers).responseData(completionHandler: { (response) in
            if let data = response.data {
                // AEXML
                do {
                    let xmlDoc = try AEXMLDocument(xml: data)
                    self.MsgShowPanel.text = xmlDoc.xml
                } catch {
                    self.MsgShowPanel.text = "\(error)"
                }
            }
        })
    }

    // MARK: UITableViewDataSource
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewDataArray.count
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "REUSEID", for: indexPath)
        cell.textLabel?.text = self.tableViewDataArray[indexPath.row]
        return cell
    }
    
    // MARK: UIPickerViewDataSource
    // returns the number of 'columns' to display.
    @available(iOS 2.0, *)
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerViewDataArray.count
    }
    
    // returns the # of rows in each component..
    @available(iOS 2.0, *)
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerViewDataArray[component].count
    }
    // MARK: UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerViewDataArray[component][row]
    }
    
    // MARK: AlertController
    func ShowAlert(withMsg: String) {
        let alertController = UIAlertController(title: "Attation", message: withMsg, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(alertAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableViewShow.deselectRow(at: indexPath, animated: true)
        MsgShowPanel.text = tableViewShow.cellForRow(at: indexPath)?.textLabel?.text
        
        let data = tableViewShow.cellForRow(at: indexPath)?.textLabel?.text?.data(using: String.Encoding.utf8)

        // AEXML
        do {
            let xmlDoc = try AEXMLDocument(xml: data!)
            if let attr = xmlDoc.root.attributes["href"] {
                print(textFieldURL.text!.trimmingCharacters(in: ["/"]) + "/" + attr.trimmingCharacters(in: ["/"]))
                textFieldURL.text = self.baseURL.trimmingCharacters(in: ["/"]) + "/" + attr.trimmingCharacters(in: ["/"])
            }
            
            if let attr = xmlDoc.root.attributes["val"] {
                self.MsgShowPanel.text = "Value: \(attr) \n-----------\n" + self.MsgShowPanel.text
            }
        } catch {
            self.MsgShowPanel.text = "\(error)"
        }
    }
}

