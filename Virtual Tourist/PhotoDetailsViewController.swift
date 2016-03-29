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
            if let fullPath = photo.fullPath {
                photoView.image = UIImage(contentsOfFile: fullPath)
            }
            
            if let title = photo.title {
                navigationItem.title = title
            }
            
            var string = ""
            
            if let description_ = photo.description_ {
                string = "\(description_)\n\n"
            }
            
            if let tags = photo.tags {
                for tag in tags {
                    let t = tag as! Tag
                    string += "#\(t.name!) "
                }
            }
            
            tagsLabel.text = string
        }
    }
}
