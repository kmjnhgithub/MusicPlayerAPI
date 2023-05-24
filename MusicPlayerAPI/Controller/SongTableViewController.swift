//
//  SongTableViewController.swift
//  MusicPlayerAPI
//
//  Created by mike liu on 2023/5/24.
//

import UIKit
import Kingfisher


class SongTableViewController: UITableViewController {
    
    var items = [StoreItem]()
    let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.center = CGPoint(x: self.view.center.x, y: self.view.bounds.height / 3)
        self.view.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
        
        fetchItems()

    }
    @IBSegueAction func showDetail(_ coder: NSCoder) -> ItemDetailViewController? {
        if let row = tableView.indexPathForSelectedRow?.row {
            let controller = ItemDetailViewController(coder: coder)
            controller?.items = items
            controller?.position = row
            return controller
        } else {
            return nil
        }
    }
    
    func fetchItems() {
        let urlStr = "https://itunes.apple.com/search?term=Apathy&media=music&country=tw"
        if let url = URL(string: urlStr) {
            URLSession.shared.dataTask(with: url) { data, response , error in
                if let data {
                    let decoder = JSONDecoder()
                    do {
                        let searchResponse = try decoder.decode(SearchResponse.self, from: data)
                        self.items = searchResponse.results
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.activityIndicator.stopAnimating()
                        }
                    
                    } catch {
                        print(error)
                        // show error alert
                    }
                    // show error alert
                }
            }.resume()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(ItemTableViewCell.self)", for: indexPath) as! ItemTableViewCell

        // Configure the cell...
        let item = items[indexPath.row]
        
        cell.songName.text = item.trackName
        cell.nameLabel.text = item.artistName
        cell.photoImage.kf.setImage(with: item.artworkUrl100, placeholder: UIImage(systemName: "music.note"))
        
        
        // 設定cell的字體與大小
        cell.songName?.font = UIFont(name: "Helvetica-Bold", size: 18)
        cell.nameLabel?.font = UIFont(name: "Helvetica", size: 16)
        

        return cell
    }
    
}
