//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/17/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var photoId: NSNumber?
    @NSManaged var title: String?
    @NSManaged var urlPath: String?
    @NSManaged var filePath: String?
    @NSManaged var location: Location?

}
