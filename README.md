# JLogger

A lightweight in-app logger for iOS. JLogger provides a floating console that can be minimized, dragged, expanded, copied, and shared during runtime. It now supports both SwiftUI and UIKit integration while sharing the same logging core.

## Features

- 🎯 Floating console window
- 🔄 Real-time log updates
- 🎨 Beautiful UI with dark theme
- 📱 Minimizable and draggable interface
- 🎭 Multiple log levels (Debug, Info, Warning, Error)
- 📜 Auto-scrolling to latest logs
- 🧹 Clear logs functionality
- 🔒 Thread-safe logging
- 📋 One-tap log entry copying
- 📤 Share logs
- 🧩 Shared logger core for SwiftUI and UIKit
- 🪟 UIKit overlay support via `UIWindow`

## Requirements

- iOS 14.0+
- Swift 5.5+

## Installation

### Swift Package Manager

Add JLogger to your project through Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/kleoer/JLogger.git", from: "1.0.0")
]
```

## Logging

```swift
JLogger.shared.log("Hello, World!")
JLogger.shared.log("Debug message", .debug)
JLogger.shared.log("Warning: Low memory", .warning)
JLogger.shared.log("Error occurred", .error)
```

## SwiftUI Usage

Import `JLogger` and place `JLoggerView()` in your SwiftUI hierarchy:

```swift
import SwiftUI
import JLogger

struct ContentView: View {
    var body: some View {
        ZStack {
            // Your app content
            JLoggerView()
        }
    }
}
```

## UIKit Usage

Import `JLogger` and mount the overlay onto a window:

```swift
import JLogger

JLoggerUIView.show()
JLogger.shared.log("Hello from UIKit")
```

If you already have a specific `UIWindow`, you can pass it directly:

```swift
JLoggerUIView.show(window)
```

When `window` is `nil`, `JLoggerUIView.show()` will try to resolve the active window from `connectedScenes`. If it is not available immediately, it retries automatically.

## Example Project

The repository includes an `Example` target that demonstrates:

- shared logging through `JLogger.shared`
- SwiftUI integration with `JLoggerView`
- UIKit overlay integration with `JLoggerUIView.show()`

## Public API

```swift
JLogger.shared.log(_:_:)
JLoggerUIView.show(_:)
JLoggerUIView.hide()
JLoggerView()
```

## License

JLogger is available under the MIT license. See the LICENSE file for more info.

## Author

Created by kleoer

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 
