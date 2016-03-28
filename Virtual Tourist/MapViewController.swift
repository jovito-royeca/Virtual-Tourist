//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/17/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit


class MapViewController: UIViewController {
    
    struct Keys {
        static let Latitude       = "latitude"
        static let Longitude      = "longitude"
        static let LatitudeDelta  = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
    }
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var instructionLabel: UILabel!
    var savedRegion:MKCoordinateRegion?
    var editingOn = false
    var startDragCoordinate:CLLocationCoordinate2D?
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        if let latitude = NSUserDefaults.standardUserDefaults().objectForKey(Keys.Latitude) as? CLLocationDegrees,
            let longitude = NSUserDefaults.standardUserDefaults().objectForKey(Keys.Longitude) as? CLLocationDegrees,
            let latitudeDelta = NSUserDefaults.standardUserDefaults().objectForKey(Keys.LatitudeDelta) as? CLLocationDegrees,
            let longitudeDelta = NSUserDefaults.standardUserDefaults().objectForKey(Keys.LongitudeDelta) as? CLLocationDegrees {
                
                let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
                savedRegion = MKCoordinateRegion(center: center, span: span)
        }
        
        // load any Pins from Core Data
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
            for pin in results {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(pin.latitude!.doubleValue, pin.longitude!.doubleValue)
                mapView.addAnnotation(annotation)
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let savedRegion = savedRegion {
            mapView.region = savedRegion
            mapView.setCenterCoordinate(savedRegion.center, animated: true)
        }
    }
    
    // MARK: Actions
    @IBAction func longPressAction(sender: UILongPressGestureRecognizer) {
        if sender.state != .Began || editingOn {
            return
        }
        
        let touchPoint = sender.locationInView(mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        mapView.addAnnotation(annotation)
        
        let dictionary: [String : AnyObject] = [
            Pin.Keys.Latitude : annotation.coordinate.latitude,
            Pin.Keys.Longitude : annotation.coordinate.longitude,
            Pin.Keys.PageNumber : 1
        ]
        
        // Now we create a new Pin, using the shared Context
        let pin = Pin(dictionary: dictionary, context: sharedContext)
        CoreDataManager.sharedInstance().saveContext()
        let failure = { (error: NSError?) in
            print("error=\(error)")
        }
        
        // download images for the pin immidiately
        DownloadManager.sharedInstance().downloadImagesForPin(pin, failure: failure)
//        if let pin = DownloadManager.sharedInstance().findOrCreatePin(annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) {
//            DownloadManager.sharedInstance().downloadImagesForPin(pin, failure: failure)
//        }
    }
    
    @IBAction func editAction(sender: UIBarButtonItem) {
        editingOn = !editingOn
        instructionLabel.hidden = !editingOn
        editButton.title = editingOn ? "Done" : "Edit"
    }
    
    // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext
    }
    
    // MARK: Utility methods
}

// MARK: MKMapViewDelegate
extension MapViewController : MKMapViewDelegate {
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        savedRegion = MKCoordinateRegion(center: mapView.region.center, span: mapView.region.span)
        
        NSUserDefaults.standardUserDefaults().setDouble(savedRegion!.center.latitude, forKey: Keys.Latitude)
        NSUserDefaults.standardUserDefaults().setDouble(savedRegion!.center.longitude, forKey: Keys.Longitude)
        NSUserDefaults.standardUserDefaults().setDouble(savedRegion!.span.latitudeDelta, forKey: Keys.LatitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(savedRegion!.span.longitudeDelta, forKey: Keys.LongitudeDelta)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = mapView.selectedAnnotations.first as? MKPointAnnotation {
        
            if editingOn {
                mapView.removeAnnotation(annotation)
                
                // delete Location from Core Data
                if let pin = DownloadManager.sharedInstance().findOrCreatePin(annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) {
                    DownloadManager.sharedInstance().deleteImagesForPin(pin)
                    sharedContext.deleteObject(pin)
                    CoreDataManager.sharedInstance().saveContext()
                    
                }
                
            } else {
                // deselect so we can select it again upon returning from PhotosViewController
                mapView.deselectAnnotation(annotation, animated: false)
                
                let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PhotosViewController") as! PhotosViewController
                controller.region = savedRegion
                controller.annotation = annotation
                if let pin = DownloadManager.sharedInstance().findOrCreatePin(annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) {
                    controller.pin = pin
                }
                self.navigationController!.pushViewController(controller, animated: true)
            }
        }
    }
    
    // TODO: Implement dragging pins to change location
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if newState == .Starting {
            startDragCoordinate = view.annotation!.coordinate
        }
            
        else if newState == .Ending {
            if let pin = DownloadManager.sharedInstance().findOrCreatePin(startDragCoordinate!.latitude, longitude: startDragCoordinate!.longitude) {
                pin.latitude = NSNumber(double: view.annotation!.coordinate.latitude)
                pin.longitude = NSNumber(double: view.annotation!.coordinate.longitude)
                CoreDataManager.sharedInstance().saveContext()
            }
        }
    }
}
