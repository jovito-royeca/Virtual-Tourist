//
//  PhotosViewController.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/17/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit


class PhotosViewController: UIViewController, NSFetchedResultsControllerDelegate {

    // MARK: properties
    @IBOutlet weak var newButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    var region:MKCoordinateRegion?
    var annotation:MKPointAnnotation?
    var pin:Pin?
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "photoId", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    // MARK: Actions
    @IBAction func newButtonAction(sender: UIBarButtonItem) {
        
    }
    
    
    @IBAction func deleteButtonAction(sender: UIBarButtonItem) {
        
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        
        
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        fetchedResultsController.delegate = self
        
        collectionView.dataSource = self
//        collectionView.reloadData()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mapView.region = region!
        mapView.setCenterCoordinate(region!.center, animated: true)
        mapView.addAnnotation(annotation!)
    }
    
    // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext
    }
    
    // MARK: Utility methods
    private func setupCollectionView() {
        let space: CGFloat = 1.0
        let dimension = (view.frame.size.width - (2*space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }
}

extension PhotosViewController : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let CellIdentifier = "photoCollectionViewCell"
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        if let path = DownloadManager.sharedInstance().pathForPhoto(photo) {
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                cell.photoView.image = UIImage(contentsOfFile: path)
                cell.photoView.contentMode = .ScaleToFill
            } else {
                DownloadManager.sharedInstance().downloadPhotoImage(photo, completion: { (filePath: String) in
                    performUIUpdatesOnMain {
                        collectionView.reloadItemsAtIndexPaths([indexPath])
                    }
                })
            }
        }
        
        return cell
    }
}
