//
//  ProcessTableView.swift
//  mactop
//
//  Created by Laptop on 7/5/2024.
//

import SwiftUI
import Combine

struct ProcessTableView: View {
    @StateObject private var processInfo = ProcessInfo()
    @ObservedObject var host : MachineInfo
    @Binding var inProcessTable: Bool
    @State var sortAsc: Bool = false
    @State var currSortValue: sortValues = sortValues.cpu_percent
    var body: some View {
        VStack {
            HStack {
                TableHeaderView(sortAsc: $sortAsc, currSortValue: $currSortValue)
            }
            .frame(maxWidth: 440)
            .fontWeight(.bold)
            ScrollView {
                ForEach($processInfo.procInfoArr, id: \.pid) { $process in
                    HStack {
                        Text(verbatim: "\(process.pid)")
                            .frame(width: 60, alignment: .leading)
                        Text(String(format: "%.1f", process.cpu_percent))
                            .frame(width: 65, alignment: .leading)
                        Text(String(format: "%.1f", process.mem_percent))
                            .frame(width: 70, alignment: .leading)
                        Text(process.name)
                        Spacer()
                    }
                    .frame(maxWidth: 440)
                }
            }
        }
        .frame(maxWidth: 440, maxHeight: 150)
        .onChange(of: host.global_diff, {
            processInfo.setTimeInterval(host.global_diff, host.cpuCount)
            processInfo.getProcessList(host.memMax)
            processInfo.sortProcesses(sortAsc, currSortValue)
        })
        .onDisappear{
            processInfo.time_interval_ns = 0.0
            processInfo.procArr = []
            processInfo.procInfoArr = []
        }
    }
}

struct TableHeaderView: View {
    @Binding var sortAsc: Bool
    @Binding var currSortValue: sortValues
    var body: some View {
            Button(action: {
                currSortValue == .pid ? sortAsc.toggle() : (currSortValue = .pid)
            }){
                Text("PID")
                if currSortValue == .pid {
                    Text("\( sortAsc == false ? Image(systemName: "arrowtriangle.down.fill") : Image(systemName: "arrowtriangle.up.fill")  )")
                }
            }
            .padding(0)
            .frame(width: 60, alignment: .leading)
            Button(action: {
                currSortValue == .cpu_percent ? sortAsc.toggle() : (currSortValue = .cpu_percent)
            }){
                Text("CPU%")
                if currSortValue == .cpu_percent {
                    Text("\( sortAsc == false ? Image(systemName: "arrowtriangle.down.fill") : Image(systemName: "arrowtriangle.up.fill")  )")
                }
            }
            .padding(0)
            .frame(width: 65, alignment: .leading)
            Button(action: {
                currSortValue == .mem_percent ? sortAsc.toggle() : (currSortValue = .mem_percent)
            }){
                Text("Mem%")
                if currSortValue == .mem_percent {
                    Text("\( sortAsc == false ? Image(systemName: "arrowtriangle.down.fill") : Image(systemName: "arrowtriangle.up.fill")  )")
                }
            }
            .padding(0)
            .frame(width: 70, alignment: .leading)
            Button(action: {
                currSortValue == .name ? sortAsc.toggle() : (currSortValue = .name)
            }){
                Text("Name")
                if currSortValue == .name {
                    Text("\( sortAsc == false ? Image(systemName: "arrowtriangle.down.fill") : Image(systemName: "arrowtriangle.up.fill")  )")
                }
            }
            .padding(0)
            .frame(width: 60, alignment: .leading)
            Spacer()
    }
}
