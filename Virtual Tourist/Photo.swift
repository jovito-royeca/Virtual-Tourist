//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/17/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {

    struct Keys {
        static let FilePath     = "filePath"
        static let PhotoId      = "id"
        static let Title        = "title"
        static let URLPath      = "url_m"
        static let Description  = "description"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Photo class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary. This works in the same way that it did before we started on Core Data
        filePath = dictionary[Keys.FilePath] as? String
        photoId = dictionary[Keys.PhotoId] as? String
        title = dictionary[Keys.Title] as? String
        urlPath = dictionary[Keys.URLPath] as? String
        
        // save only non-white space
        if let desc = dictionary[Keys.Description] as? [String: AnyObject] {
            if let content = desc["_content"] as? String {
                let charSet = NSCharacterSet.whitespaceCharacterSet()
                let trimmedString = content.stringByTrimmingCharactersInSet(charSet)
                if trimmedString != "" {
                    description_ = trimmedString
                }
            }
        }
        
    }
    
    override func prepareForDeletion() {
        // delete the image file
        if let fullPath = fullPath {
            if NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
                do {
                    print("deleting... \(fullPath)")
                    try NSFileManager.defaultManager().removeItemAtPath(fullPath)
                } catch let error as NSError {
                    print("Error deleting... \(error.localizedDescription)")
                }
            }
        }
    }
    
    var fullPath: String? {
        
        get {
            if let filePath = filePath {
                let docsDirectory: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
                return "\(docsDirectory.path!)/\(filePath)"
            }
            return nil
        }
    }
}
