//
//  URLSessionProtocols.swift
//  MovieSearch
//
//  Created by Kenny Schlagel on 5/25/18.
//

import Foundation


protocol WebRequestable {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: WebRequestable {}
