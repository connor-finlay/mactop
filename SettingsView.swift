//
//  SettingsView.swift
//  mactop
//
//  Created by Laptop on 11/4/2024.
//

import SwiftUI
import ServiceManagement
import SwiftData


struct SettingsView: View {
    @State private var onBack : Bool = false
    @State private var inPicker : Bool = false
    @Binding var inSettings : Bool
    @Binding var primary : Color
    @Binding var secondary : Color
    @Binding var tertiary : Color
    var body: some View {
            VStack {
                SettingsHeaderView(inSettings: $inSettings, primary: $primary, secondary: $secondary, tertiary: $tertiary)
                Spacer()
                
                launchOnStartupSettings(secondary: $secondary, tertiary: $tertiary)
                
                Spacer()
                
                if !inPicker {
                    Button(action: {
                        inPicker.toggle()
                    }, label: {
                        Text("Change Theme")
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 20))
                            .padding([.top, .bottom], 2)
                            .padding([.trailing, .leading], 1)
                    })
                    .onHover(perform: { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    })
                    .foregroundColor(primary)
                    .tint(tertiary)
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(10)
                } else {
                    ThemePicker(primary: $primary, secondary: $secondary, tertiary: $tertiary, inPicker: $inPicker)
                }
                
                Spacer()
            }
            .frame(width: 440, height: 150)
            .background(primary)
            .foregroundColor(secondary)
            .onTapGesture {
                if inPicker {
                    inPicker.toggle()
                }
            }
    }
}

struct launchOnStartupSettings: View {
    @AppStorage("launchOnLogin") private var launchAccess : Bool = false
    @Binding var secondary : Color
    @Binding var tertiary : Color
    var body: some View {
        ZStack {
            Toggle("Allow mactop to open automatically when you log in?", isOn: $launchAccess)
                .foregroundColor(secondary)
                .tint(tertiary)
                .toggleStyle(.switch)
                .onHover(perform: { hovering in
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                })
                .onChange(of: launchAccess) {
                    if launchAccess == true {
                        try? SMAppService.mainApp.register()
                    } else {
                        try? SMAppService.mainApp.unregister()
                    }
                }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
 

struct ThemePicker: View {
    @Environment(\.modelContext) var modelContext
    @Query var themes: [Theme]
    @Binding var primary : Color
    @Binding var secondary : Color
    @Binding var tertiary : Color
    @Binding var inPicker : Bool
    let colors: [Theme] = [
        Theme(name: "grey", primary: ColorSet(red: 0.08627451, green: 0.08627451, blue: 0.08627451), secondary: ColorSet(red: 1, green: 1, blue: 1),
              tertiary: ColorSet(red: 0.8627451, green: 0.8627451, blue: 0.8627451) ),
        Theme(name: "brown", primary: ColorSet(red: 181/255, green: 148/255, blue: 105/255), secondary: ColorSet(red: 1, green: 1, blue: 1),
              tertiary: ColorSet(red: 127/255, green: 101/255, blue: 69/255) ),
        Theme(name: "blue", primary: ColorSet(red: 0.25, green: 0.61, blue: 1), secondary: ColorSet(red: 1, green: 1, blue: 1),
              tertiary: ColorSet(red: 0.21, green: 0.4, blue: 1)),
        Theme(name: "purple", primary: ColorSet(red: 218/255, green: 143/255, blue: 1), secondary: ColorSet(red: 1, green: 1, blue: 1),
              tertiary: ColorSet(red: 128/255, green: 94/255, blue: 176/255) ),
        Theme(name: "green", primary: ColorSet(red: 49/255, green: 222/255, blue: 75/255), secondary: ColorSet(red: 1, green: 1, blue: 1),
              tertiary: ColorSet(red: 0, green: 125/255, blue: 27/255) ),
        Theme(name: "yellow", primary: ColorSet(red: 1, green: 0.83, blue: 0.149), secondary: ColorSet(red: 0.6275, green: 0.35294, blue: 0),
              tertiary: ColorSet(red: 0.6275, green: 0.35294, blue: 0)),
        Theme(name: "orange", primary: ColorSet(red: 1, green: 149/255, blue: 0), secondary: ColorSet(red: 1, green: 1, blue: 1),
              tertiary: ColorSet(red: 215/255, green: 0, blue: 69/255) ),
        Theme(name: "pink", primary: ColorSet(red: 1, green: 100/255, blue: 130/255), secondary: ColorSet(red: 1, green: 1, blue: 1),
              tertiary: ColorSet(red: 170/255, green: 16/255, blue: 76/255) ),
        Theme(name: "white", primary: ColorSet(red: 1, green: 1, blue: 1), secondary: ColorSet(red: 0, green: 0, blue: 0),
              tertiary: ColorSet(red: 0, green: 0, blue: 0) ),
    ]
    var body: some View {
            ZStack {
                HStack {
                    ForEach(colors) { color in
                        Button(action: {
                            primary = Color(.sRGB, red: color.primary.red, green: color.primary.green, blue: color.primary.blue)
                            secondary = Color(.sRGB, red: color.secondary.red, green: color.secondary.green, blue: color.secondary.blue)
                            tertiary = Color(.sRGB, red: color.tertiary.red, green: color.tertiary.green, blue: color.tertiary.blue)
                            themes[0].primary = color.primary
                            themes[0].secondary = color.secondary
                            themes[0].tertiary = color.tertiary
                            inPicker.toggle()
                            try? modelContext.save()
                        }, label: {
                            Image(systemName: "rectangle.fill")
                                .font(.system(size: 25))
                                .foregroundColor(Color(red: color.primary.red, green: color.primary.green, blue: color.primary.blue))
                        }).buttonStyle(PlainButtonStyle())
                        .onHover(perform: { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        })
                    }
                }
                .padding([.top, .bottom], 8)
                .padding([.trailing, .leading], 5)
            }
            .background(tertiary)
            .cornerRadius(10)
            .padding()
            .frame(height: 40)
    }
}

struct SettingsHeaderView: View {
    @Binding var inSettings: Bool
    @Binding var primary: Color
    @Binding var secondary: Color
    @Binding var tertiary: Color
    @State private var onBack : Bool = false
    var body: some View {
        HStack {
            Button(action: {
                inSettings.toggle()
            }, label: {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.system(size: 20))
                    .frame(alignment: .leading)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(!onBack ? primary : Color.white, !onBack ? secondary :  tertiary )
                    .symbolEffect(.scale.up, isActive: onBack)
                    .onHover(perform: { hovering in
                        if hovering {
                            onBack = true
                        } else {
                            onBack = false
                        }
                    })
            })
            .padding(.leading, 20)
            Spacer()
            Text("Settings")
                .font(.system(size: 20))
                .padding(.vertical, 10)
                .padding(.trailing, 55)
            Spacer()
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: 440, alignment: .leading)
        
        Divider()
            .overlay(secondary)
    }
}
