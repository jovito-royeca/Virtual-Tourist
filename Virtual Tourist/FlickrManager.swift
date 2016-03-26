//
//  FlickrManager.swift
//  Virtual Tourist
//
//  Created by Jovit Royeca on 3/18/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit

class FlickrManager: NSObject {

    // MARK: Helper for Creating a URL from Parameters
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    // MARK: - Shared Instance
    class func sharedInstance() -> FlickrManager {
        
        struct Singleton {
            static var sharedInstance = FlickrManager()
        }
        
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Image Cache
    struct Caches {
        static let imageCache = ImageCache()
    }
}
