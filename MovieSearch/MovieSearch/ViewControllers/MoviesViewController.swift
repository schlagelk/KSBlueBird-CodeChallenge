//
//  MoviesViewController.swift
//  MovieSearch
//
//  Created by Kenny Schlagel on 5/25/18.
//

import UIKit

class MoviesViewController: UIViewController {

    // for making movie requests
    var movies: [Movie] = []
    var requestWrapper: MovieRequestWrapper?
    var fetcher: MovieFetcher?
    var searchString: String = ""

    // for prefetching
    let loadingQueue = OperationQueue()
    var loadingOperations = [IndexPath: ImageFetchOperation]()

    // for paginating
    var requestInProgress = false
    var lastIndexPathRow: Int = 0

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!

    // the container for more details when cells are tapped
    @IBOutlet weak var movieDetailContainer: UIView!
    @IBOutlet weak var overviewText: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailContainerTopConstraint: NSLayoutConstraint!

    let containerTopOffset: CGFloat = -140
    var spinner: UIActivityIndicatorView?
    
    // for customizing collectionview appearance
    fileprivate let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 30.0, right: 10.0)
    fileprivate let itemsPerRow: CGFloat = 2

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.prefetchDataSource = self

        // fetcher is nil by default, but can be passed in if needed
        if fetcher == nil {
            let config = URLSessionConfiguration.default
            // on our own thread, though
            let queue = OperationQueue()
            queue.qualityOfService = .userInitiated
            let urlSession = URLSession(configuration: config, delegate: nil, delegateQueue: queue)

            fetcher = MovieFetcher(session: urlSession)
        }

        // set up activity indicator
        if spinner == .none {
            let spinna = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            spinna.frame = CGRect(x: self.view.center.x - 15, y: -800, width: 40.0, height: 40.0)
            spinna.transform = CGAffineTransform(scaleX: 2, y: 2)
            spinna.alpha = 0.0
            view.addSubview(spinna)
            spinner = spinna
        }
    }

    /**
     This method fetches movies from the specified source in the view controller's fetcher property.
     - parameter from: The urlRequest object where the request should be made (example, a server)
     */
    func fetchMovies(from urlRequest: URLRequest) {
        guard let movieFetcher = fetcher else { return }

        self.requestInProgress = true
        movieFetcher.fetchData(urlRequest: urlRequest) {data, error in
            if let d = data {
                if let wrapper = self.decodeResponse(data: d) {
                    self.requestWrapper = wrapper
                    self.movies.append(contentsOf: wrapper.results)

                    DispatchQueue.main.async { [unowned self] in
                        if self.requestWrapper?.page == 1 {
                            self.collectionView.reloadData()
                        } else {// avoid collectionView.reloadData() when calling page2, cause it looks choppy when reloading collection
                            let indexPaths: [IndexPath] = self.createIndexPathsForPaginatedResults(results: wrapper.results, from: self.lastIndexPathRow)
                            self.collectionView.performBatchUpdates({ () -> Void in
                                self.collectionView.insertItems(at: indexPaths)
                            }, completion: nil)
                        }
                    }
                } else {
                    // TODO, handle decoding error
                    print("Error decoding response")
                }
            } else if let e = error {
                // TODO, handle error
                print("Network error - \(e)")
            }
            DispatchQueue.main.async {
                self.hideSpinner()
            }
            self.requestInProgress = false
        }
    }

    /**
     This method attempts to decode a data object (for example, a response from a server).

     - parameter data: The response data to decode
     - returns: A MovieRequestWrapper struct which contains pagination data and a nested array of Movies
     */
    func decodeResponse(data: Data) -> MovieRequestWrapper? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(MovieRequestWrapper.self, from: data)
        } catch {
            // TODO - handle error
            print(error)
        }
        return nil
    }

    /**
     This starts and shows the view controller's activity indicator
     */
    func showSpinner() {
        spinner?.startAnimating()
        spinner?.alpha = 1.0
        UIView.animate(withDuration: 0.25) { [spinna = spinner] in
            spinna?.frame.origin.y = self.view.center.y - 50
        }
    }

    /**
     Stops and hides the view controller's activity indicator
     */
    func hideSpinner() {
        spinner?.stopAnimating()
        spinner?.alpha = 0.0
    }

    /**
     Resets and hides the overview container view
     */
    func resetOverviewContainer() {
        detailContainerTopConstraint.constant = containerTopOffset
        overviewText.setContentOffset(.zero, animated: false)
    }

    /**
     Creates indexPaths to append to use when performing batch updates on a collectionview's data source.

     - parameter results: The next objects to append to the data source - for example, those receied from the next server response in a paginated response
     - parameter from: The starting point where the returned index paths should begin.
     - returns: A sequence of index paths starting from the the indexPath used in the from parameter
     */
    func createIndexPathsForPaginatedResults(results: [Movie], from lastIndexPathRow: Int) -> [IndexPath] {
        var indexPaths: [IndexPath] = []
        for (index, _) in results.enumerated()  {
            var row = 0
            if lastIndexPathRow != 0 {
                row = lastIndexPathRow + 1 + index
            }
            let path = IndexPath(row: row, section: 0)
            indexPaths.append(path)
        }
        return indexPaths
    }
}


