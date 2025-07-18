//
//  ContentView.swift
//  HarmonicaNotes
//
//  Created by Onno Speekenbrink on 2025-06-29.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    // Semitone offsets per hole relative to base key: draw (−) and blow (+)
    let drawOffsets = [2, 7, 11, 14, 17, 21, 23, 26, 29, 33]
    let blowOffsets = [0, 4, 7, 12, 16, 19, 24, 28, 31, 36]

    // Base MIDI note (middle C=60). Controls tuning key.
    @State private var baseMidi: Int = 60

    // Computed frequencies per hole based on baseMidi
    private var drawFrequencies: [Float] { drawOffsets.map { midiToFrequency(baseMidi + $0) } }
    private var blowFrequencies: [Float] { blowOffsets.map { midiToFrequency(baseMidi + $0) } }

    // Computed note names per hole based on baseMidi
    private var drawNoteNames: [String] { drawOffsets.map { midiToName(baseMidi + $0) } }
    private var blowNoteNames: [String] { blowOffsets.map { midiToName(baseMidi + $0) } }
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
    // Recording state and virtual clock to ignore paused/edit/playback time
    @State private var isRecording: Bool = false
    @State private var pauseStart: Date? = nil
    @State private var pausedTime: TimeInterval = 0
    @State private var wasPaused: Bool = false
    @State private var showSettings: Bool = false
    @State private var showNotes:    Bool = false
    // Currently highlighted log entry during playback
    @State private var currentLogPlaybackIndex: Int? = nil

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
            // Settings button at bottom-left
            VStack {
                Spacer()
                HStack {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                    .padding()
                    Spacer()
                }
            }
        }
        // Monitor pause state when editing or playback start/stop
        .onChange(of: isPlaying) { updatePauseState() }
        .onChange(of: isEditing) { updatePauseState() }
