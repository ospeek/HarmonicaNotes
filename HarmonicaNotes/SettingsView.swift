import SwiftUI

/// Settings screen matching main theme, with configurable options.
struct SettingsView: View {
    /// Binding to control presentation state.
    @Binding var isPresented: Bool
    /// Toggle to control showing notes labels in main screen.
    @Binding var showNotes: Bool
    /// Base MIDI note for tuning key (C3=48 … C5=72).
    @Binding var baseMidi: Int

    // Convert a MIDI note number to a note name (e.g. "C4", "F#3").
    private func midiToName(_ midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = midi / 12 - 1
        let name = names[midi % 12]
        return "\(name)\(octave)"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Stepper(value: $baseMidi, in: 48...72, step: 1) {
                    Text("Key: \(midiToName(baseMidi))")
                        .foregroundColor(.white)
                }
                .padding(8)

                Toggle("Show Notes instead of Values", isOn: $showNotes)
                    .toggleStyle(SwitchToggleStyle())
                    .foregroundColor(.white)
                    .padding(8)
                Spacer()
                HStack {
                    Spacer()
                    Button("Close") {
                        isPresented = false
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    )
                    .foregroundColor(.black)
                }
            }
            .padding()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isPresented: .constant(true),
                     showNotes:   .constant(true),
                     baseMidi:    .constant(60))
    }
}
