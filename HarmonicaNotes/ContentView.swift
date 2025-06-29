//
//  ContentView.swift
//  HarmonicaNotes
//
//  Created by Onno Speekenbrink on 2025-06-29.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            GeometryReader { geometry in
                let buttonSize = (geometry.size.width - 88) / 10 // 88 = 8*9 spacing + 16*2 padding
                VStack(spacing: 16) {
                    // Top row: -1 to -10 buttons
                    HStack(spacing: 8) {
                        ForEach(1...10, id: \.self) { i in
                            Button(action: {
                                // handle negative button press if needed
                            }) {
                                Text("-\(i)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .frame(width: buttonSize, height: buttonSize)
                            }
                            .buttonStyle(SquareButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    // Bottom row: +1 to +10 buttons
                    HStack(spacing: 8) {
                        ForEach(1...10, id: \.self) { i in
                            Button(action: {
                                // handle positive button press if needed
                            }) {
                                Text("+\(i)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .frame(width: buttonSize, height: buttonSize)
                            }
                            .buttonStyle(SquareButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
                .padding(.vertical)
            }
        }
    }
}
// Custom button style for square buttons with pressed visual feedback
struct SquareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.white.opacity(0.3) : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 1))
            .cornerRadius(4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Preview
#Preview {
    ContentView()
}
