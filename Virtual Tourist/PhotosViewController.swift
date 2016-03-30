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
import MBProgressHUD

class PhotosViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    // MARK: Variables
    var region:MKCoordinateRegion?
    var annotation:MKPointAnnotation?
    var pin:Pin?
    var selectOn = false
    var noImagesLabel:UILabel?
    var selectedPhotos = Array<Photo>()
    var pinImageCount = 0
    
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
    @IBAction func refreshButtonAction(sender: UIBarButtonItem) {
        if let pin = pin {
            refreshButton.enabled = false
            
            if let photos = pin.photos {
                for photo in photos.allObjects {
                    let photoObject = photo as! Photo
                    if let p = DownloadManager.sharedInstance().findOrCreatePhoto([Photo.Keys.PhotoId: photoObject.photoId!], pin: pin) {
                        sharedContext.deleteObject(p)
                    }
                }
            }
            
            pinImageCount = 0
            pin.pageNumber = NSNumber(int: pin.pageNumber!.integerValue+1)
            CoreDataManager.sharedInstance().saveContext()
            
            let failure = { (error: NSError?) in
                print("Refresh error... \(error)")
            }
            DownloadManager.sharedInstance().downloadImagesForPin(pin, howMany: Constants.FlickrParameterValues.PerPageValue, failure: failure)
            checkPinImageCount()
        }
    }
    
    
    @IBAction func selectButtonAction(sender: UIBarButtonItem) {
        selectOn = !selectOn
        refreshButton.enabled = !selectOn && pinImageCount >= pin!.photos?.count
        toolBar.hidden = !selectOn
        selectButton.title = selectOn ? "Cancel" : "Select"
        
        if !selectOn {
            selectedPhotos.removeAll()
            
            if let indexPaths = collectionView.indexPathsForSelectedItems() {
                collectionView.reloadItemsAtIndexPaths(indexPaths)
            }
        }
    }
    
    @IBAction func deleteAction(sender: UIBarButtonItem) {
        if let pin = pin {
            let failure = { (error: NSError?) in
                print("Download error... \(error)")
            }
            let count = selectedPhotos.count
            
            for photo in selectedPhotos {
                if let p = DownloadManager.sharedInstance().findOrCreatePhoto([Photo.Keys.PhotoId: photo.photoId!], pin: pin) {
                    sharedContext.deleteObject(p)
                    pinImageCount--
                }
            }
            selectedPhotos.removeAll()
            
            pin.pageNumber = NSNumber(int: pin.pageNumber!.integerValue+1)
            CoreDataManager.sharedInstance().saveContext()
            
            DownloadManager.sharedInstance().downloadImagesForPin(pin, howMany: count, failure: failure)
            checkPinImageCount()
        }
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true

        do {
            try fetchedResultsController.performFetch()
        } catch {}
        fetchedResultsController.delegate = self
        
        if let pin = pin {
            let failure = { (error: NSError?) in
                print("Refresh error... \(error)")
            }
            
            let count = pin.photos!.count >= Constants.FlickrParameterValues.PerPageValue ? 0 : (Constants.FlickrParameterValues.PerPageValue - pin.photos!.count)
            
            if count > 0 {
                DownloadManager.sharedInstance().downloadImagesForPin(pin, howMany: count, failure: failure)
            }
            checkPinImageCount()
        }
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
    func checkPinImageCount() {
        if let objects = fetchedResultsController.fetchedObjects {
            if objects.count == 0 {
                if noImagesLabel == nil {
                    noImagesLabel = UILabel(frame: CGRectMake(0, collectionView.frame.origin.y+100, view.frame.size.width, 40))
                    noImagesLabel!.text = "No Images Found"
                    noImagesLabel!.textColor = UIColor.whiteColor()
                    noImagesLabel!.textAlignment = .Center
                    collectionView.addSubview(noImagesLabel!)
                }
            
            } else {
                if let noImagesLabel = noImagesLabel {
                    noImagesLabel.removeFromSuperview()
                }
                noImagesLabel = nil
            }
        }
    }
    
    private func setupCollectionView() {
        let space: CGFloat = 1.0
        let dimension = (view.frame.size.width - (3*space)) / 4.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo, indexPath: NSIndexPath) {
        var isSelected = false
        for p in selectedPhotos {
            if p == photo {
                isSelected = true
                break
            }
        }
        
        cell.checkImage.hidden = !isSelected
        cell.photoView.image = nil
        
        if let fullPath = photo.fullPath {
            if !cell.hasHUD {
                MBProgressHUD.showHUDAddedTo(cell, animated: true)
                cell.hasHUD = true
            }
            
            DownloadManager.sharedInstance().downloadPhotoImage(photo, completion: { (filePath: String) in
                performUIUpdatesOnMain {
                    cell.photoView.image = UIImage(contentsOfFile: fullPath)
                    MBProgressHUD.hideHUDForView(cell, animated: true)
                    cell.hasHUD = false
                    
                    self.pinImageCount++
                    if !self.selectOn {
                        self.refreshButton.enabled = self.pinImageCount >= self.pin!.photos?.count
                    }
                    
                    self.checkPinImageCount()
                }
            })
        }
    }
}

// MARK: UICollectionViewDataSource
extension PhotosViewController : UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let CellIdentifier = "photoCollectionViewCell"
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        configureCell(cell, photo: photo, indexPath: indexPath)
        return cell
    }
}

// MARK: UICollectionViewDelegate
extension PhotosViewController : UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if selectOn {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
            cell.checkImage.hidden = false
            selectedPhotos.append(photo)
            deleteButton.enabled = true
        } else {
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoDetailsViewController") as! PhotoDetailsViewController
            controller.photo = photo
            self.navigationController!.pushViewController(controller, animated: true)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        if selectOn {
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            
            if let index = selectedPhotos.indexOf(photo) {
                selectedPhotos.removeAtIndex(index)
            }
            cell.checkImage.hidden = true
            deleteButton.enabled = selectedPhotos.count > 0
        }
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension PhotosViewController : NSFetchedResultsControllerDelegate {
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            switch type {
            case .Insert:
                collectionView.insertSections(NSIndexSet(index: sectionIndex))
                
            case .Delete:
                collectionView.deleteSections(NSIndexSet(index: sectionIndex))
                
            default:
                return
            }
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                collectionView.insertItemsAtIndexPaths([newIndexPath!])
                
            case .Delete:
                collectionView.deleteItemsAtIndexPaths([indexPath!])
                
            case .Update:
                if let indexPath = indexPath {
                    if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
                        let photo = controller.objectAtIndexPath(indexPath) as! Photo
                        configureCell(cell as! PhotoCollectionViewCell, photo: photo, indexPath: indexPath)
                    }
                }
                
            case .Move:
                collectionView.deleteItemsAtIndexPaths([indexPath!])
                collectionView.insertItemsAtIndexPaths([newIndexPath!])

            }
    }
}
