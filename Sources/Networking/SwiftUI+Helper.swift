//
//  SwiftUI+Helper.swift
//  Networking
//
//  Created by Eugene Peschard on 09/03/2020.
//

import SwiftUI

@available(OSX 10.15, iOS 13, *)
public extension Binding where Value: Equatable {
    func dispatched<State>(to state: Store<State>,
                           _ keyPath: WritableKeyPath<State, Value>) -> Self {
        return .init(get: { () -> Value in
            self.wrappedValue
        }, set: { value in
            self.wrappedValue = value
            state[keyPath] = value
        })
    }
}
