//
//  JLoggerApp.swift
//  JLogger
//
//  Created by LONG JUN on 2025/6/20.
//

import SwiftUI
import JLogger

@main
struct JLoggerApp: App {
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                JLoggerView()
                    .onReceive(timer) { _ in
                        generateRandomLog()
                    }
            }
        }
    }
    
    private func generateRandomLog() {
        let levels: [JLogger.LogLevel] = [.info, .warning, .error, .debug]
        let actions = ["User Click", "Page Load", "Data Update", "Network Request", "Cache Clear"]
        let components = ["Home", "Settings", "Profile", "Messages", "Search"]
        let status = ["Success", "Failed", "Timeout", "Unauthorized", "Not Found"]
        
        let randomLevel = levels.randomElement() ?? .info
        let randomAction = actions.randomElement() ?? ""
        let randomComponent = components.randomElement() ?? ""
        let randomStatus = status.randomElement() ?? ""
        let randomId = Int.random(in: 1000...9999)
        let randomDuration = Double.random(in: 0.1...2.0)
        
        var logMessage = ""
        
        switch randomLevel {
        case .info:
            logMessage = "\(randomAction) - \(randomComponent) [ID:\(randomId)]"
        case .warning:
            logMessage = "\(randomComponent) slow response time (\(String(format: "%.2f", randomDuration))s)"
        case .error:
            logMessage = "\(randomComponent) \(randomAction) \(randomStatus) [Error Code:\(randomId)]"
        case .debug:
            logMessage = "[\(randomComponent)] Memory Usage: \(Int.random(in: 50...200))MB"
        }
        
        JLogger.shared.log(logMessage, randomLevel)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("[\(randomLevel.rawValue)] \(dateFormatter.string(from: Date())) \(logMessage)")
    }
}
