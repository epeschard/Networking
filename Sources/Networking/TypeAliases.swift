//
//  Helpers.swift
//  Networking
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Combine

@available(OSX 10.15, iOS 13, *)
public typealias Store<State> = CurrentValueSubject<State, Never>
