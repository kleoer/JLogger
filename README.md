# JLogger

A lightweight, elegant logging solution for SwiftUI applications. JLogger provides a floating console view that can be minimized and dragged around the screen, making it perfect for debugging and monitoring your app in real-time.

## Features

- 🎯 Floating console window
- 🔄 Real-time log updates
- 🎨 Beautiful UI with dark theme
- 📱 Minimizable and draggable interface
- 🎭 Multiple log levels (Debug, Info, Warning, Error)
- 📜 Auto-scrolling to latest logs
- 🧹 Clear logs functionality
- 🔒 Thread-safe logging
- 💫 Smooth animations and transitions

## Requirements

- iOS 14.0+
- Swift 5.5+
- SwiftUI 2.0+

## Installation

### Swift Package Manager

Add JLogger to your project through Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/kleoer/JLogger.git", from: "1.0.0")
]
```

## Usage

1. Import JLogger in your SwiftUI view:

```swift
import JLogger
```

2. Add the logger view to your SwiftUI hierarchy:

```swift
struct ContentView: View {
    var body: some View {
        ZStack {
            // Your app content
            JLoggerView()
        }
    }
}
```

3. Log messages using different log levels:

```swift
// Log messages
JLogger.shared.log("Hello, World!", level: .info)
JLogger.shared.log("Debug message", level: .debug)
JLogger.shared.log("Warning: Low memory", level: .warning)
JLogger.shared.log("Error occurred", level: .error)
```

## Customization

JLogger comes with a beautiful default theme, but you can customize various aspects:

- Log entry appearance
- Window size and position
- Animation timing
- Color schemes

## License

JLogger is available under the MIT license. See the LICENSE file for more info.

## Author

Created by kleoer (kleoer@gmail.com)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 