//
//  WatchesViewController.swift
//  ObixTestDemo
//
//  Created by wangyuanyuan on 01/11/2016.
//  Copyright © 2016 wangyuanyuan. All rights reserved.
//

import UIKit
import Alamofire
import AEXML

class WatchesViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var responseTextView: UITextView!
    @IBOutlet weak var watchTableView: UITableView!
    @IBOutlet weak var parametersTextView: UITextView!
    
    let username="admin", password="test12345"
    var headers: HTTPHeaders = [:]       // HTTP Basic Authorization

    var watchesOpArray: [String] = []
    
    var isStop = false
    
    var urlCreateWatchObjext = ""
    var urlAddWatchPoint = ""
    var urlPollWatchChange=""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        urlTextField.delegate = self
        watchTableView.dataSource = self
        watchTableView.delegate = self
        
        // HTTP Basic Authorization
        if let authorizationHeader = Request.authorizationHeader(user: self.username, password: self.password) {
            headers[authorizationHeader.key] = authorizationHeader.value
        }
        
        urlCreateWatchObjext = urlTextField.text!
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

    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return watchesOpArray.count
    }
    
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "REUSEID", for: indexPath)
        
        cell.textLabel?.text = watchesOpArray[indexPath.row]
        
        return cell
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        CreateWatchObject()
        
        return true
    }
    
    func CreateWatchObject() {
        Alamofire.request(urlTextField.text!, method: .post, headers: headers).responseData(completionHandler: { (response) in
            if let data = response.data {
                // AEXML
                do {
                    let xmlDoc = try AEXMLDocument(xml: data)
                    
                    self.watchesOpArray.removeAll()
                    for ele in xmlDoc.root["op"].all! {
                        self.watchesOpArray.append(ele.attributes["name"]! + ":" + ele.attributes["href"]!)
                        
                        if ele.attributes["name"] == "add" {
                            self.urlAddWatchPoint = ele.attributes["href"]!
                        }
                        if ele.attributes["name"] == "pollChanges" {
                            self.urlPollWatchChange = ele.attributes["href"]!
                        }
                    }
                    self.watchTableView.reloadData()
                    
                    self.responseTextView.text = xmlDoc.xml
                } catch {
                    self.responseTextView.text = "\(error)"
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let urlText = watchesOpArray[indexPath.row]
        let url = urlText.substring(from: urlText.index(after: (urlText.characters.index(of: ":")!)))
        
        self.responseTextView.text = url
        self.urlTextField.text = url
    }
    
    @IBAction func PostAction(_ sender: AnyObject) {
        guard let url = self.urlTextField.text, !url.isEmpty else {
            ShowAlert(withMsg: "Something Wrong with URL!")
            return
        }
        guard let value = self.parametersTextView.text else {
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
                    self.responseTextView.text = xmlDoc.xml
                } catch {
                    self.responseTextView.text = "\(error)"
                }
            }
        })
    }
    
    
    func ShowAlert(withMsg: String) {
        let alertController = UIAlertController(title: "Attation", message: withMsg, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(alertAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func PollAction(_ sender: AnyObject) {
        
        DispatchQueue.global().async {
            while !self.isStop {
                Alamofire.request(self.urlPollWatchChange, method: .post, headers: self.headers).responseData(completionHandler: { (response) in
                    if let data = response.data {
                        // AEXML
                        do {
                            let xmlDoc = try AEXMLDocument(xml: data)
                            self.responseTextView.text = xmlDoc.xml
                        } catch {
                            self.responseTextView.text = "\(error)"
                        }
                    }
                })
                sleep(1)
            }
        }
    }
    
}
