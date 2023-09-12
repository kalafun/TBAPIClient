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
    associatedtype BodyType: Any, Encodable

    var path: String { get }
    var offlineData: Data? { get }
    var method: CallMethod { get }
    var queryParameters: Parameters? { get }
    var customDateFormatter: DateFormatter? { get }
    var headers: [String: String] { get }
    var body: BodyType? { get }
    var isRefreshTokenCall: Bool { get }

    func parse(data: Data) throws -> ReturnType
    func encodeBody() throws -> Data
    func parseErrorMessage(from data: Data) throws -> String
    func handleRefreshToken(completion: @escaping (Error?) -> Void)
}

public enum CallMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public extension Call {

    var offlineData: Data? { nil }
    var queryParameters: Parameters? { nil }
    var headers: [String: String] { [:] }
    var customDateFormatter: DateFormatter? { nil }
    var body: BodyType? { nil }
    var isRefreshTokenCall: Bool { false }

    func encodeBody() throws -> Data {
        let encoder = JSONEncoder()

        if customDateFormatter != nil {
            setDateEncodingStrategy(for: encoder)
        }

        let httpBody = try encoder.encode(body)
        return httpBody
    }

    func parse(data: Data) throws -> ReturnType {
        let decoder = JSONDecoder()

        if customDateFormatter != nil {
            setDateDecodingStrategy(for: decoder)
        }

        let objects: ReturnType = try decoder.decode(ReturnType.self, from: data)
        return objects
    }

    private func setDateEncodingStrategy(for encoder: JSONEncoder) {
        encoder.dateEncodingStrategy = .custom({ [weak self] date, encoder in
            let stringDate = self?.customDateFormatter?.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(stringDate)
        })
    }

    private func setDateDecodingStrategy(for decoder: JSONDecoder) {
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
