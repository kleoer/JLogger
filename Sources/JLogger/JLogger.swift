//
//  JLogger.swift
//  JLogger
//
//  Created by kleoer on 2025/6/19.
//

import SwiftUI

public class JLogger: ObservableObject, @unchecked Sendable {

    public enum LogLevel: String {
        case debug = "Debug"
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
    }

    public static let shared = JLogger()
    
    @Published var logs: [LogEntry] = []
    @Published var isMinimized = true
    
    struct LogEntry: Identifiable, Sendable, Equatable {
        let id = UUID()
        let timestamp: Date
        let level: String
        let message: String
    }
    
    private init() {}
    
    public func log(_ message: String, _ level: LogLevel = .info) {
        let entry = LogEntry(timestamp: Date(), level: level.rawValue, message: message)
        DispatchQueue.main.async {
            self.logs.append(entry)
        }
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
}
