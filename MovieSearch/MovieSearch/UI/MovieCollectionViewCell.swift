//
//  MovieCollectionViewCell.swift
//  MovieSearch
//
//  Created by Kenny Schlagel on 5/25/18.
//

import UIKit

class MovieCollectionViewCell: UICollectionViewCell {
    public static let reuseIdentifier = "MovieCell"

    @IBOutlet weak var posterImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    func showLoadingIndicator() {
        loadingIndicator.alpha = 1.0
        loadingIndicator.startAnimating()
    }

    func hideLoadingIndicator() {
        loadingIndicator.alpha = 0
        loadingIndicator.stopAnimating()
    }

    /**
     This method configure's the cell's UI with movie data - for now just the title.  Ideally you would just call this method if you needed to add more data to the cell's UI in the future, instead of having to set properties from the collectionview individually
     - parameter with: An optional movie struct, if available
     */
    func configure(with movie: Movie?) {
        DispatchQueue.main.async { [weak self]  in
            guard let unwrappedSelf = self else { return }

            if let m = movie {
                unwrappedSelf.titleLabel.text = m.title
            }
        }
    }
}
