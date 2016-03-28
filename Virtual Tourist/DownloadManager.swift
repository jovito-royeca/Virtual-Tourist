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
                                self.downloadPhotoImage(p, completion: nil)
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
    
    func deleteImagesForPin(pin: Pin) {
        let docsDirectory: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let dir = "\(docsDirectory.path!)/\(pin.latitude!)X\(pin.longitude!)"

        // remove the image files
        if let photos = pin.photos {
            for photo in photos.allObjects as! [Photo] {
                
                if let fullPath = pathForPhoto(photo) {
                    if NSFileManager.defaultManager().fileExistsAtPath(fullPath as String) {
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(fullPath as String)
                        } catch let error as NSError {
                            NSLog("Error deleting... \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        
        // remove the directory
        do {
            try NSFileManager.defaultManager().removeItemAtPath(dir)
        } catch let error as NSError {
            NSLog("Error deleting... \(error.localizedDescription)")
        }
    }
    
    func findOrCreatePin(latitude: Double, longitude: Double) -> Pin? {
        var pin:Pin?
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", NSNumber(double: latitude), NSNumber(double: longitude))
        do {
            if let p = try sharedContext.executeFetchRequest(fetchRequest).first as? Pin {
                pin = p
            } else {
                let dictionary = [
                    Pin.Keys.Latitude : latitude,
                    Pin.Keys.Longitude : longitude,
                    Pin.Keys.PageNumber: 1
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
        
        fetchRequest.predicate = NSPredicate(format: "pin == %@ AND photoId == %@", pin, photoId!)
        do {
            if let p = try sharedContext.executeFetchRequest(fetchRequest).first as? Photo {
                photo = p
                photo!.title = dict[Photo.Keys.Title] as? String
                photo!.urlPath = dict[Photo.Keys.URLPath] as? String
                
            } else {
                photo = Photo(dictionary: dict, context: sharedContext)
            }
            
            if let urlPath = photo!.urlPath {
                if let url = NSURL(string: urlPath) {
                    photo!.filePath = "\(pin.latitude!)X\(pin.longitude!)/\(url.lastPathComponent!)"
                }
            }
            photo!.pin = pin
            
            CoreDataManager.sharedInstance().saveContext()
            
            if let title = dict[Photo.Keys.Title] as? String {
                photo!.tags = findOrCreateTags(title)
                CoreDataManager.sharedInstance().saveContext()
            }
            
        } catch let error as NSError {
            print("Error in fetch \(error), \(error.userInfo)")
        }
        
        return photo
    }
    
    func findOrCreateTags(string: String) -> NSSet? {
        var tags = Array<Tag>()
        
        for component in string.componentsSeparatedByString(" ") {
            
            if component.hasPrefix("#") {
                var tag:Tag?
                let name = component.substringFromIndex(component.startIndex.advancedBy(1))
                let fetchRequest = NSFetchRequest(entityName: "Tag")
                fetchRequest.predicate = NSPredicate(format: "name == %@", name)
                
                do {
                    if let t = try sharedContext.executeFetchRequest(fetchRequest).first as? Tag {
                        tag = t
                    } else {
                        tag = Tag(dictionary: ["name": name], context: sharedContext)
                    }
                    tags.append(tag!)
                    
                    CoreDataManager.sharedInstance().saveContext()
                } catch let error as NSError {
                    print("Could not delete \(error), \(error.userInfo)")
                }
            }
        }
        
        return tags.count > 0  ? NSSet(array: tags) : nil
    }
    
    func downloadPhotoImage(photo: Photo, completion: ((filePath: String) -> Void)?) {
        
        if let fullPath = pathForPhoto(photo) {
            // create subdirectory if not yet existing
            let docsDirectory: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            let dir = "\(docsDirectory.path!)/\(photo.pin!.latitude!)X\(photo.pin!.longitude!)"
            if !NSFileManager.defaultManager().fileExistsAtPath(dir) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    NSLog("Error creating dir... \(error.localizedDescription)")
                }
            }
            
            if !NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
                let httpMethod:HTTPMethod = .Get
                
                let success = { (results: AnyObject!) in
                    let data = results as! NSData
                    data.writeToFile(fullPath as String, atomically: true)
                    print("writing... \(fullPath)")
                    
                    if let completion = completion {
                        completion(filePath: fullPath)
                    }
                }
                
                let failure = { (error: NSError?) in
                    print("error=\(error)")
                }
                
                NetworkManager.sharedInstance().exec(httpMethod, urlString: photo.urlPath, headers: nil, parameters: nil, values: nil, body: nil, dataOffset: 0, isJSON: false, success: success, failure: failure)
            }
        }
    }
    
    func pathForPhoto(photo: Photo) -> String? {
        if let filePath = photo.filePath {
            let docsDirectory: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            return "\(docsDirectory.path!)/\(filePath)"
        }
        
        return nil
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
