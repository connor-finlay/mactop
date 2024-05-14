import SwiftUI
import ServiceManagement
import SwiftData

struct menuDisplay: View {
    @State var inSettings : Bool = false
    @Query var themes: [Theme]
    @Environment(\.modelContext) var modelContext
    @State var primary: Color = Color.blue
    @State var secondary: Color = Color.white
    @State var tertiary: Color = Color.blue
    @Environment(\.colorScheme) var color
    @Binding var colorBinding: ColorScheme
    var body: some View {
        if !inSettings {
            InfoView(inSettings: $inSettings, primary: $primary, secondary: $secondary, tertiary: $tertiary)
                .task {
                    if themes.isEmpty {
                        let initialTheme = Theme(name: "bckgrnd")
                        modelContext.insert(initialTheme)
                        setColors(initialTheme, &primary, &secondary, &tertiary)
                    } else {
                        setColors(themes[0], &primary, &secondary, &tertiary)
                    }
                }
                .onAppear {
                    colorBinding = color
                }
                .onChange(of: color, {
                    colorBinding = color
                })
        } else {
            SettingsView(inSettings: $inSettings, primary: $primary, secondary: $secondary, tertiary: $tertiary)
                .task {
                    setColors(themes[0], &primary, &secondary, &tertiary)
                }
        }
    }
}

func setColors (_ theme: Theme,_ primary: inout Color,_ secondary: inout Color,_ tertiary: inout Color) {
    primary = Color(.sRGB, red: theme.primary.red, green: theme.primary.green, blue: theme.primary.blue)
    secondary = Color(.sRGB, red: theme.secondary.red, green: theme.secondary.green, blue: theme.secondary.blue)
    tertiary = Color(.sRGB, red: theme.tertiary.red, green: theme.tertiary.green, blue: theme.tertiary.blue)
}


