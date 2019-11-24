//
//  ResourceViewModel.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Combine
import Foundation

@available(OSX 10.15, iOS 13, *)
public struct ResourceViewModel<T> {
    public let resource: Resource<T>
    public let hasDataToDisplay: Property<Bool>

    public init(resource: Resource<T>,
                hasDataToDisplay: @escaping (Loadable<T>) -> Bool) {
        self.resource = resource
        self.hasDataToDisplay = resource
            .map(hasDataToDisplay)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

@available(OSX 10.15, iOS 13, *)
public extension ResourceViewModel {
    var isLoading: Property<Bool> {
        return resource
            .map({ $0.isLoading })
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    var shouldShowActivity: Property<Bool> {
        return isLoading.zip(hasDataToDisplay)
            .map({ $0.0 && !$0.1 })
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    var shouldShowRefresh: Property<Bool> {
        return isLoading.zip(hasDataToDisplay)
            .map({ $0.0 && $0.1 })
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    var shouldShowError: Property<Bool> {
        return resource
            .map({ $0.error != nil })
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    var shouldShowData: Property<Bool> {
        return shouldShowError.zip(resource)
            .map({ !$0.0 && $0.1.entity != nil })
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    var errorString: Property<String> {
        return resource
            .map({ resource in
                guard let error = resource.error else { return "" }
                return "An error occured: \(error.localizedDescription)"
            }).removeDuplicates()
            .eraseToAnyPublisher()
    }
}
