//
//  Helpers.swift
//  Networking
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Combine
import Foundation

public typealias ValueClosure<V> = (V) -> Void

@available(OSX 10.15, iOS 13, *)
public typealias Property<T> = AnyPublisher<T, Never>

@available(OSX 10.15, iOS 13, *)
public typealias Resource<T> = CurrentValueSubject<Loadable<T>, Never>
