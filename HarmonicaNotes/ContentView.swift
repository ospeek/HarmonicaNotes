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
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            GeometryReader { geometry in
                let buttonSize = (geometry.size.width - 88) / 10 // 88 = 8*9 spacing + 16*2 padding
                VStack(spacing: 16) {
                    // Top row: -1 to -10 buttons
                    HStack(spacing: 8) {
                        ForEach(0..<10, id: \.self) { idx in
                            NoteButton(label: "-\(idx+1)", freq: drawFrequencies[idx], size: buttonSize)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    // Bottom row: +1 to +10 buttons
                    HStack(spacing: 8) {
                        ForEach(0..<10, id: \.self) { idx in
                            NoteButton(label: "+\(idx+1)", freq: blowFrequencies[idx], size: buttonSize)
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
// MARK: - NoteButton (press-and-hold)
/// A button that triggers noteOn/noteOff for given frequency on press-and-hold.
struct NoteButton: View {
    let label: String
    let freq: Float
    let size: CGFloat
    @State private var isPressing = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isPressing ? Color.white.opacity(0.3) : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 1))
                .frame(width: size, height: size)
                .scaleEffect(isPressing ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressing)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
        .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressing {
                            isPressing = true
                            SynthEngine.shared.noteOn(frequency: freq)
                        }
                    }
                    .onEnded { _ in
                        isPressing = false
                        SynthEngine.shared.noteOff()
                    }
        )
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
