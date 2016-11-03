//
//  WebModeViewController.swift
//  ObixTestDemo
//
//  Created by wangyuanyuan on 02/11/2016.
//  Copyright © 2016 wangyuanyuan. All rights reserved.
//

import UIKit

import Alamofire
import AEXML

class WebModeViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate{

    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var refreshBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var backBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var responseTableView: UITableView!
    var responseTableViewArray: [String] = []
    
    var baseURL = ""
    
    @IBOutlet weak var parameterTextView: UITextView!
    @IBOutlet weak var responseTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        urlTextField.delegate = self
        responseTableView.dataSource = self
        responseTableView.delegate = self
        
        baseURL = urlTextField.text!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return responseTableViewArray.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "REUSEID", for: indexPath)
        cell.textLabel?.text = responseTableViewArray[indexPath.row]
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            self.urlTextField.text = self.responseTableViewArray[indexPath.row]
        } else {
            self.urlTextField.text = self.URLPiece(self.baseURL, withUrl: self.responseTableViewArray[indexPath.row])
        }
        
        RequestByGetWithoutParameters()
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        RequestByGetWithoutParameters()

        return true
    }
    
    @IBAction func backAction(_ sender: AnyObject) {
        var url = urlTextField.text!
        if url.hasSuffix("/") {
            url.remove(at: url.index(before: url.endIndex))
        }
        
        while url.characters.count>0 && !url.hasSuffix("/") {
            url.remove(at: url.index(before: url.endIndex))
        }
        
        urlTextField.text = url
        RequestByGetWithoutParameters()
    }
    
    
    @IBAction func refreshAction(_ sender: AnyObject) {
        RequestByGetWithoutParameters()
    }
    
    @IBAction func postButtonAction(_ sender: AnyObject) {
        PostValue()
    }
    
    @IBAction func watchButtonAction(_ sender: AnyObject) {
        let parameters = parameterTextView.text!
        parameterTextView.text = ""
        PostValue()
        
        parameterTextView.text = parameters
        PostValue()
        
    }
    
    
    // MARK: Personal Functions
    func RequestByGetWithoutParameters() {
        Alamofire.request(urlTextField.text!, headers: PublicStaticVar.getHeaders()).responseData { (response) in
            self.baseURL = self.urlTextField.text!
            if let data = response.data {
                do {
                    let xmlDoc = try AEXMLDocument(xml: data)
                    
                    self.responseTextView.text = xmlDoc.xml
                    
                    self.responseTableViewArray.removeAll()
                    
                    if let href = xmlDoc.root.attributes["href"] {
                        self.responseTableViewArray.append(href.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                    } else if let val = xmlDoc.root.attributes["val"] {
                        self.responseTableViewArray.append("Value = " + val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                    }
                    if xmlDoc.root.children.count > 0 {
                        for element in xmlDoc.root.children {
                            if let href = element.attributes["href"] {
                                self.responseTableViewArray.append(href.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                            } else if let val = element.attributes["val"] {
                                self.responseTableViewArray.append("Value = " + val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                            }
                        }
                    }
                    self.responseTableView.reloadData()
                    
                } catch {
                    PublicStaticVar.ShowAlert(atViewController: self, withMsg: "\(error)")
                }
            }
        }
        
    }
    
    func URLPiece(_ urlMain: String, withUrl: String) -> String {
        var resultURL = urlMain
        var suffix = withUrl
        
        if withUrl.hasPrefix("http") {
            return withUrl
        }
        if !resultURL.hasSuffix("/") {
            resultURL += "/"
        }
        if !suffix.hasSuffix("/") {
            suffix += "/"
        }
        
        if suffix.characters[suffix.startIndex] == "/" {
            suffix.remove(at: withUrl.startIndex)
            suffix = suffix.substring(from: suffix.characters.index(of: "/")!)
            suffix.remove(at: withUrl.startIndex)
        }
        
        resultURL += suffix
        return resultURL
    }
    
    func PostValue() {
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
            "POST_PARAMETER": parameterTextView.text
        ]
        Alamofire.request(urlTextField.text!, method: .post, parameters: parameters, encoding: CustomXMLEncoding(), headers: PublicStaticVar.getHeaders()).responseData(completionHandler: { (response) in
            if let data = response.data {
                // AEXML
                do {
                    let xmlDoc = try AEXMLDocument(xml: data)
                    
                    self.responseTextView.text = xmlDoc.xml
                    
                    self.responseTableViewArray.removeAll()
                    
                    if let href = xmlDoc.root.attributes["href"] {
                        self.responseTableViewArray.append(href.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                    } else if let val = xmlDoc.root.attributes["val"] {
                        self.responseTableViewArray.append("Value = " + val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                    }
                    if xmlDoc.root.children.count > 0 {
                        for element in xmlDoc.root.children {
                            if let href = element.attributes["href"] {
                                self.responseTableViewArray.append(href.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                            } else if let val = element.attributes["val"] {
                                self.responseTableViewArray.append("Value = " + val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                            }
                        }
                    }
                    self.responseTableView.reloadData()
                    
                } catch {
                    PublicStaticVar.ShowAlert(atViewController: self, withMsg: "\(error)")
                }
            }
        })
    }
}
