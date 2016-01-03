//
//  ViewController.swift
//  hasjob
//
//  Created by Ankit Goel on 29/11/15.
//  Copyright © 2015 ankitgoel. All rights reserved.
//

import UIKit
import SwiftHTTP
import Kanna

struct Stickie {
    var headline: String = ""
    var location: String = ""
    var date: String = ""
    var company: String = ""
    var detailURL: String = ""
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    var posts: [Stickie] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var noJobsFoundLabel: UILabel!
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    @IBAction func searchButtonPressed() {
        searchBar.resignFirstResponder()
        if searchBar.text == "" {
            getJobs()
        } else {
            getJobs(searchBar.text!)
        }
    }
    
    @IBAction func clearButtonPressed() {
        self.searchBar.resignFirstResponder()
        if searchBar.text != "" {
            searchBar.text = ""
            getJobs()
        }
    }
    
    @IBAction func tryAgainButtonPressed() {
        if searchBar.text == "" {
            getJobs()
        } else {
            getJobs(searchBar.text!)
        }
    }
    
    // MARK:- Controller Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Hide no jobs found label
        self.noJobsFoundLabel.hidden = true
        self.tryAgainButton.hidden = true
        
        // Don't show empty cell in tableview by adding footer
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor(red: 207/255, green: 208/255, blue: 213/255, alpha: 1.0)
        
        searchButton.layer.cornerRadius = 10
        clearButton.layer.cornerRadius = 10
        
        // Send request
        getJobs()
    }
    
    // MARK:- Web Requests
    func getJobs(keyword: String = "") {
        // Show loading indicator
        self.view.makeToastActivity(.Center)
        self.view.userInteractionEnabled = false
        
        var url = "https://hasjob.co/"
        // Add parameter if keyword added
        if keyword != "" {
            url = url + "?q=\(keyword.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!)"
        }
        
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
                dispatch_async(dispatch_get_main_queue()) {
                    self.view.makeToast(response.error!.localizedDescription, duration: 3.0, position: .Center)
                    if self.posts.count == 0 {
                        self.tryAgainButton.hidden = false
                    }
                }
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.tryAgainButton.hidden = true
                self.parseHTML(String(data: response.data, encoding: NSUTF8StringEncoding)!)
            }
        }
    }
    
    // MARK:- Parse HTML
    func parseHTML(HTMLString: String) {
        if let doc = Kanna.HTML(html: HTMLString, encoding: NSUTF8StringEncoding) {
            posts = []
            
            for link in doc.xpath("//a[@class='stickie']") {
                var post = Stickie()
                post.detailURL = link["href"]!
                // Fix for grouped stickie posts
                if link["href"]!.componentsSeparatedByString("/").count == 2 {
                    post.detailURL = link["data-href"]!
                }
                post.headline = link.css("span[class=\"headline\"]").text!
                post.date = link.css("span[class=\"annotation top-right\"]").text!
                post.company = link.css("span[class=\"annotation bottom-right\"]").text!
                post.location = link.css("span[class=\"annotation top-left\"]").text!
                
                posts.append(post)
                
            }
            // reload table view
            dispatch_async(dispatch_get_main_queue()){
                self.tableView.reloadData()
                if self.searchBar.text! != "" && self.posts.count == 0 {
                    self.noJobsFoundLabel.hidden = false
                    self.noJobsFoundLabel.text = "No jobs found matching the keyword '\(self.searchBar.text!)'"
                } else {
                    self.noJobsFoundLabel.hidden = true
                }
            }
        }
    }
    
    // MARK:- TextField Delegate methods
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        searchBar.resignFirstResponder()
        if textField.text == "" {
            self.view.makeToast("Enter keyword to search", duration: 3.0, position: .Center)
        } else {
            getJobs(searchBar.text!)
        }
        return true
    }
    
    // MARK:- Table view data source & delegate methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("hasjobCell") as! HasjobTableViewCell
        cell.dateLabel.text = posts[indexPath.row].date
        cell.locationLabel.text = posts[indexPath.row].location
        cell.companyLabel.text = posts[indexPath.row].company
        cell.headlineLabel.text = posts[indexPath.row].headline
        return cell
    }
    
    // Hide keyboard when table scrolled
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if scrollView.isEqual(tableView) {
            searchBar.resignFirstResponder()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK:- Prepare for segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "detail" {
            let cell = sender as! HasjobTableViewCell
            let indexPath = tableView.indexPathForCell(cell)
            
            let detailVC = segue.destinationViewController as! DetailViewController
            detailVC.url = "https://hasjob.co/\(posts[indexPath!.row].detailURL)"
        }
    }
}

