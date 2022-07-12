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
    private var refreshTokenRetry = 0
    public static let shared = APIClient()
    private init() {}

    public func start<C: Call>(call: C, baseURL: URL, result: @escaping (Result<C.ReturnType, Error>) -> Void) {

        guard let stringNonPercentEncoding = baseURL.appendingPathComponent(call.path).absoluteString.removingPercentEncoding else {
            DispatchQueue.main.async {
                result(.failure(APIClientError.failedToRemovePercentEncoding))
            }
            return
        }

        // ADD QueryParameters
        var urlComponents = URLComponents(string: stringNonPercentEncoding)
        if let parameters = call.queryParameters {
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

        #if DEBUG
        print("REQUEST>>>\n\(request.description)")
        #endif

        // Add Headers
        call.headers.forEach({
            request.addValue($0.value, forHTTPHeaderField: $0.key)
        })

        #if DEBUG
        print("HEADERS>>>\n\(request.allHTTPHeaderFields?.description ?? "")")
        #endif

        // Add Body
        if let _ = call.body {
            do {
                let httpBody = try call.encodeBody()
                request.httpBody = httpBody
                #if DEBUG
                print("BODY>>>\n\(String(data: httpBody, encoding: String.Encoding.utf8)! as NSString)")
                #endif
            } catch {
                result(.failure(error))
            }
        } else {
            #if DEBUG
            print("BODY>>>\n EMPTY")
            #endif
        }

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

            if let httpURLResponse = urlResponse as? HTTPURLResponse {
                let statusCode = httpURLResponse.statusCode
                print("STATUS CODE>>>\n\(statusCode)")
                print("HEADERS>>>\n\(httpURLResponse.allHeaderFields)")

                // Handle status code errors
                if statusCode >= 300 && statusCode < 600 {
                    if statusCode == 401 {
                        if self.refreshTokenRetry > 0 {
                        } else {
                            self.refreshTokenRetry += 1
                            call.handleRefreshToken { error in
                                if error != nil {
                                    let handledError = self.handleError(for: call, from: data, statusCode: statusCode)
                                    result(.failure(handledError))
                                    return
                                }

                                self.refreshTokenRetry = 0
                                self.start(call: call, baseURL: baseURL, result: result)
                                return
                            }
                            return
                        }
                    }

                    let handledError = self.handleError(for: call, from: data, statusCode: statusCode)
                    result(.failure(handledError))
                    return
                }
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

    private func handleError<C: Call>(for call: C, from data: Data, statusCode: Int) -> Error {
        do {
            let errorMessage = try call.parseErrorMessage(from: data)
            return NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        } catch {
            return error
        }
    }
}