.sheet(isPresented: $showSettings) {
    SettingsView(isPresented: $showSettings,
                 showNotes:    $showNotes,
                 baseMidi:     $baseMidi)
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
                        NoteButton(label: showNotes ? drawNoteNames[idx] : "-\(idx+1)",
                                   size: buttonSize,
                                   isActive: currentIndex == idx,
                                   isDraw: true)
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
                        NoteButton(label: showNotes ? blowNoteNames[idx] : "+\(idx+1)",
                                   size: buttonSize,
                                   isActive: currentIndex == idx + 10,
                                   isDraw: false)
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
                                        let nowAdjusted = Date().addingTimeInterval(-pausedTime)
                                        if isRecording, let last = log.indices.last {
                                            log[last].duration = nowAdjusted.timeIntervalSince(log[last].timestamp)
                                        }
                                        SynthEngine.shared.noteOff()
                                    }
                                    if let idx = newIndex {
                                        // start or resume recording
                                        if !isRecording {
                                            isRecording = true
                                        }
                                        let freq = idx < 10 ? drawFrequencies[idx] : blowFrequencies[idx - 10]
                                        SynthEngine.shared.noteOn(frequency: freq)
                                        if isRecording {
                                            let nowAdjusted = Date().addingTimeInterval(-pausedTime)
                                            let labelText = idx < 10 ? "-\(idx+1)" : "+\((idx-10)+1)"
                                            log.append(LogEntry(label: labelText, timestamp: nowAdjusted))
                                        }
                                    }
                                    currentIndex = newIndex
                                }
                            }
                        .onEnded { _ in
                            if currentIndex != nil {
                                // close last note duration
                                let nowAdjusted = Date().addingTimeInterval(-pausedTime)
                                if isRecording, let last = log.indices.last {
                                    log[last].duration = nowAdjusted.timeIntervalSince(log[last].timestamp)
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
            ScrollView(.vertical, showsIndicators: false) {
                let columns = [GridItem(.adaptive(minimum: 32), spacing: 4)]
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(log.enumerated()), id: \.offset) { idx, entry in
                        Text(entry.label)
                            .font(.system(size: 16))
                            .foregroundColor(isEditing && selectedLogIndex == idx ? .yellow : .white)
                            .padding(4)
                            .background(
                                isEditing && selectedLogIndex == idx
                                    ? Color.white.opacity(0.3)
                                    : (isPlaying && currentLogPlaybackIndex == idx
                                        ? Color.gray.opacity(0.6)
                                        : Color.clear)
                            )
                            .cornerRadius(4)
                            .onTapGesture {
                                if isEditing {
                                    selectedLogIndex = idx
                                } else {
                                    if isRecording { isRecording = false }
                                    playTask?.cancel()
                                    isPlaying = true
                                    let startIndex = idx
                                    playTask = Task {
                                        await playSequence(from: startIndex)
                                        isPlaying = false
                                    }
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 8) {
                // Edit toggle
                Button {
                    isEditing.toggle()
                    if !isEditing {
                        selectedLogIndex = nil
                    }
                } label: {
                    Image(systemName: isEditing ? "pencil.circle.fill" : "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(isEditing ? .yellow : .white)
                }
                .buttonStyle(LiquidGlassButtonStyle())
                // Clear or Delete (when a log entry is selected)
                Button {
                    if let sel = selectedLogIndex, sel < log.count {
                        log.remove(at: sel)
                    } else {
                        log.removeAll()
                    }
                    // Reset recording when all notes cleared
                    if log.isEmpty {
                        pausedTime = 0
                        pauseStart = nil
                        wasPaused = false
                        isRecording = false
                    }
                    isEditing = false
                    selectedLogIndex = nil
                } label: {
                    Image(systemName: selectedLogIndex != nil ? "trash.fill" : "xmark.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .buttonStyle(LiquidGlassButtonStyle())
                // Record (when empty) or Play/Stop button
                if log.isEmpty {
                    Button {
                        // Start new recording session
                        pausedTime = 0
                        pauseStart = nil
                        wasPaused = false
                        isRecording = true
                    } label: {
                        Image(systemName: isRecording ? "stop.fill" : "record.circle")
                            .font(.system(size: 16))
                            .foregroundColor(isRecording ? .red : .white)
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                } else {
                    Button {
                        if isPlaying {
                            playTask?.cancel()
                            isPlaying = false
                        } else {
                            // Stop recording when playing sequence
                            if isRecording {
                                isRecording = false
                            }
                            playTask?.cancel()
                            isPlaying = true
                            playTask = Task {
                                await playSequence()
                                isPlaying = false
                            }
                        }
                    } label: {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                }
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

    // Convert a MIDI note number to frequency in Hz
    private func midiToFrequency(_ midi: Int) -> Float {
        440 * pow(2, Float(midi - 69) / 12)
    }

    // Convert a MIDI note number to a note name (e.g. "C4", "F#3")
    private func midiToName(_ midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = midi / 12 - 1
        let name = names[midi % 12]
        return "\(name)\(octave)"
    }
    // Virtual clock: track total paused time during editing or playback
    private func updatePauseState() {
        let paused = isPlaying || isEditing
        if paused && !wasPaused {
            pauseStart = Date()
        } else if !paused && wasPaused {
            if let ps = pauseStart {
                pausedTime += Date().timeIntervalSince(ps)
                pauseStart = nil
            }
        }
        wasPaused = paused
    }

    // Playback the recorded log with original timing, highlighting notes as they play
    @MainActor
    private func playSequence(from startIndex: Int = 0) async {
        guard startIndex < log.count else { return }
        // Clear previous playback highlight
        currentLogPlaybackIndex = nil
        // Sequential playback using recorded durations, starting at startIndex
        var prevTime = log[startIndex].timestamp
        for idx in startIndex..<log.count {
            let entry = log[idx]
            let start = entry.timestamp
            let delay = start.timeIntervalSince(prevTime)
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            // Highlight the log entry and grid note
            currentLogPlaybackIndex = idx
            if let sign = entry.label.first, let num = Int(entry.label.dropFirst()) {
                let gridIdx = (sign == "-" ? num - 1 : num - 1 + 10)
                currentIndex = gridIdx
            }
            let freq = frequency(for: entry.label)
            SynthEngine.shared.noteOn(frequency: freq)
            let dur = entry.duration ?? 0.2
            if dur > 0 {
                try? await Task.sleep(nanoseconds: UInt64(dur * 1_000_000_000))
            }
            SynthEngine.shared.noteOff()
            // Clear highlights and advance
            currentIndex = nil
            currentLogPlaybackIndex = nil
            prevTime = start.addingTimeInterval(dur)
        }
    }
}

// MARK: - NoteButton
/// A note button with liquid glass style, active highlight, and row tint.
struct NoteButton: View {
    let label: String
    let size: CGFloat
    let isActive: Bool
    /// True for draw row (tint red), false for blow row (tint blue)
    let isDraw: Bool

    private var rowTint: Color {
        isDraw ? Color.red.opacity(0.1) : Color.blue.opacity(0.1)
    }

    var body: some View {
        Text(label)
            .font(.system(size: 12))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isActive ? Color.gray.opacity(0.6) : rowTint)
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(isActive ? 1 : 0.7), lineWidth: 1)
            )
            .scaleEffect(isActive ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isActive)
    }
}

// Custom button style for liquid glass buttons with glass effect
struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.7), lineWidth: 1))
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
