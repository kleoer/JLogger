//
//  JLoggerView.swift
//  JLogger
//
//  Created by kleoer on 2025/6/19.
//

import SwiftUI

public struct JLoggerView: View {
    @StateObject private var logger = JLogger.shared
    @State private var dragOffset = CGSize.zero
    @State private var position = miniPosition
    @State private var isScrolling = false
    
    // Default position for minimized view
    private static let miniPosition = CGPoint(x: (UIScreen.main.bounds.width - miniSize.width) * 1.5 - miniSize.width / 2.0, y: (UIScreen.main.bounds.height - miniSize.height) * 1.5 - miniSize.height / 2.0)
    // Size of minimized view
    private static let miniSize = CGSize(width: 60, height: 60)

    private var screen: CGRect {
        UIScreen.main.bounds
    }
    
    public init() {
        _logger = StateObject(wrappedValue: JLogger.shared)
    }
    
    public var body: some View {
        Group {
            if logger.isMinimized {
                minimizedView
                    .offset(x: position.x - (screen.width - JLoggerView.miniSize.width) + dragOffset.width,
                            y: position.y - (screen.height - JLoggerView.miniSize.height) + dragOffset.height)
            } else {
                VStack {
                    Spacer()
                    expandedView
                        .frame(maxWidth: .infinity, maxHeight: screen.height / 2)
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if logger.isMinimized {
                        dragOffset = gesture.translation
                    }
                }
                .onEnded { gesture in
                    if logger.isMinimized {
                        position = CGPoint(
                            x: position.x + dragOffset.width,
                            y: position.y + dragOffset.height
                        )
                        dragOffset = .zero
                    }
                }
        )
        .ignoresSafeArea()
    }
    
    private var minimizedView: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: JLoggerView.miniSize.width, height: JLoggerView.miniSize.height)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                )
            
            VStack(spacing: 2) {
                Image(systemName: "terminal")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                Text("\(logger.logs.count)")
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .onTapGesture {
            withAnimation(.spring()) {
                logger.isMinimized.toggle()
            }
        }
    }
    
    private var expandedView: some View {
        VStack(spacing: 0) {
            titleBar
            logContent
        }
        .background(Color.black.opacity(0.8))
    }
    
    private var titleBar: some View {
        HStack {
            Text("Console")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.leading)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    logger.clearLogs()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(CircleButtonStyle())
                
                Button(action: {
                    withAnimation(.spring()) {
                        logger.isMinimized.toggle()
                    }
                }) {
                    Image(systemName: "minus")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
                .buttonStyle(CircleButtonStyle())
            }
            .padding(.trailing)
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }
    
    private var logContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(logger.logs) { entry in
                        logEntry(entry)
                            .id(entry.id)
                    }
                }
                .padding(.vertical, 8)
            }
            .gesture(DragGesture().onChanged { _ in
                isScrolling = true
            }.onEnded { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isScrolling = false
                }
            })
            .onChange(of: logger.logs) { _ in
                if !isScrolling {
                    withAnimation {
                        proxy.scrollTo(logger.logs.last?.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private func logEntry(_ entry: JLogger.LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("[\(entry.level)]")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(levelColor(entry.level))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(levelColor(entry.level).opacity(0.2))
                    .cornerRadius(4)
                
                Text(entry.timestamp, style: .time)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Text(entry.message)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(nil)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.03))
    }
    
    struct CircleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(8)
                .background(
                    Circle()
                        .fill(configuration.isPressed ? 
                              Color.white.opacity(0.2) : 
                              Color.white.opacity(0.1))
                )
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        }
    }
    
    private func levelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "error":
            return .red
        case "warning":
            return .orange
        case "debug":
            return .purple
        default:
            return .blue
        }
    }
}

struct JLoggerView_Previews: PreviewProvider {
    static var previews: some View {
        JLoggerView()
    }
}
