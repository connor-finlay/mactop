//
//  SettingsView.swift
//  mactop
//
//  Created by Laptop on 11/4/2024.
//

import SwiftUI
import ServiceManagement

/*
 
 Things to Do!
 
 Add a question on start up to check whether launch on login has been asked
 
 Create an variable to store whether the prompt to launchonlogin has been asked
 
 Create a settings page to change launch on login, with a back button
    maybe different color schemes
 
 */


struct SettingsView: View {
    @Binding var inSettings : Bool 
    @State private var onBack : Bool = false
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    inSettings.toggle()
                }, label: {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 20))
                        .frame(alignment: .leading)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(!onBack ? Color.blue : Color.white, !onBack ? Color.white :  Color(red: 0.21, green: 0.4, blue: 1) )
                        .symbolEffect(.scale.up, isActive: onBack)
                        .onHover(perform: { hovering in
                            if hovering {
                                onBack = true
                            } else {
                                onBack = false
                            }
                        })
                }).padding(.leading, 20)
                Spacer()
                Text("Settings")
                    .font(.system(size: 20))
                    .padding(.vertical, 10)
                    .padding(.trailing, 55)
                Spacer()
            }.buttonStyle(PlainButtonStyle())
                .frame(maxWidth: 440, alignment: .leading)
            Divider()
                .overlay(Color.white)
            Spacer()
            launchOnStartupSettings()
            Spacer()
        }.frame(width: 440, height: 150)
        .background(Color.blue)
    }
}

struct launchOnStartupSettings: View {
    @AppStorage("launchOnLogin") private var launchAccess : Bool = false
    var body: some View {
        ZStack {
            Toggle("Allow mactop to open automatically when you log in?", isOn: $launchAccess)
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

