//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/17/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {
    
    struct Keys {
        static let Latitude   = "latitude"
        static let Longitude  = "longitude"
        static let PageNumber = "pageNumber"
    }

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Pin class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary. This works in the same way that it did before we started on Core Data
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
        pageNumber = dictionary[Keys.PageNumber] as? Int
    }
    
    override func prepareForDeletion() {
        // remove the subdirectory
        let docsDirectory: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let dir = "\(docsDirectory.path!)/\(latitude!)X\(longitude!)"
        
        do {
            print("deleting... \(dir)")
            try NSFileManager.defaultManager().removeItemAtPath(dir)
        } catch let error as NSError {
            print("Error deleting... \(error.localizedDescription)")
        }
    }
}
