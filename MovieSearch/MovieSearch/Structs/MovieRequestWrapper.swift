//
//  MovieRequestWrapper.swift
//  MovieSearch
//
//  Created by Kenny Schlagel on 5/26/18.
//

import Foundation

struct MovieRequestWrapper: Codable {
    var page: Int
    var totalResults: Int
    var totalPages: Int
    var results: [Movie]
}
