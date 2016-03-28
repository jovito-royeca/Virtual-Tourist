//
//  Virtual_TouristTests.swift
//  Virtual TouristTests
//
//  Created by Jovit Royeca on 3/16/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import XCTest
import CoreData
@testable import Virtual_Tourist

class Virtual_TouristTests: XCTestCase {
    var imagesDownloaded = 0
    var finished = false
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testImageDownload() {
        let urlPath = "https://farm2.staticflickr.com/1582/25975763672_64699cdbf5.jpg"
        
        
        if let url = NSURL(string: urlPath) {
        
            let cacheDirectory: NSURL = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
            let fullPath = "\(cacheDirectory.path!)/\(url.lastPathComponent!)"
            
            if !NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
                
                let httpMethod:HTTPMethod = .Get
                
                let success = { (results: AnyObject!) in
                    let data = results as! NSData
                    print("writing... \(fullPath)")
                    data.writeToFile(fullPath, atomically: true)
                    self.finished = true
                }
                
                let failure = { (error: NSError?) in
                    print("error=\(error)")
                    self.finished = true
                }
                
                NetworkManager.sharedInstance().exec(httpMethod, urlString: url.absoluteString, headers: nil, parameters: nil, values: nil, body: nil, dataOffset: 0, isJSON: false, success: success, failure: failure)
                
                repeat {
                    NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate:NSDate.distantFuture())
                } while !finished
            }
        }

    }
    
    func testFlickr() {
        let lat = 14.6139688454391
        let lon = 121.058349889362
        let pin = findOrCreatePin(lat, longitude: lon)
        
        let httpMethod:HTTPMethod = .Get
        let urlString = "\(Constants.Flickr.ApiScheme)://\(Constants.Flickr.ApiHost)/\(Constants.Flickr.ApiPath)"
        let parameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(lat, longitude: lon),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            "per_page": "3"
        ]
        
        let success = { (results: AnyObject!) in
            if let dict = results as? [String: AnyObject] {
            
                if let photos = dict["photos"] as? [String: AnyObject] {
                    if let photo = photos["photo"] as? [[String: AnyObject]] {
                        print("\(photo)")
                        
                        for d in photo {
                            if let p = self.findOrCreatePhoto(d, pin: pin!) {
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
        
        let failure = { (error: NSError?) in
            print("error=\(error)")
            self.finished = true
        }
                
        NetworkManager.sharedInstance().exec(httpMethod, urlString: urlString, headers: nil, parameters: parameters, values: nil, body: nil, dataOffset: 0, isJSON: true, success: success, failure: failure)
        
        repeat {
            NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate:NSDate.distantFuture())
        } while !finished
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
                        Pin.Keys.Longitude : longitude,
                        Pin.Keys.PageNumber : 1
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
                
                self.imagesDownloaded++
                
                if self.imagesDownloaded >= 18 {
                    self.finished = true
                }
            }
            
            let failure = { (error: NSError?) in
                print("error=\(error)")
                self.finished = true
            }
            
            NetworkManager.sharedInstance().exec(httpMethod, urlString: photo.urlPath, headers: nil, parameters: nil, values: nil, body: nil, dataOffset: 0, isJSON: false, success: success, failure: failure)
        }
    }
    
    func bboxString(latitude: Double, longitude: Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext
    }
}
