//
//  Tag+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/26/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Tag {

    @NSManaged var name: String?
    @NSManaged var photos: NSSet?

}
