//
//  Virtual_TouristTests.swift
//  Virtual TouristTests
//
//  Created by Jovit Royeca on 3/16/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import XCTest
@testable import Virtual_Tourist

class Virtual_TouristTests: XCTestCase {
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
    
    func testFlickr() {
        let lat = 14.6139688454391
        let lon = 121.058349889362
        
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
            "per_page": "2"
        ]
        let success = { (results: AnyObject!) in
            if let dict = results as? [String: AnyObject] {
            
                if let photos = dict["photos"] as? [String: AnyObject] {
                    if let photo = photos["photo"] as? [[String: AnyObject]] {
                        print("\(photo)")
                    }  else {
                        print("error: photo key not found")
                    }
                } else {
                    print("error: photos key not found")
                }
            }
            self.finished = true
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
    
    func bboxString(latitude: Double, longitude: Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
}
