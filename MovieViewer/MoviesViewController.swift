//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Anastasia Blodgett on 10/13/16.
//  Copyright © 2016 Anastasia Blodgett. All rights reserved.
//
import AFNetworking
import UIKit
import AASquaresLoading

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var movies: [NSDictionary]?
    var endpoint: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        self.showRefreshControl()
    }
    
    fileprivate func showNetworkError() -> UIView {
        let networkErrorView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 120))
        networkErrorView.backgroundColor = UIColor.black
        networkErrorView.alpha = 0.9
        
        let errorLabel = UILabel(frame: CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y+80, width: self.view.frame.size.width, height: 30))
        errorLabel.textColor = UIColor.white
        errorLabel.textAlignment = .center
        errorLabel.text = "Network Error"
        networkErrorView.addSubview(errorLabel)
        return networkErrorView
    }
    
    fileprivate func showRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
        self.refreshControlAction(refreshControl: refreshControl)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let movies = movies {
            return movies.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieCell", for: indexPath) as! MovieTableViewCell
        
        let movie = movies?[indexPath.row]
        let title = movie?["title"] as! String
        let overview = movie?["overview"] as! String
        
        let basePosterURL = "https://image.tmdb.org/t/p/w500/"
        if let posterPath = movie?["poster_path"] as? String {
            let imageURL = URL(string: basePosterURL + posterPath)
            
            let imageRequest = URLRequest(url: imageURL!)
            cell.posterImageView.setImageWith(imageRequest,
                                              placeholderImage: nil,
                                              success: { (imageRequest, imageResponse, image) in
                                                
                                                if imageResponse != nil {
                                                    cell.posterImageView.alpha = 0
                                                    cell.posterImageView.image = image
                                                    UIView.animate(withDuration: 3.5, animations: {
                                                        cell.posterImageView.alpha = 1.0
                                                    })
                                                }
                                                else {
                                                    cell.posterImageView.image = image
                                                }
                }, failure: { (imageRequest, imageResponse, error) in
                    //TODO: show the default error for image "No Image"
                    cell.posterImageView.image = nil
            })
        }
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        return cell
    }
    
    @objc fileprivate func refreshControlAction(refreshControl: UIRefreshControl) {
        
        let start:TimeInterval = NSDate.timeIntervalSinceReferenceDate// timeIntervalSinceReferenceDate()
        self.view.squareLoading.start(0.0)
        self.view.squareLoading.setSquareSize(60)
        self.view.squareLoading.color = UIColor.orange
        
        let errorView = self.showNetworkError()
        errorView.isHidden = true
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string:"https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(with: request,completionHandler: { (dataOrNil, response, error) in
            let responseTime:TimeInterval = NSDate.timeIntervalSinceReferenceDate - start
        
            if let data = dataOrNil {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options:[]) as? NSDictionary {
                    
                    self.movies = responseDictionary["results"] as! [NSDictionary]
                    
                    self.tableView.reloadData()
                    refreshControl.endRefreshing()
                }
            }
            if (error != nil || responseTime > 3) {

                self.view.squareLoading.stop(3.0)
                
                errorView.isHidden = false
                self.view.addSubview(errorView)
            }
            else {
                self.view.squareLoading.stop(1.0)
            }
        });
        task.resume()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        let movie = movies?[(indexPath?.row)!]
        
        let detailViewController = segue.destination as! DetailsViewController
        detailViewController.movie = movie
        
    }
}
