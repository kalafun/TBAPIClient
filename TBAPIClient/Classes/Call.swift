//
//  Call.swift
//  APIClient
//
//  Created by Tomas Bobko on 21.05.20.
//  Copyright © 2020 Tomas Bobko. All rights reserved.
//

public protocol Call: AnyObject {
    typealias Parameters = [String: String]

    associatedtype ReturnType: Any, Decodable

    var path: String { get }
    var offlineData: Data? { get }
    var method: CallMethod { get }
    var parameters: Parameters? { get }
    var customDateFormatter: DateFormatter? { get }
    var headers: [String: String]? { get }

    func parse(data: Data) throws -> ReturnType
}

public enum CallMethod: String {
    case get = "GET"
    case post = "POST"
}

public extension Call {

    var offlineData: Data? { nil }
    var parameters: Parameters? { nil }
    var headers: [String: String]? { nil }
    var customDateFormatter: DateFormatter? { nil }

    func parse(data: Data) throws -> ReturnType {
        let decoder = JSONDecoder()

        if customDateFormatter != nil {
            setDecodingStrategy(for: decoder)
        }

        let objects: ReturnType = try decoder.decode(ReturnType.self, from: data)
        return objects
    }

    private func setDecodingStrategy(for decoder: JSONDecoder) {
        decoder.dateDecodingStrategy = .custom({ [weak self] decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = self?.customDateFormatter?.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Cannot decode date string \(dateString)")
        })
    }
}
