//
//  Movie.swift
//  MovieSearch
//
//  Created by Kenny Schlagel on 5/25/18.
//

import Foundation

struct Movie: Codable {
    var title: String
    var overview: String
    var posterPath: String?
}
