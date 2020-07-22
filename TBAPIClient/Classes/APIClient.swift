//
//  APIClient.swift
//  APIClient
//
//  Created by Tomas Bobko on 21.05.20.
//  Copyright © 2020 Tomas Bobko. All rights reserved.
//

import Foundation

enum APIClientError: Error {
    case invalidURL
    case responseDataNil
    case failedToRemovePercentEncoding
}

public class APIClient {

    private let session = URLSession(configuration: .default)

    public static let shared = APIClient()
    private init() { }

    public func start<C: Call>(call: C, baseURL: URL, result: @escaping (Result<C.ReturnType, Error>) -> Void) {

        guard let stringNonPercentEncoding = baseURL.appendingPathComponent(call.path).absoluteString.removingPercentEncoding else {
            DispatchQueue.main.async {
                result(.failure(APIClientError.failedToRemovePercentEncoding))
            }
            return
        }

        var urlComponents = URLComponents(string: stringNonPercentEncoding)

        if let parameters = call.parameters {
            urlComponents?.queryItems = parameters.compactMap({ URLQueryItem(name: $0.key, value: $0.value )})
        }

        guard let url = urlComponents?.url else {
            DispatchQueue.main.async {
                #if DEBUG
                print(APIClientError.invalidURL)
                #endif
                result(.failure(APIClientError.invalidURL))
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = call.method.rawValue

        if let headers = call.headers {
            headers.forEach({
                request.addValue($0.value, forHTTPHeaderField: $0.key)
            })
        }

        #if DEBUG
        print("REQUEST>>>\n\(request.url?.absoluteString ?? "")")
        #endif

        session.dataTask(with: request) { data, urlResponse, error in
            if let error = error {
                DispatchQueue.main.async {
                    #if DEBUG
                    print(error)
                    #endif
                    result(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    #if DEBUG
                    print(APIClientError.responseDataNil)
                    #endif
                    result(.failure(APIClientError.responseDataNil))
                }
                return
            }

            print("RESPONSE>>>\n" + String(data: data, encoding: String.Encoding.utf8)! as NSString)

            do {
                let parsedObject = try call.parse(data: data)
                DispatchQueue.main.async {
                    result(.success(parsedObject))
                }
            } catch {
                DispatchQueue.main.async {
                    #if DEBUG
                    print(error)
                    #endif
                    result(.failure(error))
                }
                return
            }
        }.resume()
    }
}
