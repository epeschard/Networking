//
//  Helpers.swift
//  Networking
//
//  Created by Eugene Peschard on 09/03/2020.
//

import Foundation
import Combine
import SwiftUI

// MARK: - General

public extension ProcessInfo {
    var isRunningTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}

public extension String {
    func localized(_ locale: Locale) -> String {
        let localeId = String(locale.identifier.prefix(2))
        guard let path = Bundle.main.path(forResource: localeId, ofType: "lproj"),
            let bundle = Bundle(path: path) else {
            return NSLocalizedString(self, comment: "")
        }
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
}

// MARK: - View Inspection helper

@available(OSX 10.15, iOS 13, *)
internal final class Inspection<V> where V: View {
    let notice = PassthroughSubject<UInt, Never>()
    var callbacks = [UInt: (V) -> Void]()

    func visit(_ view: V, _ line: UInt) {
        if let callback = callbacks.removeValue(forKey: line) {
            callback(view)
        }
    }
}
