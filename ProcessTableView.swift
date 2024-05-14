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
                            .frame(width: 55, alignment: .leading)
                        Text(String(format: "%.1f", process.cpu_percent))
                            .frame(width: 60, alignment: .leading)
                        Text(String(format: "%.1f", process.mem_percent))
                            .frame(width: 60, alignment: .leading)
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
        switch currSortValue {
        case .pid:
            Button(action: {
                sortAsc.toggle()
            }){
                Text("PID \( sortAsc == false ? Image(systemName: "arrowtriangle.down.fill") : Image(systemName: "arrowtriangle.up.fill")  )")
                    .frame(width: 60, alignment: .leading)
            }
            Button(action: {
                currSortValue = sortValues.cpu_percent
            }){
                Text("CPU%")
                    .frame(width: 60, alignment: .leading)
            }
            Button(action: {
                currSortValue = sortValues.mem_percent
            }){
                Text("Mem%")
                    .frame(width: 60, alignment: .leading)
            }
            Button(action: {
                currSortValue = sortValues.name
            }){
                Text("Name")
                    .frame(width: 60, alignment: .leading)
            }
            Spacer()
        case .name:
            Button(action: {
                currSortValue = sortValues.pid
            }){
                Text("PID")
                    .frame(width: 60, alignment: .leading)
            }
            Button(action: {
                currSortValue = sortValues.cpu_percent
            }){
                Text("CPU%")
                    .frame(width: 60, alignment: .leading)
            }
            Button(action: {
                currSortValue = sortValues.mem_percent
            }){
                Text("Mem%")
                    .frame(width: 60, alignment: .leading)
            }
            Button(action: {
                sortAsc.toggle()
            }){
                Text("Name \( sortAsc == false ? Image(systemName: "arrowtriangle.down.fill") : Image(systemName: "arrowtriangle.up.fill")  )")
                    .frame(width: 60, alignment: .leading)
            }
            Spacer()
        case .cpu_percent:
            Button(action: {
                currSortValue = sortValues.pid
            }){
                Text("PID")
                    .frame(width: 55, alignment: .leading)
            }
            Button(action: {
                sortAsc.toggle()
            }){
                Text("CPU% \( sortAsc == false ? Image(systemName: "arrowtriangle.down.fill") : Image(systemName: "arrowtriangle.up.fill")  )")
                    .frame(width: 60, alignment: .leading)
            }
            Button(action: {
                currSortValue = sortValues.mem_percent
            }){
                Text("Mem%")
                    .frame(width: 60, alignment: .leading)
            }
            Button(action: {
                currSortValue = sortValues.name
            }){
                Text("Name")
                    .frame(width: 60, alignment: .leading)
            }
            Spacer()
        case .mem_percent:
            Button(action: {
                currSortValue = sortValues.pid
            }){
                Text("PID")
                    .frame(width: 60, alignment: .leading)
            }
            Button(action: {
                currSortValue = sortValues.cpu_percent
            }){
                Text("CPU%")
                    .frame(width: 60, alignment: .leading)
            }
            Button(action: {
                sortAsc.toggle()
            }){
                Text("Mem% \( sortAsc == false ? Image(systemName: "arrowtriangle.down.fill") : Image(systemName: "arrowtriangle.up.fill")  )")
                    .frame(width: 65, alignment: .leading)
            }
            Button(action: {
                currSortValue = sortValues.name
            }){
                Text("Name")
                    .frame(width: 60, alignment: .leading)
            }
            Spacer()
        }
    }
}

