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
            
            if let tags = photo.tags {
                var tagsString = ""
                
                for tag in tags {
                    let t = tag as! Tag
                    tagsString += "#\(t.name!) "
                }
                tagsLabel.text = tagsString
            }
        }
    }
}
