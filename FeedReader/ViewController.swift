//
//  ViewController.swift
//  FeedReader
//
//  Created by praveen on 4/13/15.
//  Copyright (c) 2015 NYU. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
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
    var posts: [HNPost]!
    var nextPageId: String!
    var scrolledToBottom: Bool!
    var refreshControl: UIRefreshControl!
    var errorMessageLabel: UILabel!

    
    @IBOutlet weak var postsTableView: UITableView!
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        postFilter = DefaultPostFilterType
        posts = []
        nextPageId = ""
        scrolledToBottom = false
        refreshControl = UIRefreshControl()
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchPosts()
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
                    self.posts = posts as [HNPost]
                    dispatch_async(dispatch_get_main_queue(), {
                        self.postsTableView.separatorStyle = .SingleLine
                        self.postsTableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
                        self.postsTableView.reloadData()
                        self.refreshControl.endRefreshing()
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    })
                } else {
                    self.posts = []
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
                    self.posts.extend(posts as [HNPost])
                    dispatch_async(dispatch_get_main_queue(), {
                        self.postsTableView.separatorStyle = .SingleLine
                        self.postsTableView.reloadData()
                        self.postsTableView.flashScrollIndicators()
                        self.scrolledToBottom = false
                        self.refreshControl.endRefreshing()
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    })
                } else {
                    self.posts = []
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
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PostCellIdentifier) as UITableViewCell
        
        let post = posts[indexPath.row]
        
        if HNManager.sharedManager().hasUserReadPost(post) {
            stylePostCellAsRead(cell)
        }
        
        cell.textLabel.text = post.Title
        cell.detailTextLabel?.text = "\(post.Points) points by \(post.Username)"
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        
        let reloadDistance: CGFloat = 10
        if y > h + reloadDistance && !scrolledToBottom && posts.count > 0 {
            scrolledToBottom = true
            fetchPosts()
        }
    }
    
    // MARK: UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
//        if segue.identifier == ShowBrowserIdentifier {
//            let webView = segue.destinationViewController.childViewControllers[0] as BrowserViewController
//            let cell = sender as UITableViewCell
//            let post = posts[postsTableView.indexPathForSelectedRow()!.row]
//            
//            HNManager.sharedManager().setMarkAsReadForPost(post)
//            stylePostCellAsRead(cell)
//            
//            webView.post = post
//        }
    }
    
    // MARK: IBActions
    
    @IBAction func changePostFilter(sender: UISegmentedControl) {
        HNManager.sharedManager().postUrlAddition = nil
        
        if sender.selectedSegmentIndex == 0 {
            postFilter = .Top
        } else if sender.selectedSegmentIndex == 1 {
            postFilter = .New
        } else if sender.selectedSegmentIndex == 2 {
            postFilter = .Ask
        } else {
            println("Bad segment index!")
        }
        
        fetchPosts()
    }
    
    
    let devCourses = [
        ("iOS App Dev with Swift Essential Training","Simon Allardice"),
        ("iOS 8 SDK New Features","Lee Brimelow"),
        ("Data Visualization with D3.js","Ray Villalobos"),
        ("Swift Essential Training","Simon Allardice"),
        ("Up and Running with AngularJS","Ray Villalobos"),
        ("MySQL Essential Training","Bill Weinman"),
        ("Building Adaptive Android Apps with Fragments","David Gassner"),
        ("Advanced Unity 3D Game Programming","Michael House"),
        ("Up and Running with Ubuntu Desktop Linux","Scott Simpson"),
        ("Up and Running with C","Dan Gookin") ]
    
    let webCourses = [
        ("HTML Essential Training","James Williamson"),
        ("Building a Responsive Single-Page Design","Ray Villalobos"),
        ("Muse Essential Training","Justin Seeley"),
        ("WordPress Essential Training","Morten Rand-Hendriksen"),
        ("Installing and Running Joomla! 3: Local and Web-Hosted Sites","Jen Kramer"),
        ("Managing Records in SharePoint","Toni Saddler-French"),
        ("Design the Web: SVG Rollovers with CSS","Chris Converse"),
        ("Up and Running with Ember.js","Kai Gittens"),
        ("HTML5 Game Development with Phaser","Joseph Labrecque"),
        ("Responsive Media","Christopher Schmitt") ]
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return devCourses.count
        } else {
            return webCourses.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        if indexPath.section == 0 {
            let (courseTitle,courseAuthor) = devCourses[indexPath.row]
            cell.textLabel?.text = courseTitle
            cell.detailTextLabel?.text = courseAuthor
        } else {
            let (courseTitle,courseAuthor) = webCourses[indexPath.row]
            cell.textLabel?.text = courseTitle
            cell.detailTextLabel?.text = courseAuthor
        }
        
        // Retrieve an image
        var myImage = UIImage(named: "CellIcon")
        cell.imageView?.image = myImage
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Developer Courses"
        } else {
            return "Web Courses"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
}

