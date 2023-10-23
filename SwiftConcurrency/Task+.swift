//
//  Task+.swift
//  SwiftConcurrency
//
//  Created by JayHsia on 2023/10/21.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    public static func sleep(secounds: Double? = nil) async throws {
        let delay = secounds ?? Double((5...20).randomElement()!) * 0.1
        let nanoseconds = UInt64(delay * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
