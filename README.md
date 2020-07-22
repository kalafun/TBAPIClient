# TBAPIClient - Lightweight REST API Client written in Swift

[![Version](https://img.shields.io/cocoapods/v/TBAPIClient.svg?style=flat)](https://cocoapods.org/pods/TBAPIClient)
[![License](https://img.shields.io/cocoapods/l/TBAPIClient.svg?style=flat)](https://cocoapods.org/pods/TBAPIClient)
[![Platform](https://img.shields.io/cocoapods/p/TBAPIClient.svg?style=flat)](https://cocoapods.org/pods/TBAPIClient)

The idea is that you just define the data model you know you will receive the data as. Then create another structure conforming to the `Call` protocol and implement all variables and functions to your needs. Then you just call the `APIClient.shared.start()` function with your `struct` and the `baseURL` and you handle the response in the closure.

## Example

```swift
struct GetCustomersResponse: Decodable {
    let customers: [Customer]
}

struct Customer: Decodable {
    let id: String
    let name: String
    let age: Int
    let address: String
}

struct GetCustomersCall: Call {
    typealias ReturnType = GetCustomersResponse
    var path: String { "/api/getCustomers" }
    var method: CallMethod = .get
}

...
// somewhere in the code
APIClient.shared.start(GetCustomersCall(), baseURL: baseUrl) { getCustomersResult in
    switch getCustomersResult {
        case .success(let result):
        // result handling
        case .failure(let error):
        // error handling
    }
}
```

## Requirements

## Installation

TBAPIClient is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'TBAPIClient'
```

## Author

Tomáš Bobko, kalafun@gmail.com

## License

TBAPIClient is available under the MIT license. See the LICENSE file for more info.
