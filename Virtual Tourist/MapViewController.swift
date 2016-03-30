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
    
    // MARK: Outlets
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    // MARK: Variables
    var savedRegion:MKCoordinateRegion?
    var editingOn = false
    var currentAnnotation:MKPointAnnotation?
    var currentPin:Pin?
    
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
        if editingOn {
           return
        }
        
        let touchPoint = sender.locationInView(mapView)
        let location = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        switch sender.state {
            case .Began:
                currentAnnotation = MKPointAnnotation()
                currentAnnotation!.coordinate = location
                mapView.addAnnotation(currentAnnotation!)
            
            case .Changed:
                // update the pin's location based on drag gesture
                currentAnnotation!.coordinate = location
            case .Ended:
                // create the pin
                let dictionary: [String : AnyObject] = [
                    Pin.Keys.Latitude : location.latitude,
                    Pin.Keys.Longitude : location.longitude,
                    Pin.Keys.PageNumber : 1
                ]
                createPin(dictionary)
            
            default:
                return
        }
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
    func createPin(dictionary: [String: AnyObject]) {
        let pin = Pin(dictionary: dictionary, context: sharedContext)
        
        CoreDataManager.sharedInstance().saveContext()
        let failure = { (error: NSError?) in
            print("error=\(error)")
        }
        
        // download images for the pin immidiately
        DownloadManager.sharedInstance().downloadImagesForPin(pin, howMany: Constants.FlickrParameterValues.PerPageValue, failure: failure)
    }
    
    func deletePin(pin: Pin) {
        if let photos = pin.photos {
            for photo in photos.allObjects {
                sharedContext.deleteObject(photo as! NSManagedObject)
            }
        }
        sharedContext.deleteObject(pin)
        CoreDataManager.sharedInstance().saveContext()
    }
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.draggable = true
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = mapView.selectedAnnotations.first as? MKPointAnnotation {
        
            if editingOn {
                mapView.removeAnnotation(annotation)
                
                // delete Pin from Core Data
                if let pin = DownloadManager.sharedInstance().findOrCreatePin(annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) {
                    deletePin(pin)
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
    
    // BUG: dragging pins does not work because mapView:didSelectAnnotationView: takes precedence
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        let location = view.annotation!.coordinate
        
        switch newState {
            case .Starting:
                currentPin = DownloadManager.sharedInstance().findOrCreatePin(location.latitude, longitude: location.longitude)
            
            case .Ending:
                // delete the current pin
                if let currentPin = currentPin {
                    deletePin(currentPin)
                }
            
                // then create a new one
                let dictionary: [String : AnyObject] = [
                    Pin.Keys.Latitude : location.latitude,
                    Pin.Keys.Longitude : location.longitude,
                    Pin.Keys.PageNumber : 1
                ]
                createPin(dictionary)
            
            default:
                return
        }
    }
}
