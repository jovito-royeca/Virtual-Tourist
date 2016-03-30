//
//  PhotoDetailsViewController.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/29/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit

class PhotoDetailsViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var tagsLabel: UILabel!
    
    // MARK: Variables
    var photo:Photo?
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        if let photo = photo {
            var titleString = ""
            var tagsString = ""
            
            if let fullPath = photo.fullPath {
                photoView.image = UIImage(contentsOfFile: fullPath)
            }
            
            if let title = photo.title {
                titleString = "\(title)\n"
            }
            if let owner = photo.owner {
                if let ownerName = owner.ownerName {
                    titleString += "By \(ownerName)"
                }
            }
            titleLabel.text = titleString
            
            if let description_ = photo.description_ {
                tagsString = "\(description_)\n\n"
            }
            
            if let tags = photo.tags {
                for tag in tags {
                    let t = tag as! Tag
                    tagsString += "#\(t.name!) "
                }
            }
            tagsLabel.text = tagsString
        }
    }
}
