import SwiftUI


@main
struct mactopApp: App {
    var body: some Scene {
        MenuBarExtra("macTop", image: "cpu-18")
        {
            menuDisplay()
        }
        .menuBarExtraStyle(.window)
    }
}

