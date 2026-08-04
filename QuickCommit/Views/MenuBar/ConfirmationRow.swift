import SwiftUI

struct ConfirmationRow: View {
    let subject: String
    var body: some View { Label("Checkpointed: \(subject)", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
}
