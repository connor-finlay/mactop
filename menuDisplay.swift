import SwiftUI
import ServiceManagement

struct menuDisplay: View {
    @State var inSettings : Bool = false
    var body: some View {
        if !inSettings {
            InfoView(inSettings: $inSettings)
        } else {
            SettingsView(inSettings: $inSettings)
        }
    }
}

