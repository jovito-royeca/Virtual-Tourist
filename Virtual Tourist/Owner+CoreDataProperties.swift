//
//  Owner+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/30/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Owner {

    @NSManaged var ownerId: String?
    @NSManaged var ownerName: String?
    @NSManaged var photos: NSSet?

}
