//
//  ImageFetchOperation.swift
//  MovieSearch
//
//  Created by Kenny Schlagel on 5/26/18.
//

import UIKit

/**
 This class handles the operation for downloading an image from a URL or falling back to a default image
 */
class ImageFetchOperation: Operation {
    var loadingCompleteHandler: ((UIImage) -> ())?
    
    var url: String?
    var image: UIImage?

    init(url: String?) {
        self.url = url
    }

    override func main() {
        guard !isCancelled else { return }

        if let unwrappedURl = url {
            UIImage.downloadImageFromUrl(unwrappedURl) { [weak self] (image) in
                guard let unwrapped = self, !unwrapped.isCancelled, let image = image else { return }

                unwrapped.image = image
                unwrapped.loadingCompleteHandler?(image)
            }
        } else { // url was nil, use image plachodler
            if let image = UIImage(named: "No-Image") {
                loadingCompleteHandler?(image)
            }
        }
    }
}
