//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/17/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let latitude = NSUserDefaults.standardUserDefaults().objectForKey("latitude") as? CLLocationDegrees,
            let longitude = NSUserDefaults.standardUserDefaults().objectForKey("longitude") as? CLLocationDegrees,
            let latitudeDelta = NSUserDefaults.standardUserDefaults().objectForKey("latitudeDelta") as? CLLocationDegrees,
            let longitudeDelta = NSUserDefaults.standardUserDefaults().objectForKey("longitudeDelta") as? CLLocationDegrees {
                
                let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
                let savedRegion = MKCoordinateRegion(center: center, span: span)
                mapView.setRegion(savedRegion, animated: true)
        }
        
        mapView.delegate = self
    }
}

// MARK: MKMapViewDelegate
extension MapViewController : MKMapViewDelegate {
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.region.center
        let span = mapView.region.span
        
        NSUserDefaults.standardUserDefaults().setDouble(center.latitude, forKey: "latitude")
        NSUserDefaults.standardUserDefaults().setDouble(center.longitude, forKey: "longitude")
        NSUserDefaults.standardUserDefaults().setDouble(span.latitudeDelta, forKey: "latitudeDelta")
        NSUserDefaults.standardUserDefaults().setDouble(span.longitudeDelta, forKey: "longitudeDelta")
    }
}
