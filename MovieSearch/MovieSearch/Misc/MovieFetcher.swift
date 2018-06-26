//
//  MovieFetcher.swift
//  MovieSearch
//
//  Created by Kenny Schlagel on 5/25/18.
//

import Foundation

/**
This class is responsible for fetching both movie and poster data.  It includes a nested url formatter called Router which is responsible for formating the appropriate urls relative to the Movie model.

    TODO, load urls from an environment manager, use URLComponents and inject api_key at build time?

 */
class MovieFetcher {

    var session: WebRequestable

    typealias callback = (_ data: Data?, _ error: Error?) -> Void

    enum Router {
        case movie(String)
        case image(String)

        var route: String {
            switch self {
            case .movie(let query): return "&query=\(query)" // insert your url and api keys
            case .image(let hash): return "\(hash)" // insert your url and api keys
            }
        }
    }

    init(session: WebRequestable) {
        self.session = session
    }

    func fetchData(urlRequest: URLRequest, callback: @escaping callback) {
        //todo
        let task = session.dataTask(with: urlRequest) {data, reponse, error in
            callback(data, error)
        }
        task.resume()
    }

    /**
     This creates a URLRequest object using a url string and a specified http method
     - parameter route: A string value of the route to be called
     - parameter method: The http method to be used when making the request.  Default is GET
     - returns: Optional URLRequest if success
     */
    static func createURLRequest(route: String, method: String = "GET") -> URLRequest? {
        guard let url = URL(string: route) else { return .none }
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = method
        return request as URLRequest
    }
}
