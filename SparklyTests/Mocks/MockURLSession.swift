//
//  MockURLSession.swift
//  SparklyTests
//
//  Created by Austin Drummond on 12/6/25.
//

import Foundation

class MockURLProtocol: URLProtocol {
    static var mockResponses: [URL: (data: Data, response: URLResponse)] = [:]
    static var mockErrors: [URL: Error] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        if let error = MockURLProtocol.mockErrors[url] {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let mock = MockURLProtocol.mockResponses[url] {
            client?.urlProtocol(self, didReceive: mock.response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: mock.data)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let error = NSError(
            domain: "MockURLProtocol",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "No mock response for \(url)"]
        )
        client?.urlProtocol(self, didFailWithError: error)
    }

    override func stopLoading() {}

    static func reset() {
        mockResponses = [:]
        mockErrors = [:]
    }

    static func mockSuccess(url: URL, data: Data, statusCode: Int = 200) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        mockResponses[url] = (data: data, response: response)
    }

    static func mockError(url: URL, error: Error) {
        mockErrors[url] = error
    }
}

extension URLSession {
    static var mock: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
