//
//  UIImage+Ext.swift
//  MovieSearch
//
//  Created by Kenny Schlagel on 5/26/18.
//

import Foundation

import UIKit

extension UIImage {
    /**
     This downloads an image from a url
     - parameter url: A string value of the image url
     - parameter completionHandler: The handler to be called upon success or failure of the download task
     */
    static func downloadImageFromUrl(_ url: String, completionHandler: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: url) else {
            completionHandler(.none)
            return
        }
        
        let dataTask: URLSessionDataTask = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            guard
                let httpStatusCode = response as? HTTPURLResponse, httpStatusCode.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data,
                error == nil,
                let image = UIImage(data: data)
            else {
                completionHandler(nil)
                return
            }
            completionHandler(image)
        })
        dataTask.resume()
    }
}