// MARK: UICollectionViewDataSource
extension MoviesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MovieResultsHeaderView.reuseIdentifier, for: indexPath) as? MovieResultsHeaderView {
            if let results = requestWrapper?.totalResults {
                header.headerTitleLabel.text = "\(results) results"
            } else {
                header.headerTitleLabel.text = "Enter a search to find a movie!"
            }
            return header
        }
        return UICollectionReusableView()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCollectionViewCell.reuseIdentifier, for: indexPath) as? MovieCollectionViewCell {
            cell.configure(with: movies[indexPath.row])
            cell.showLoadingIndicator()

            // When our data is loaded we just need to update the cell's image
            let imageClosure: (UIImage?) -> () = { [unowned self] (image) in
                DispatchQueue.main.async {
                    cell.posterImage.image = image
                    cell.hideLoadingIndicator()
                }
                self.loadingOperations.removeValue(forKey: indexPath)
            }

            // Do we have an operation already?
            if let operation = loadingOperations[indexPath] {
                // With data?
                if let image = operation.image {
                    DispatchQueue.main.async {
                        cell.posterImage.image = image
                        cell.hideLoadingIndicator()
                    }
                    loadingOperations.removeValue(forKey: indexPath)
                } else {
                    // No data loaded yet, so add the completion closure to update the cell once the data arrives
                    operation.loadingCompleteHandler = imageClosure
                }
            } else {
                // create a url
                var posterPath = movies[indexPath.row].posterPath
                if let path = posterPath {
                    posterPath = MovieFetcher.Router.image(path).route
                }
                // create an operation
                let operation = ImageFetchOperation(url: posterPath)
                operation.loadingCompleteHandler = imageClosure
                // add it to queue
                loadingQueue.addOperation(operation)
                loadingOperations[indexPath] = operation
            }

            return cell
        }
        // just to avoid a force unwrap above, but ideally would need fallback cell
        return UICollectionViewCell()
    }
}

// MARK: UICollectionViewDelegate
extension MoviesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard !requestInProgress else { return }
        guard requestWrapper?.page != requestWrapper?.totalPages else { return }

        if (indexPath.row + 1) == movies.count {
            if let text = textField.text, text.count > 0, let queryString = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let page = requestWrapper?.page {
                let route = MovieFetcher.Router.movie(queryString).route + "&page=\(page + 1)"
                if let request = MovieFetcher.createURLRequest(route: route) {
                    lastIndexPathRow = indexPath.row
                    fetchMovies(from: request)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Cancel and remove and existing operations to ensure we aren't wasting resources
        if let dataLoader = loadingOperations[indexPath] {
            dataLoader.cancel()
            loadingOperations.removeValue(forKey: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = movies[indexPath.row]
        overviewText.text = movie.overview
        titleLabel.text = movie.title
        detailContainerTopConstraint.constant = 0

        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: UICollectionViewDataSourcePrefetching
extension MoviesViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let _ = loadingOperations[indexPath] {
                return
            }
            // create a url
            var posterPath = movies[indexPath.row].posterPath
            if let path = posterPath {
                posterPath = MovieFetcher.Router.image(path).route
            }
            // create an operation (note - no need to add image closure here, it will happen at cellForRowAt)
            let operation = ImageFetchOperation(url: posterPath)
            // add it to queue
            loadingQueue.addOperation(operation)
            loadingOperations[indexPath] = operation
        }
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let dataLoader = loadingOperations[indexPath] {
                dataLoader.cancel()
                loadingOperations.removeValue(forKey: indexPath)
            }
        }
    }
}


// MARK: UICollectionViewDelegateFlowLayout
extension MoviesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        // take itemsPerRow and space out the cell nicely
        let padding = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - padding
        let widthPerItem = availableWidth / itemsPerRow

        return CGSize(width: widthPerItem, height: widthPerItem * 1.5) // make it more long than wide
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

// MARK: UITextFieldDelegate
extension MoviesViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        resetOverviewContainer()
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}


// MARK: UITextFieldDelegate
extension MoviesViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        if let text = textField.text, text.count > 0, let queryString = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            if searchString != queryString {
                movies.removeAll()
                collectionView.reloadData()
            }
            searchString = queryString
            if let request = MovieFetcher.createURLRequest(route: MovieFetcher.Router.movie(searchString).route) {
                resetOverviewContainer()
                showSpinner()
                fetchMovies(from: request)
            }
        }

        return true
    }
}

