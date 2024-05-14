import SwiftUI
import SwiftData
import ServiceManagement

struct InfoView: View {
    @StateObject var host : MachineInfo = MachineInfo()
    @State private var onQuit : Bool = false
    @State private var onSettings : Bool = false
    @State private var onProcessTable: Bool = false
    @State private var inProcessTable: Bool = false
    @AppStorage("launchOnLoginRequested") private var launchOnLoginRequested : Bool = false
    @Binding var inSettings : Bool
    @Binding var primary : Color
    @Binding var secondary : Color
    @Binding var tertiary : Color
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack  {
            HStack (spacing : 5){
                Text("Mem: \(String(format: "%.2fG",host.currMemUsageRaw)) / \(String(format: "%.1fG",host.memInGB))")
                ProgressView( value: host.currMemUsageRaw, total: host.memInGB)
                    .tint(tertiary)
                Button(action: {
                    inProcessTable.toggle()
                }){
                    Image(systemName: "doc.text.below.ecg.fill")
                        .font(.system(size: 20))
                        .foregroundColor(!onProcessTable ? secondary : tertiary)
                        .symbolEffect(.scale.up, isActive: onProcessTable)
                        .onHover(perform: { hovering in
                            if hovering {
                                onProcessTable = true
                            } else {
                                onProcessTable = false
                            }
                        })
                }
                Button(action: {
                    inSettings.toggle()
                }){
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(!onSettings ? secondary : tertiary)
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
                        .foregroundStyle(!onQuit ? primary : Color.white, !onQuit ? secondary : Color.red)
                        .symbolEffect(.scale.up, isActive: onQuit)
                        .onHover(perform: { hovering in
                            if hovering {
                                onQuit = true
                            } else {
                                onQuit = false
                            }
                        })
                }
            }
            .frame(height: 25)
            
            HStack {
                VStack {
                    ForEach( Array(stride(from: 0, to: Int((self.host.cpuCount)), by: 2)), id: \.self) {index in
                        CPUUsageCluster(cpu: index, percent: $host.usages[index], barColor: tertiary)
                    }
                }
                VStack {
                    ForEach( Array(stride(from: 1, to: Int((self.host.cpuCount)), by: 2)), id: \.self) {index in
                        CPUUsageCluster(cpu: index, percent: $host.usages[index], barColor: tertiary)
                    }
                }
            }
            if  !launchOnLoginRequested {
                launchOnStartup(primary: $primary)
            }
            
            if inProcessTable {
                ProcessTableView(host: host, inProcessTable: $inProcessTable)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding([.top], 10)
        .padding([.bottom,.trailing,.leading])
        .background(primary)
        .foregroundColor(secondary)
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
    var barColor : Color
    var body: some View {
        HStack{
            Text("CPU: \(cpu)")
            ProgressView( value: percent, total: 100)
                .tint(barColor)
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
    @Binding var primary : Color
    var body: some View {
        HStack {
            Text("Allow mactop to open automatically when you log in?")
            Button( action: {
                launchOnLoginRequested.toggle()
            }){
                Image(systemName: "x.circle.fill")
                    .font(.system(size: 20))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(!onNo ? primary : Color.white, !onNo ? Color.white : Color.red)
                    .symbolEffect(.scale.up, isActive: onNo)
            }
            .onHover(perform: { hovering in
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
                    .foregroundStyle(!onYes ? primary : Color.white, !onYes ? Color.white : Color.green)
                    .symbolEffect(.scale.up, isActive: onYes)
            }
            .onHover(perform: { hovering in
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


