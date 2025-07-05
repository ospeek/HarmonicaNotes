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
                HStack {
                    Text("Key: \(midiToName(baseMidi))")
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 0) {
                        Button(action: { if baseMidi > 40 { baseMidi -= 1 } }) {
                            Image(systemName: "minus")
                                .foregroundColor(.black)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                        }
                        .disabled(baseMidi == 40)

                        Button(action: { if baseMidi < 70 { baseMidi += 1 } }) {
                            Image(systemName: "plus")
                                .foregroundColor(.black)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                        }
                        .disabled(baseMidi == 70)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
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
