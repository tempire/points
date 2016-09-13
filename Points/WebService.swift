//
//  WebService.swift
//  Points
//
//  Created by Glen Hinkle on 7/5/16.
//  Copyright © 2016 Zombie Dolphin. All rights reserved.
//

import Foundation

struct Resource<A: JSONStruct>: CustomStringConvertible {
    let request: NSMutableURLRequest
    
    var description: String {
        return "request: \(request)"
    }
    
    init(url: URL, method: NSMutableURLRequest.Method) {
        request = NSMutableURLRequest(
            url: url,
            method: method
        )
    }
}

enum ResourceResult<A: JSONStruct> {
    case success(A)
    case error(JSONError)
    case networkError(NSError)
}

class WebService {
    static let wsdcBaseURL = URL(string: "http://wsdc-points.us-west-2.elasticbeanstalk.com")!
    
    static var session = URLSession.shared
    
    class func load<A: JSONStruct>(_ resource: Resource<A>, completion: @escaping (ResourceResult<A>)->Void) {
        
        resource.request.setHeader(.date(Date()))
        
        WebService.session.dataTask(with: resource.request as URLRequest, completionHandler: { data, response, error in
            if let error = error as? NSError {
                return completion(
                    .networkError(
                        NSError(domain: NSError.Domain.network.description, code: error.code, userInfo: error.userInfo)))
            }
            
            do {
                completion(.success(try A(data: data)))
            }
            catch let error as JSONError {
                completion(.error(error))
            }
            catch let error as NSError {
                completion(.error(JSONError.unexpectedError(error)))
            }
            }) .resume()
    }
    
    class func search(_ query: String) -> Resource<WSDC.SearchResults> {
        let resource = Resource<WSDC.SearchResults>(
            url: WebService.wsdcBaseURL.appendingPathComponent("/lookup/find"),
            method: .POST
        )
        
        resource.request.addFormParameters(["q": query as AnyObject])
        
        return resource
    }
    
    class func competitor(_ wsdcId: Int) -> Resource<WSDC.Competitor> {
        let resource = Resource<WSDC.Competitor>(
            url: WebService.wsdcBaseURL.appendingPathComponent("/lookup/find"),
            method: .POST
        )
        
        resource.request.addFormParameters(["num": "\(wsdcId)" as AnyObject])
        
        return resource
    }
}
