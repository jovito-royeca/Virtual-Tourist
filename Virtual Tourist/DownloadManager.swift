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

    func downloadImagesForPin(pin: Pin, howMany: Int, failure: (error: NSError?) -> Void) {
        
        let httpMethod:HTTPMethod = .Get
        let urlString = "\(Constants.Flickr.ApiScheme)://\(Constants.Flickr.ApiHost)/\(Constants.Flickr.ApiPath)"
        let parameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(pin.latitude!.doubleValue, longitude: pin.longitude!.doubleValue),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParameterKeys.Page: "\(pin.pageNumber!)",
            Constants.FlickrParameterKeys.PerPage: "\(howMany)",
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.ExtrasValue
        ]
        
        let success = { (results: AnyObject!) in
            if let dict = results as? [String: AnyObject] {
                
                if let photos = dict["photos"] as? [String: AnyObject] {
                    if let photo = photos["photo"] as? [[String: AnyObject]] {
                        
                        for d in photo {
                            if let p = self.findOrCreatePhoto(d, pin: pin) {
                                if let owner = self.findOrCreateOwner(d) {
                                    p.owner = owner
                                    CoreDataManager.sharedInstance().saveContext()
                                }
                                
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
                
            } else {
                photo = Photo(dictionary: dict, context: sharedContext)
                if let urlPath = photo!.urlPath {
                    if let url = NSURL(string: urlPath) {
                        photo!.filePath = "\(pin.latitude!)X\(pin.longitude!)/\(url.lastPathComponent!)"
                    }
                }
                photo!.pin = pin
                
                if let tags = dict["tags"] as? String {
                    if let setTags = findOrCreateTags(tags) {
                        photo!.tags = setTags
                    }
                }
                
                CoreDataManager.sharedInstance().saveContext()
            }
            
        } catch let error as NSError {
            print("Error in fetch \(error), \(error.userInfo)")
        }
        
        return photo
    }
    
    func findOrCreateOwner(dict: Dictionary<String, AnyObject>) -> Owner? {
        var owner:Owner?
        
        let fetchRequest = NSFetchRequest(entityName: "Owner")
        let ownerId = dict[Owner.Keys.OwnerId] as? String
        
        fetchRequest.predicate = NSPredicate(format: "ownerId == %@", ownerId!)
        do {
            if let o = try sharedContext.executeFetchRequest(fetchRequest).first as? Owner {
                owner = o
                
            } else {
                owner = Owner(dictionary: dict, context: sharedContext)
                CoreDataManager.sharedInstance().saveContext()
            }
            
        } catch let error as NSError {
            print("Error in fetch \(error), \(error.userInfo)")
        }
        
        return owner
    }
    
    func findOrCreateTags(string: String) -> NSSet? {
        if isStringEmpty(string) {
            return nil
        }
        
        var tags = Array<Tag>()
        
        for name in string.componentsSeparatedByString(" ") {
            var tag:Tag?
            let fetchRequest = NSFetchRequest(entityName: "Tag")
            fetchRequest.predicate = NSPredicate(format: "name == %@", name)
            
            do {
                if let t = try sharedContext.executeFetchRequest(fetchRequest).first as? Tag {
                    tag = t
                } else {
                    tag = Tag(dictionary: ["name": name], context: sharedContext)
                }
                CoreDataManager.sharedInstance().saveContext()
                
                tags.append(tag!)
            } catch let error as NSError {
                print("Error in tags... \(error), \(error.userInfo)")
            }
        }
        
        return tags.count > 0 ? NSSet(array: tags) : nil
    }
    
    func isStringEmpty(string: String) -> Bool {
        let charSet = NSCharacterSet.whitespaceCharacterSet()
        let trimmedString = string.stringByTrimmingCharactersInSet(charSet)
        return trimmedString == "" ? true : false
    }
    
    func downloadPhotoImage(photo: Photo, completion: ((filePath: String) -> Void)?) {
        if let filePath = photo.filePath {
            let docsDirectory: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            let fullPath = "\(docsDirectory.path!)/\(filePath)"
            
            // create subdirectory if not yet existing
            let subdir = "\(docsDirectory.path!)/\(photo.pin!.latitude!)X\(photo.pin!.longitude!)"
            if !NSFileManager.defaultManager().fileExistsAtPath(subdir) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(subdir, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    print("Error creating dir... \(error.localizedDescription)")
                }
            }
            
            // download the image if not yet existing
            if !NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
                let httpMethod:HTTPMethod = .Get
                
                let success = { (results: AnyObject!) in
                    // now let's write the image file
                    let imageData = results as! NSData
                    imageData.writeToFile(fullPath as String, atomically: true)
                    print("writing... \(fullPath)")
                    
                    if let completion = completion {
                        completion(filePath: fullPath)
                    }
                }
                
                let failure = { (error: NSError?) in
                    print("Error downloading image... =\(error)")
                    
                    if let completion = completion {
                        completion(filePath: fullPath)
                    }
                }
                
                NetworkManager.sharedInstance().exec(httpMethod, urlString: photo.urlPath, headers: nil, parameters: nil, values: nil, body: nil, dataOffset: 0, isJSON: false, success: success, failure: failure)
                
            } else {
                
                if let completion = completion {
                    completion(filePath: fullPath)
                }
            }
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
