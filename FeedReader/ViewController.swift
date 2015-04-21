//
//  ViewController.swift
//  FeedReader
//
//  Created by praveen on 4/13/15.
//  Copyright (c) 2015 NYU. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource , UITableViewDelegate  {
    
    let PostCellIdentifier = "PostCell"
    let ShowBrowserIdentifier = "ShowBrowser"
    let PullToRefreshString = "Pull to Refresh"
    let ReadTextColor = UIColor(red: 0.467, green: 0.467, blue: 0.467, alpha: 1.0)
    let ReadDetailTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
    let FetchErrorMessage = "Could Not Fetch Posts"
    let NoPostsErrorMessage = "No More Posts to Fetch"
    let ErrorMessageLabelTextColor = UIColor.grayColor()
    let ErrorMessageFontSize: CGFloat = 16
    let DefaultPostFilterType = PostFilterType.Top
    
    var postFilter: PostFilterType!
    var techFeeds: [HNPost]!
    var nextPageId: String!
    var scrolledToBottom: Bool!
    var refreshControl: UIRefreshControl!
    var errorMessageLabel: UILabel!
    var toolbarBarButtonItems: [UIBarButtonItem]?
    
    @IBOutlet weak var webView: UIWebView!

    
    @IBOutlet weak var postsTableView: UITableView!
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        postFilter = DefaultPostFilterType
        techFeeds = []
        nextPageId = ""
        scrolledToBottom = false
        refreshControl = UIRefreshControl()
        toolbarBarButtonItems = toolbarItems as? [UIBarButtonItem]
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchPosts()
        loadUrl()
    }
    
    // MARK: Functions
    
    func configureUI() {
        refreshControl.addTarget(self, action: "fetchPosts", forControlEvents: .ValueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: PullToRefreshString)
        postsTableView.insertSubview(refreshControl, atIndex: 0)
        
        // Have to initialize this UILabel here because the view does not exist in init() yet.
        errorMessageLabel = UILabel(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
        errorMessageLabel.textColor = ErrorMessageLabelTextColor
        errorMessageLabel.textAlignment = .Center
        errorMessageLabel.font = UIFont.systemFontOfSize(ErrorMessageFontSize)
    }
    
    func fetchPosts() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let postUrlAddition = HNManager.sharedManager().postUrlAddition
        if !scrolledToBottom {
            HNManager.sharedManager().loadPostsWithFilter(postFilter, completion: { posts, _ in
                if posts != nil && posts.count > 0 {
                    self.techFeeds = posts as [HNPost]
                    dispatch_async(dispatch_get_main_queue(), {
                        self.postsTableView.separatorStyle = .SingleLine
                        self.postsTableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
                        self.postsTableView.reloadData()
                        self.refreshControl.endRefreshing()
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    })
                } else {
                    self.techFeeds = []
                    self.postsTableView.reloadData()
                    if posts == nil {
                        self.showErrorMessage(self.FetchErrorMessage)
                    } else {
                        self.showErrorMessage(self.NoPostsErrorMessage)
                    }
                    self.scrolledToBottom = false
                    self.refreshControl.endRefreshing()
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            })
        } else if postUrlAddition != nil {
            HNManager.sharedManager().loadPostsWithUrlAddition(postUrlAddition, completion: { posts, _ in
                if posts != nil && posts.count > 0 {
                    self.techFeeds.extend(posts as [HNPost])
                    dispatch_async(dispatch_get_main_queue(), {
                        self.postsTableView.separatorStyle = .SingleLine
                        self.postsTableView.reloadData()
                        self.postsTableView.flashScrollIndicators()
                        self.scrolledToBottom = false
                        self.refreshControl.endRefreshing()
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    })
                } else {
                    self.techFeeds = []
                    self.postsTableView.reloadData()
                    if posts == nil {
                        self.showErrorMessage(self.FetchErrorMessage)
                    } else {
                        self.showErrorMessage(self.NoPostsErrorMessage)
                    }
                    self.scrolledToBottom = false
                    self.refreshControl.endRefreshing()
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            })
        }
    }
    
    func showErrorMessage(message: String) {
        errorMessageLabel.text = message
        self.postsTableView.backgroundView = errorMessageLabel
        self.postsTableView.separatorStyle = .None
    }
    
    func stylePostCellAsRead(cell: UITableViewCell) {
        cell.textLabel.textColor = ReadTextColor
        cell.detailTextLabel?.textColor = ReadDetailTextColor
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return techFeeds.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
       var cell = tableView.dequeueReusableCellWithIdentifier(PostCellIdentifier) as UITableViewCell
        //let cell = tableView.dequeueReusableCellWithIdentifier("PostCell" , forIndexPath: indexPath) as UITableViewCell
                let post = techFeeds[indexPath.row]
        
                if HNManager.sharedManager().hasUserReadPost(post) {
                    stylePostCellAsRead(cell)
                }
        
                cell.textLabel.text = post.Title
                cell.detailTextLabel?.text = "\(post.Points) points by \(post.Username)"
                
                return cell
    }
    
    // MARK: UITableViewDelegate
    
    func loadUrl(feed:HNPost) {
        if techFeeds.count>0 {
            let url = NSURL(string: feed.UrlString)
            let request = NSURLRequest(URL: url!)
            webView.loadRequest(request)
        }
    }
    
    func loadUrl() {
        //if techFeeds.count>0 {
            let url = NSURL(string: "www.google.com")
            let request = NSURLRequest(URL: url!)
            webView.loadRequest(request)
        //}
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let feed = techFeeds[indexPath.row]
        HNManager.sharedManager().setMarkAsReadForPost(feed)
        //webView.post = feed
        loadUrl(feed)
    }
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        
        let reloadDistance: CGFloat = 10
        if y > h + reloadDistance && !scrolledToBottom && techFeeds.count > 0 {
            scrolledToBottom = true
            fetchPosts()
        }
    }
    
    @IBAction func changePostFilter(sender: UISegmentedControl) {
        HNManager.sharedManager().postUrlAddition = nil
        
        if sender.selectedSegmentIndex == 0 {
            postFilter = .Top
        } else if sender.selectedSegmentIndex == 1 {
            postFilter = .New
        } else if sender.selectedSegmentIndex == 2 {
            postFilter = .Jobs
        } else {
            println("Bad segment index!")
        }
        
        fetchPosts()
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        toolbarBarButtonItems?[0].enabled = webView.canGoBack
        toolbarBarButtonItems?[2].enabled = webView.canGoForward
    }
    
    @IBAction func doRefresh(AnyObject) {
        webView.reload()
    }
    
    @IBAction func goBack(AnyObject) {
        webView.goBack()
    }
    
    @IBAction func goForward(AnyObject) {
        webView.goForward()
    }
    
    @IBAction func stop(AnyObject) {
        webView.stopLoading()
    }
    
}


