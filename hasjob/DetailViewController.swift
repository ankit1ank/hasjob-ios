//
//  DetailViewController.swift
//  hasjob
//
//  Created by Ankit Goel on 20/12/15.
//  Copyright © 2015 ankitgoel. All rights reserved.
//

import UIKit
import SwiftHTTP
import Kanna

class DetailViewController: UIViewController {

    var url = ""
    
    @IBOutlet weak var descriptionTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Details"
        getJob()
    }
    
    // MARK:- Web Requests
    func getJob(keyword: String = "") {
        // Show loading indicator
        self.view.makeToastActivity(.Center)
        self.view.userInteractionEnabled = false
        
        let req = try! HTTP.GET(url)
        req.start { response in
            
            // Hide toast when data fetched
            defer {
                dispatch_async(dispatch_get_main_queue()) {
                    self.view.hideToastActivity()
                    self.view.userInteractionEnabled = true
                }
            }
            
            guard response.error == nil else {
                self.view.makeToast(response.error!.localizedDescription, duration: 3.0, position: .Center)
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.parseHTML(String(data: response.data, encoding: NSUTF8StringEncoding)!)
            }
        }
    }
    
    // MARK:- Parse HTML
    func parseHTML(HTMLString: String) {
        if let doc = Kanna.HTML(html: HTMLString, encoding: NSUTF8StringEncoding) {
            let link = doc.xpath("//div[@itemprop='articleBody']")
            // This removes space and also fixes job perks alignment in text
            let strippedText = link.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).stringByReplacingOccurrencesOfString("            ", withString: "")
            
            descriptionTextView.text = strippedText
                
        }
    }

}
