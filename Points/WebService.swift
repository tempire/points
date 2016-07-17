//
//  WebService.swift
//  Points
//
//  Created by Glen Hinkle on 7/5/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

struct Resource<A: JSONStruct> {
    let request: NSMutableURLRequest
    var parameters = [String:AnyObject]()
    
    init(url: NSURL, method: NSMutableURLRequest.Method) {
        request = NSMutableURLRequest(
            url: url,
            method: method
        )
    }
}

class WebService {
    static let wsdcBaseURL = NSURL(string: "http://wsdc-points.us-west-2.elasticbeanstalk.com")!
    
    static var session = NSURLSession.sharedSession()
    
    class func load<A>(resource: Resource<A>, completion: (JSONResult<A>)->Void) {
        
        WebService.session.dataTaskWithRequest(resource.request) { data, response, error in
            do {
                completion(.Success(try A(data: data)))
            }
            catch let error as JSONError {
                completion(.Error(error))
            }
            catch let error as NSError {
                completion(.Error(.UnexpectedError(error)))
            }
            }.resume()
    }
    
    class func search(query: String) -> Resource<WSDC.SearchResults> {
        let resource = Resource<WSDC.SearchResults>(
            url: WebService.wsdcBaseURL.URLByAppendingPathComponent("/lookup/find"),
            method: .POST
        )
        
        resource.request.addFormParameters(["q": query])
        
        return resource
    }
    
    class func competitor(wsdcId: Int) -> Resource<WSDC.Competitor> {
        let resource = Resource<WSDC.Competitor>(
            url: WebService.wsdcBaseURL.URLByAppendingPathComponent("/lookup/find"),
            method: .POST
        )
        
        resource.request.addFormParameters(["num": "\(wsdcId)"])
        
        return resource
    }
}