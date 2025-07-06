import SwiftUI

/// A simple launch screen view displayed before the app loads.
struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Harmonica Notes")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

#if DEBUG
struct LaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreen()
    }
}
#endif
