//
//  PhotosViewController.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/17/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


class PhotosViewController: UIViewController {

    // MARK: properties
    @IBOutlet weak var newButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    var region:MKCoordinateRegion?
    var pin:MKPointAnnotation?
    
    // MARK: Actions
    @IBAction func newButtonAction(sender: UIBarButtonItem) {
        
    }
    
    
    @IBAction func deleteButtonAction(sender: UIBarButtonItem) {
        
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPhotos()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mapView.setRegion(region!, animated: false)
        mapView.addAnnotation(pin!)
    }
    
    private func setupMap() {
        mapView.setRegion(region!, animated: false)
        mapView.addAnnotation(pin!)
    }
    
    private func setupPhotos() {
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2*space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
        
        collectionView.backgroundColor = UIColor.whiteColor()
    }
}
