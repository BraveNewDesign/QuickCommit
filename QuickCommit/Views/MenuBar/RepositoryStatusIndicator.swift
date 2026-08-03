import SwiftUI

struct RepositoryStatusIndicator: View {
    let state: RepositoryUIState

    var body: some View { Circle().fill(state == .ready ? .green : .secondary).frame(width: 8, height: 8) }
}
