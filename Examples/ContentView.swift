//
//  ContentView.swift
//  JLogger
//
//  Created by LONG JUN on 2025/6/20.
//

import SwiftUI
import JLogger

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "globe")
                .imageScale(.large)
            Text("Hello, world!")
            Spacer()
            Button {
                JLogger.shared.log("Clicked")
            } label: {
                Text("Click")
            }

        }
        .padding()
    }
}

#Preview {
    ContentView()
}
