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
    var editingOn = false
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let locationManager = CLLocationManager()
//        if CLLocationManager.authorizationStatus() == .NotDetermined {
//            locationManager.requestWhenInUseAuthorization()
//        }
    
        mapView.delegate = self
        
        if let latitude = NSUserDefaults.standardUserDefaults().objectForKey(Keys.Latitude) as? CLLocationDegrees,
            let longitude = NSUserDefaults.standardUserDefaults().objectForKey(Keys.Longitude) as? CLLocationDegrees,
            let latitudeDelta = NSUserDefaults.standardUserDefaults().objectForKey(Keys.LatitudeDelta) as? CLLocationDegrees,
            let longitudeDelta = NSUserDefaults.standardUserDefaults().objectForKey(Keys.LongitudeDelta) as? CLLocationDegrees {
                
                let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
                let savedRegion = MKCoordinateRegion(center: center, span: span)
                mapView.setRegion(savedRegion, animated: true)
        }
        
        // load any Locations from Core Data
        let fetchRequest = NSFetchRequest(entityName: "Location")
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest) as! [Location]
            for location in results {
                let point = MKPointAnnotation()
                point.coordinate = CLLocationCoordinate2DMake(location.latitude!.doubleValue, location.longitude!.doubleValue)
                mapView.addAnnotation(point)
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    // MARK: Actions
    @IBAction func longPressAction(sender: UILongPressGestureRecognizer) {
        if sender.state != .Began || editingOn {
            return
        }
        
        let touchPoint = sender.locationInView(mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let point = MKPointAnnotation()
        point.coordinate = touchMapCoordinate
        mapView.addAnnotation(point)
        
        let dictionary: [String : AnyObject] = [
            Location.Keys.Latitude : point.coordinate.latitude,
            Location.Keys.Longitude : point.coordinate.longitude
        ]
        
        // Now we create a new Location, using the shared Context
        let _ = Location(dictionary: dictionary, context: sharedContext)
        DataManager.sharedInstance().saveContext()
    }
    
    @IBAction func editAction(sender: UIBarButtonItem) {
        editingOn = !editingOn
        instructionLabel.hidden = !editingOn
        editButton.title = editingOn ? "Done" : "Edit"
    }
    
    // MARK: - Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    var sharedContext: NSManagedObjectContext {
        return DataManager.sharedInstance().managedObjectContext
    }
}

// MARK: MKMapViewDelegate
extension MapViewController : MKMapViewDelegate {
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let region = MKCoordinateRegion(center: mapView.region.center, span: mapView.region.span)
        let adjustedRegion = mapView.regionThatFits(region)
        let center = adjustedRegion.center
        let span = adjustedRegion.span
        
        NSUserDefaults.standardUserDefaults().setDouble(center.latitude, forKey: Keys.Latitude)
        NSUserDefaults.standardUserDefaults().setDouble(center.longitude, forKey: Keys.Longitude)
        NSUserDefaults.standardUserDefaults().setDouble(span.latitudeDelta, forKey: Keys.LatitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(span.longitudeDelta, forKey: Keys.LongitudeDelta)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let pin = mapView.selectedAnnotations.first as? MKPointAnnotation {
        
            if editingOn {
                mapView.removeAnnotation(pin)
                
                // delete Location from Core Data
                let fetchRequest = NSFetchRequest(entityName: "Location")
                fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", NSNumber(double: pin.coordinate.latitude), NSNumber(double: pin.coordinate.longitude))
                do {
                    let results = try sharedContext.executeFetchRequest(fetchRequest)
                    sharedContext.deleteObject(results.first as! NSManagedObject)
                    DataManager.sharedInstance().saveContext()
                } catch let error as NSError {
                    print("Could not delete \(error), \(error.userInfo)")
                }
                
            } else {
                let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PhotosViewController") as! PhotosViewController
                let region = MKCoordinateRegion(center: mapView.region.center, span: mapView.region.span)
                let adjustedRegion = mapView.regionThatFits(region)

                controller.region = adjustedRegion
                controller.pin = pin
                self.navigationController!.pushViewController(controller, animated: true)
            }
        }
    }
}
