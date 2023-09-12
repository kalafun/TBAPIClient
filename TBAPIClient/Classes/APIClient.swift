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
    private init() {}

    public func start<C: Call>(call: C, baseURL: URL, result: @escaping (Result<C.ReturnType, Error>) -> Void) {

        var url: URL
        var request: URLRequest

        do {
            url = try prepareURL(baseURL: baseURL, call: call)
            request = try prepareRequest(url: url, call: call)
        } catch {
            DispatchQueue.main.async {
                result(.failure(error))
            }
            return
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

            self.handleResponse(urlResponse: urlResponse, call: call, data: data, baseURL: baseURL, result: result)
        }.resume()
    }

    func prepareURL<C: Call>(baseURL: URL, call: C) throws -> URL {
        guard let stringNonPercentEncoding = baseURL.appendingPathComponent(call.path).absoluteString.removingPercentEncoding else {
            throw APIClientError.failedToRemovePercentEncoding
        }

        // ADD QueryParameters
        var urlComponents = URLComponents(string: stringNonPercentEncoding)
        if let parameters = call.queryParameters {
            urlComponents?.queryItems = parameters.compactMap({ URLQueryItem(name: $0.key, value: $0.value )})
        }
        guard let url = urlComponents?.url else {
#if DEBUG
            print(APIClientError.invalidURL)
#endif
            throw APIClientError.invalidURL
        }

        return url
    }

    func prepareRequest<C: Call>(url: URL, call: C) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = call.method.rawValue

#if DEBUG
        print("REQUEST>>>\n\(request.httpMethod ?? "") \(request.description)")
#endif

        // Add Headers
        call.headers.forEach({
            request.addValue($0.value, forHTTPHeaderField: $0.key)
        })

#if DEBUG
        print("HEADERS>>>\n\(request.allHTTPHeaderFields?.description ?? "")")
#endif

        if let _ = call.body {
            let httpBody = try call.encodeBody()
            request.httpBody = httpBody
#if DEBUG
            print("BODY>>>\n\(String(data: httpBody, encoding: String.Encoding.utf8)! as NSString)")
#endif
        } else {
#if DEBUG
            print("BODY>>>\n EMPTY")
#endif
        }

        return request
    }

    @available(iOS 15.0, *)
    public func start<C: Call>(call: C, baseURL: URL) async -> Result<C.ReturnType, Error> {
        var url: URL
        var request: URLRequest

        do {
            url = try prepareURL(baseURL: baseURL, call: call)
            request = try prepareRequest(url: url, call: call)
        } catch {
            return .failure(error)
        }

        do {
            let (data, response) = try await session.data(for: request)

            let result = try await withCheckedThrowingContinuation { continuation in
                handleResponse(urlResponse: response, call: call, data: data, baseURL: baseURL) { result in
                    continuation.resume(with: result)
                }
            }

            return .success(result)
        } catch {
            return .failure(error)
        }
    }

    private static var refreshTokenCount = 2

    private func handleResponse<C: Call>(
        urlResponse: URLResponse?,
        call: C,
        data: Data,
        baseURL: URL,
        result: @escaping (Result<C.ReturnType, Error>) -> Void) {
            guard let httpURLResponse = urlResponse as? HTTPURLResponse else { return }

            let statusCode = httpURLResponse.statusCode
            print("RESPONSE>>>")
            print("STATUS CODE>>>\n\(statusCode)")
            print("HEADERS>>>\n\(httpURLResponse.allHeaderFields)")

            // Handle Unauthorized Error
            if statusCode == 401 {
                Self.refreshTokenCount -= 1

                if Self.refreshTokenCount == 1 {
                    call.handleRefreshToken { error in
                        if error != nil {
                            let handledError = self.handleError(for: call, from: data, statusCode: statusCode)
                            DispatchQueue.main.async {
                                result(.failure(handledError))
                            }
                            return
                        }

                        self.start(call: call, baseURL: baseURL, result: result)
                        return
                    }
                    return
                } else {
                    let handledError = self.handleError(for: call, from: data, statusCode: statusCode)
                    DispatchQueue.main.async {
                        result(.failure(handledError))
                    }
                    return
                }
            }
            // Handle Other Error Cases
            else if statusCode >= 300 && statusCode < 600 {
                let handledError = self.handleError(for: call, from: data, statusCode: statusCode)
                DispatchQueue.main.async {
                    result(.failure(handledError))
                }
                return
            }

            Self.resetRefreshTokenCount()
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
        }

    private static func resetRefreshTokenCount() {
        Self.refreshTokenCount = 2
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
