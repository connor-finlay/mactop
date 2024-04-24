import SwiftUI
import ServiceManagement

struct InfoView: View {
    @StateObject var host : MachineInfo = MachineInfo()
    @Binding var inSettings : Bool
    @State private var onQuit : Bool = false
    @State private var onSettings : Bool = false
    @AppStorage("launchOnLoginRequested") private var launchOnLoginRequested : Bool = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var inView : Bool = false
    var body: some View {
        VStack  {
            HStack (spacing : 5){
                Text("Mem: \(String(format: "%.2fG",host.currMemUsageRaw)) / \(String(format: "%.1fG",host.availMemoryRaw))")
                ProgressView( value: host.currMemUsageRaw, total: host.availMemoryRaw)
                Button(action: {
                    inSettings.toggle()
                }){
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(!onSettings ? Color.white : Color(red: 0.21, green: 0.4, blue: 1))
                        .symbolEffect(.scale.up, isActive: onSettings)
                        .onHover(perform: { hovering in
                            if hovering {
                                onSettings = true
                            } else {
                                onSettings = false
                            }
                        })
                }

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(!onQuit ? Color.blue : Color.white, !onQuit ? Color.white : Color.red)
                        .symbolEffect(.scale.up, isActive: onQuit)
                        .onHover(perform: { hovering in
                            if hovering {
                                onQuit = true
                            } else {
                                onQuit = false
                            }
                        })
                }
            }.buttonStyle(PlainButtonStyle())
            .frame(height: 25)
            HStack {
                VStack {
                    ForEach( Array(stride(from: 0, to: Int((self.host.cpuCount)), by: 2)), id: \.self) {index in
                        CPUUsageCluster(cpu: index, percent: $host.usages[index])
                    }
                }
                VStack {
                    ForEach( Array(stride(from: 1, to: Int((self.host.cpuCount)), by: 2)), id: \.self) {index in
                        CPUUsageCluster(cpu: index, percent: $host.usages[index])
                    }
                }
            }
            if  !launchOnLoginRequested {
                launchOnStartup()
            }
        }.environment(\.colorScheme, .dark)
        .padding([.top], 10)
        .padding([.bottom,.trailing,.leading])
        .background(Color.blue)
        .task {
            host.GetSysInfo()
            host.getVMStats()
        }
        .onReceive(timer, perform: { _ in
            host.GetSysInfo()
            host.getVMStats()
        })
    }
}

struct CPUUsageCluster: View {
    var cpu : Int
    @Binding var percent : Double
    var body: some View {
        HStack{
            Text("CPU: \(cpu)")
            ProgressView( value: percent, total: 100)
            Text("\(String(format: "%.2f",percent))%")
        }
        .frame(width: 200)
    }
}

struct launchOnStartup: View {
    @AppStorage("launchOnLogin") private var launchAccess : Bool = false
    @AppStorage("launchOnLoginRequested") private var launchOnLoginRequested : Bool = false
    @State private var onNo : Bool = false
    @State private var onYes : Bool = false
    var body: some View {
        HStack {
            Text("Allow mactop to open automatically when you log in?")
            Button( action: {
                launchOnLoginRequested.toggle()
            }){
                Image(systemName: "x.circle.fill")
                    .font(.system(size: 20))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(!onNo ? Color.blue : Color.white, !onNo ? Color.white : Color.red)
                    .symbolEffect(.scale.up, isActive: onNo)
            }.onHover(perform: { hovering in
                if hovering {
                    onNo = true
                } else {
                    onNo = false
                }
            })
            Button( action: {
                try? SMAppService.mainApp.register()
                launchAccess.toggle()
                launchOnLoginRequested.toggle()
            }){
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(!onYes ? Color.blue : Color.white, !onYes ? Color.white : Color.green)
                    .symbolEffect(.scale.up, isActive: onYes)
            }.onHover(perform: { hovering in
                if hovering {
                    onYes = true
                } else {
                    onYes = false
                }
            })
        }
        .frame(height: 25)
        .buttonStyle(PlainButtonStyle())
    }
}
