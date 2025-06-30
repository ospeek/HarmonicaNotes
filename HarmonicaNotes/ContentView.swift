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
    // Log entry with timestamp for playback
    private struct LogEntry {
        var label: String
        let timestamp: Date
        var duration: TimeInterval? = nil
    }
    @State private var currentIndex: Int? = nil
    @State private var log: [LogEntry] = []
    @State private var isEditing: Bool = false
    @State private var selectedLogIndex: Int? = nil
    @State private var playTask: Task<Void, Never>? = nil
    @State private var isPlaying: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geometry in
                VStack(alignment: .center, spacing: 0) {
                    Spacer().frame(height: 20)
                    gridSection(in: geometry)
                    logSection()
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
        }
    }

    @ViewBuilder
    private func gridSection(in geometry: GeometryProxy) -> some View {
        let spacingH: CGFloat = 8
        let spacingV: CGFloat = 16
        let paddingV: CGFloat = 16
        let hPadding: CGFloat = 16
        let width = geometry.size.width
        let buttonSize = (width - hPadding * 2 - spacingH * 9) / 10
        let gridHeight = paddingV * 2 + buttonSize * 2 + spacingV

        ZStack(alignment: .topLeading) {
            VStack(spacing: spacingV) {
                HStack(spacing: spacingH) {
                    ForEach(0..<10, id: \.self) { idx in
                        NoteButton(label: "-\(idx+1)", size: buttonSize, isActive: currentIndex == idx)
                            .onTapGesture {
                                if isEditing, let sel = selectedLogIndex, sel < log.count {
                                    let newLabel = "-\(idx+1)"
                                    let oldEntry = log[sel]
                                    log[sel] = LogEntry(label: newLabel, timestamp: oldEntry.timestamp, duration: oldEntry.duration)
                                    SynthEngine.shared.noteOn(frequency: drawFrequencies[idx])
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        SynthEngine.shared.noteOff()
                                    }
                                    // remain in edit mode; clear selection
                                    selectedLogIndex = nil
                                }
                            }
                    }
                }
                HStack(spacing: spacingH) {
                    ForEach(0..<10, id: \.self) { idx in
                        NoteButton(label: "+\(idx+1)", size: buttonSize, isActive: currentIndex == idx + 10)
                            .onTapGesture {
                                if isEditing, let sel = selectedLogIndex, sel < log.count {
                                    let newLabel = "+\(idx+1)"
                                    let oldEntry = log[sel]
                                    log[sel] = LogEntry(label: newLabel, timestamp: oldEntry.timestamp, duration: oldEntry.duration)
                                    SynthEngine.shared.noteOn(frequency: blowFrequencies[idx])
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        SynthEngine.shared.noteOff()
                                    }
                                    // remain in edit mode; clear selection
                                    selectedLogIndex = nil
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, hPadding)
            .padding(.vertical, paddingV)
            .frame(width: width, height: gridHeight, alignment: .top)

            if !isEditing {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: width, height: gridHeight)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Drag logic
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
                                        // close previous note duration
                                        let now = Date()
                                        if let last = log.indices.last {
                                            log[last].duration = now.timeIntervalSince(log[last].timestamp)
                                        }
                                        SynthEngine.shared.noteOff()
                                    }
                                    if let idx = newIndex {
                                    let freq = idx < 10 ? drawFrequencies[idx] : blowFrequencies[idx - 10]
                                    SynthEngine.shared.noteOn(frequency: freq)
                                    let labelText = idx < 10 ? "-\(idx+1)" : "+\((idx-10)+1)"
                                    log.append(LogEntry(label: labelText, timestamp: Date()))
                                }
                                    currentIndex = newIndex
                                }
                            }
                        .onEnded { _ in
                            if currentIndex != nil {
                                // close last note duration
                                let now = Date()
                                if let last = log.indices.last {
                                    log[last].duration = now.timeIntervalSince(log[last].timestamp)
                                }
                                SynthEngine.shared.noteOff()
                                currentIndex = nil
                            }
                            }
                    )
            }
        }
        .frame(width: width, height: gridHeight)
    }

    @ViewBuilder
    private func logSection() -> some View {
        let hPadding: CGFloat = 16
        HStack(alignment: .top) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                        ForEach(Array(log.enumerated()), id: \.offset) { idx, entry in
                            Text(entry.label)
                            .font(.system(size: 16))
                            .foregroundColor(isEditing ? (selectedLogIndex == idx ? .yellow : .white) : .white)
                            .padding(4)
                            .background(isEditing && selectedLogIndex == idx ? Color.white.opacity(0.3) : Color.clear)
                            .cornerRadius(4)
                            .onTapGesture {
                                if isEditing {
                                    selectedLogIndex = idx
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 48)
            VStack(spacing: 8) {
                // Edit toggle
                Button {
                    isEditing.toggle()
                    if !isEditing {
                        selectedLogIndex = nil
                    }
                } label: {
                    Text("Edit")
                        .font(.system(size: 16, weight: isEditing ? .bold : .regular))
                        .foregroundColor(isEditing ? .yellow : .white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(SquareButtonStyle())
                // Clear or Delete (when a log entry is selected)
                Button {
                    if let sel = selectedLogIndex, sel < log.count {
                        log.remove(at: sel)
                    } else {
                        log.removeAll()
                    }
                    isEditing = false
                    selectedLogIndex = nil
                } label: {
                    Text(selectedLogIndex != nil ? "Delete" : "Clear")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(SquareButtonStyle())
                // Play/Stop button
                Button {
                    if isPlaying {
                        playTask?.cancel()
                        isPlaying = false
                    } else {
                        playTask?.cancel()
                        isPlaying = true
                        playTask = Task {
                            await playSequence()
                            isPlaying = false
                        }
                    }
                } label: {
                    Text(isPlaying ? "Stop" : "Play")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(SquareButtonStyle())
            }
        }
        .padding(.horizontal, hPadding)
        .padding(.vertical, 8)
    }

    // Map label to frequency
    private func frequency(for label: String) -> Float {
        guard let sign = label.first else { return 0 }
        let numString = String(label.dropFirst())
        guard let num = Int(numString), num >= 1, num <= 10 else { return 0 }
        return sign == "-" ? drawFrequencies[num - 1] : blowFrequencies[num - 1]
    }

    // Playback the recorded log with original timing
    private func playSequence() async {
        guard !log.isEmpty else { return }
        // Sequential playback using recorded durations
        var prevTime = log[0].timestamp
        for entry in log {
            let start = entry.timestamp
            let delay = start.timeIntervalSince(prevTime)
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            let freq = frequency(for: entry.label)
            SynthEngine.shared.noteOn(frequency: freq)
            let dur = entry.duration ?? 0.2
            if dur > 0 {
                try? await Task.sleep(nanoseconds: UInt64(dur * 1_000_000_000))
            }
            SynthEngine.shared.noteOff()
            prevTime = start.addingTimeInterval(dur)
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

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
