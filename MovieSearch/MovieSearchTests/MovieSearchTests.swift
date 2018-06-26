//
//  MovieSearchTests.swift
//  MovieSearchTests
//
//  Created by Kenny Schlagel on 5/25/18.
//

import XCTest
@testable import MovieSearch

class MovieSearchTests: XCTestCase {
    // just partial mocks of these protocols for now
    class MockWebRequestable: WebRequestable {
        var session = MockSessionTask()

        func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            session = MockSessionTask()
            let path = Bundle(for: type(of: self)).path(forResource: "Response", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            completionHandler(data, nil, nil)
            return session
        }
    }

    class MockSessionTask: URLSessionDataTask {
        var didGetCounted = false

        override func resume() {
            self.didGetCounted = true
        }
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testImageFetchOperationReturnsFallbackImage() {
        // test no url
        let op = ImageFetchOperation(url: .none)
        let expectation = self.expectation(description: "ImageFetchFallback")
        var returnedImage: UIImage?
        let imageClosure: (UIImage?) -> () = {(image) in
            returnedImage = image
            expectation.fulfill()
        }
        op.loadingCompleteHandler = imageClosure
        op.start()
        wait(for: [expectation], timeout: 0.5)
        XCTAssertNotNil(returnedImage)
    }

    func testImageFetchOperationReturnsAnImageFromTheWeb() {

        // test passing in a real url
        let url = "https://avatars2.githubusercontent.com/u/11343005?s=400&u=29aac2831d9e2eb2661d64bcff213a520aee9eb2&v=4"
        let op2 = ImageFetchOperation(url: url)
        let expectation2 = self.expectation(description: "ImageFetchFallback2")
        let imageClosure2: (UIImage?) -> () = {(image) in
            expectation2.fulfill()
        }
        op2.loadingCompleteHandler = imageClosure2
        op2.start()
        wait(for: [expectation2], timeout: 1.0)
        XCTAssertNotNil(op2.image)
    }

    func testUIImageFailesCorrectly() {
        var returnedImage: UIImage?
        let expectation = self.expectation(description: "UIImageFails")
        UIImage.downloadImageFromUrl(".,.,.,./") { image in
            expectation.fulfill()
            returnedImage = image
        }
        wait(for: [expectation], timeout: 0.25)
        XCTAssertNil(returnedImage)

        let urlThatShouldFailWith404 = "https://github.com/schlagelk/Padd"
        var returnedImage2: UIImage?
        let expectation2 = self.expectation(description: "UIImageFails2")
        UIImage.downloadImageFromUrl(urlThatShouldFailWith404) { image in
            expectation2.fulfill()
            returnedImage2 = image
        }
        wait(for: [expectation2], timeout: 1.0)
        XCTAssertNil(returnedImage2)
    }

    func testMovieRoutesAreCreatedCorrectly() {
        let route1 = MovieFetcher.Router.image("/abcd").route
        XCTAssertTrue(route1 == "https://image.tmdb.org/t/p/w600_and_h900_bestv2/abcd")
        let route2 = MovieFetcher.Router.movie("potter").route
        XCTAssertTrue(route2 == "https://api.themoviedb.org/3/search/movie?api_key=2a61185ef6a27f400fd92820ad9e8537&query=potter")

        let request = MovieFetcher.createURLRequest(route: "https://api.themoviedb.org/3/search/movie?api_key=2a61185ef6a27f400fd92820ad9e8537&query=potter")
        XCTAssertNotNil(request)
    }

    func testWebRequestableProtocolIsCalled() {
        let mockWebRequestable = MockWebRequestable()

        let fetcher = MovieFetcher(session: mockWebRequestable)
        let fake = URLRequest(url: URL(string: "fake.url")!)
        let expectation = self.expectation(description: "MockCalled")
        fetcher.fetchData(urlRequest: fake) {data, error in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.10)
        XCTAssertTrue(mockWebRequestable.session.didGetCounted)
    }

    func testMoviesViewControllerDoesTheRightStuff() {
        let mockWebRequestable = MockWebRequestable()
        let fetcher = MovieFetcher(session: mockWebRequestable)

        let nav = UIStoryboard(name: "Movies", bundle: nil).instantiateInitialViewController() as! UINavigationController
        let vc = nav.viewControllers.first as! MoviesViewController
        XCTAssertNotNil(vc)
        vc.fetcher = fetcher
        // load the view
        _ = vc.view

        vc.textField.text = "potter"
        _ = vc.textFieldShouldReturn(vc.textField)
        XCTAssertFalse(vc.movies.isEmpty)
        vc.collectionView.reloadData()
    }
}
