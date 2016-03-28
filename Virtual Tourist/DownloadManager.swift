//
//  DownloadManager.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/26/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit
import CoreData

class DownloadManager: NSObject {

    func downloadImagesForPin(pin: Pin, failure: (error: NSError?) -> Void) {
        
        let httpMethod:HTTPMethod = .Get
        let urlString = "\(Constants.Flickr.ApiScheme)://\(Constants.Flickr.ApiHost)/\(Constants.Flickr.ApiPath)"
        let parameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(pin.latitude!.doubleValue, longitude: pin.longitude!.doubleValue),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPageValue
        ]
        
        let success = { (results: AnyObject!) in
            if let dict = results as? [String: AnyObject] {
                
                if let photos = dict["photos"] as? [String: AnyObject] {
                    if let photo = photos["photo"] as? [[String: AnyObject]] {
                        
                        for d in photo {
                            if let p = self.findOrCreatePhoto(d, pin: pin) {
                                self.downloadPhotoImage(p)
                            }
                        }
                        
                    }  else {
                        print("error: photo key not found")
                    }
                } else {
                    print("error: photos key not found")
                }
            }
        }
        
        NetworkManager.sharedInstance().exec(httpMethod, urlString: urlString, headers: nil, parameters: parameters, values: nil, body: nil, dataOffset: 0, isJSON: true, success: success, failure: failure)
    }
    
    func findOrCreatePin(latitude: Double, longitude: Double) -> Pin? {
        var pin:Pin?
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", NSNumber(double: latitude), NSNumber(double: longitude))
        do {
            if let p = try sharedContext.executeFetchRequest(fetchRequest).first as? Pin {
                pin = p
            } else {
                let dictionary: [String : AnyObject] = [
                    Pin.Keys.Latitude : latitude,
                    Pin.Keys.Longitude : longitude
                ]
                
                pin = Pin(dictionary: dictionary, context: sharedContext)
                CoreDataManager.sharedInstance().saveContext()
            }
        } catch let error as NSError {
            print("Could not delete \(error), \(error.userInfo)")
        }
        
        return pin
    }
    
    func findOrCreatePhoto(dict: Dictionary<String, AnyObject>, pin: Pin) -> Photo? {
        var photo:Photo?
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        let photoId = dict[Photo.Keys.PhotoId] as? String
        fetchRequest.predicate = NSPredicate(format: "photoId == %@", photoId!)
        do {
            if let p = try sharedContext.executeFetchRequest(fetchRequest).first as? Photo {
                photo = p
                photo!.title = dict[Photo.Keys.Title] as? String
                photo!.urlPath = dict[Photo.Keys.URLPath] as? String
                
            } else {
                photo = Photo(dictionary: dict, context: sharedContext)
            }
            photo!.pin = pin
            
            CoreDataManager.sharedInstance().saveContext()
        } catch let error as NSError {
            print("Could not delete \(error), \(error.userInfo)")
        }
        
        return photo
    }
    
    func downloadPhotoImage(photo: Photo) {
        
        if let path = photo.localPath {
            let httpMethod:HTTPMethod = .Get
            
            let success = { (results: AnyObject!) in
                let data = results as! NSData
                data.writeToFile(path as String, atomically: true)
                print("writing... \(path)")
            }
            
            let failure = { (error: NSError?) in
                print("error=\(error)")
            }
            
            NetworkManager.sharedInstance().exec(httpMethod, urlString: photo.urlPath, headers: nil, parameters: nil, values: nil, body: nil, dataOffset: 0, isJSON: false, success: success, failure: failure)
        }
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    private var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext
    }
    
    // MARK: - Shared Instance
    class func sharedInstance() -> DownloadManager {
        struct Static {
            static let instance = DownloadManager()
        }
        
        return Static.instance
    }
}
