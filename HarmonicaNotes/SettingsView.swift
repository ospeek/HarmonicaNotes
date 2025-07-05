import SwiftUI

/// Settings screen matching main theme, with configurable options.
struct SettingsView: View {
    /// Binding to control presentation state.
    @Binding var isPresented: Bool
    /// Toggle to control showing notes labels in main screen.
    @Binding var showNotes: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Toggle("Show Notes instead of Values", isOn: $showNotes)
                    .toggleStyle(SwitchToggleStyle(tint: .white))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showNotes ? Color.white.opacity(0.2) : Color.clear)
                    )
                Spacer()
                HStack {
                    Spacer()
                    Button("Close") {
                        isPresented = false
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                }
            }
            .padding()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(isPresented: .constant(true), showNotes: .constant(true))
    }
}
