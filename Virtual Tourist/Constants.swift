//
//  Constants.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/18/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import Foundation

struct Constants {
    
    // MARK: Flickr
    struct Flickr {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
//        static let SearchBBoxHalfWidth = 1.0
//        static let SearchBBoxHalfHeight = 1.0
//        static let SearchLatRange = (-90.0, 90.0)
//        static let SearchLonRange = (-180.0, 180.0)
    }
    
    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let APIKey = "api_key"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let APIKey = "34aedddda108d5916bf227a5bdc379a2"
    }
}