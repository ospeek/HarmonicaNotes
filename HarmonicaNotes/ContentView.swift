//
//  ContentView.swift
//  HarmonicaNotes
//
//  Created by Onno Speekenbrink on 2025-06-29.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    // Frequency mapping per hole: draw (−) and blow (+)
    let drawFrequencies: [Float] = [
        293.6648, // D4
        391.9954, // G4
        493.8833, // B4
        587.3295, // D5
        698.4565, // F5
        880.0000, // A5
        987.7666, // B5
        1174.659, // D6
        1396.912, // F6
        1760.000  // A6
    ]
    let blowFrequencies: [Float] = [
        261.6256, // C4
        329.6276, // E4
        391.9954, // G4
        523.2511, // C5
        659.2551, // E5
        783.9909, // G5
        1046.502, // C6
        1318.510, // E6
        1567.982, // G6
        2093.005  // C7
    ]
    @State private var currentIndex: Int? = nil
    @State private var log: [String] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geometry in
                let spacingH: CGFloat = 8
                let spacingV: CGFloat = 16
                let paddingV: CGFloat = 16
                let hPadding: CGFloat = 16
                let width = geometry.size.width
                let buttonSize = (width - hPadding * 2 - spacingH * 9) / 10
                let gridHeight = paddingV * 2 + buttonSize * 2 + spacingV

                VStack(alignment: .center, spacing: 0) {
                    // Move buttons down a bit
                    Spacer().frame(height: 20)

                    // Button grid with swipe gesture
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: spacingV) {
                            HStack(spacing: spacingH) {
                                ForEach(0..<10, id: \.self) { idx in
                                    NoteButton(label: "-\(idx+1)", size: buttonSize, isActive: currentIndex == idx)
                                }
                            }
                            HStack(spacing: spacingH) {
                                ForEach(0..<10, id: \.self) { idx in
                                    NoteButton(label: "+\(idx+1)", size: buttonSize, isActive: currentIndex == idx + 10)
                                }
                            }
                        }
                        .padding(.horizontal, hPadding)
                        .padding(.vertical, paddingV)
                        .frame(width: width, height: gridHeight, alignment: .top)

                        // Touch overlay
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .frame(width: width, height: gridHeight)
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x - hPadding
                                    let y = value.location.y
                                    let cellWidth = buttonSize + spacingH
                                    var newIndex: Int? = nil
                                    let col = Int(x / cellWidth)
                                    if col >= 0 && col < 10 {
                                        let withinX = x - CGFloat(col) * cellWidth
                                        if withinX >= 0 && withinX <= buttonSize {
                                            let topMinY = paddingV
                                            let topMaxY = topMinY + buttonSize
                                            let bottomMinY = topMaxY + spacingV
                                            let bottomMaxY = bottomMinY + buttonSize
                                            if y >= topMinY && y <= topMaxY {
                                                newIndex = col
                                            } else if y >= bottomMinY && y <= bottomMaxY {
                                                newIndex = col + 10
                                            }
                                        }
                                    }
                                    if newIndex != currentIndex {
                                        if currentIndex != nil {
                                            SynthEngine.shared.noteOff()
                                        }
                                        if let idx = newIndex {
                                            let freq = idx < 10 ? drawFrequencies[idx] : blowFrequencies[idx - 10]
                                            SynthEngine.shared.noteOn(frequency: freq)
                                            let labelText = idx < 10 ? "-\(idx+1)" : "+\((idx-10)+1)"
                                            log.append(labelText)
                                        }
                                        currentIndex = newIndex
                                    }
                                }
                                .onEnded { _ in
                                    if currentIndex != nil {
                                        SynthEngine.shared.noteOff()
                                        currentIndex = nil
                                    }
                                }
                            )
                    }
                    .frame(width: width, height: gridHeight)

                    // Log below buttons
                    Text(log.joined(separator: " "))
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, hPadding)
                        .padding(.vertical, 8)

                    Spacer()
                }
                .frame(width: width, height: geometry.size.height, alignment: .top)
            }
        }
    }
}

// MARK: - NoteButton
/// A button showing a note label and active state.
struct NoteButton: View {
    let label: String
    let size: CGFloat
    let isActive: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isActive ? Color.white.opacity(0.3) : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 1))
                .frame(width: size, height: size)
                .scaleEffect(isActive ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isActive)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white)
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
