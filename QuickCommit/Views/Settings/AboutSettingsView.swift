import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text(Constants.displayName).font(.title2)
            let info = Bundle.main.infoDictionary
            Text("Version \(info?["CFBundleShortVersionString"] as? String ?? "—") (\(info?["CFBundleVersion"] as? String ?? "—"))").foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
