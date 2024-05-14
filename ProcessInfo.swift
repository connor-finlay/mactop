//
//  ProcessInfo.swift
//  mactop
//
//  Created by Laptop on 7/5/2024.
//

import Foundation
import SwiftUI
import Darwin
import Foundation

struct DarwinProcess {
    var pid: UInt64
    var utime: UInt64
    var stime: UInt64
}

extension DarwinProcess: Hashable, Equatable {
    static func == (lhs: DarwinProcess, rhs: DarwinProcess) -> Bool {
        return lhs.pid == rhs.pid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
    }
}

struct DarwinProcessInfo {
    var pid: UInt64
    var name : String
    var cpu_percent: Double
    var mem_percent: Double
}

extension DarwinProcessInfo: Hashable, Equatable {
    static func == (lhs: DarwinProcessInfo, rhs: DarwinProcessInfo) -> Bool {
        return lhs.pid == rhs.pid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
    }
}

enum sortValues {
    case pid
    case name
    case cpu_percent
    case mem_percent
}

let scheduler_ticks_per_sec = sysconf(_SC_CLK_TCK);
let nanos_per_sec = 1000000000;
let Platform_nanosecondsPerSchedulerTick = Double(nanos_per_sec) / Double(scheduler_ticks_per_sec);

class ProcessInfo : ObservableObject {
    var time_interval_ns: Double = 0.0
    var procArr: [DarwinProcess] = []
    @Published var procInfoArr: [DarwinProcessInfo] = []
    
    func sortProcesses(_ sortAsc: Bool, _ sortValue: sortValues ) {
        switch sortValue{
        case .pid:
            switch sortAsc {
            case false:
                self.procInfoArr.sort { $0.pid > $1.pid }
            default:
                self.procInfoArr.sort { $0.pid < $1.pid }
            }
        case .name:
            switch sortAsc {
            case false:
                self.procInfoArr.sort { $0.name.lowercased() > $1.name.lowercased() }
            default:
                self.procInfoArr.sort { $0.name.lowercased() < $1.name.lowercased() }
            }
        case .cpu_percent:
            switch sortAsc {
            case false:
                self.procInfoArr.sort { $0.cpu_percent > $1.cpu_percent }
            default:
                self.procInfoArr.sort { $0.cpu_percent < $1.cpu_percent }
            }
        case .mem_percent:
            switch sortAsc {
            case false:
                self.procInfoArr.sort { $0.mem_percent > $1.mem_percent }
            default:
                self.procInfoArr.sort { $0.mem_percent < $1.mem_percent }
            }
        }
    }

    func setTimeInterval(_ global_diff: Double, _ cpuCount: natural_t) {
        self.time_interval_ns = Platform_schedulerTicksToNanoseconds(global_diff) / Double(cpuCount)
    }
    
    func Platform_schedulerTicksToNanoseconds(_ scheduler_ticks : Double) -> Double {
        return scheduler_ticks * Platform_nanosecondsPerSchedulerTick;
    }

    func Platform_machTicksToNanoseconds(_ mach_ticks: Double) -> Double {
        let Platform_nanosecondsPerMachTick: Double = 1
        return (Double(mach_ticks) * Platform_nanosecondsPerMachTick) ;
    }
    
    func cleanUpDeadProc(_ livePIDs: [UInt64] ) {
        self.procInfoArr.removeAll( where: { !livePIDs.contains($0.pid)} )
        self.procArr.removeAll( where: { !livePIDs.contains($0.pid)} )
    }
    
    
    func getProcessList(_ maxMem: Double) {
        var mib = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var bufferSize = 0

        if sysctl(&mib, UInt32(mib.count), nil, &bufferSize, nil, 0) < 0 {
            perror(&errno)
            return
        }
        
        var procList: UnsafeMutablePointer<kinfo_proc>?
        procList = UnsafeMutablePointer.allocate(capacity: bufferSize)
        defer { procList?.deallocate() }

        if sysctl(&mib, UInt32(mib.count), procList, &bufferSize, nil, 0) < 0 {
            perror(&errno)
            return
        }

        let entryCount = bufferSize / MemoryLayout<kinfo_proc>.stride
        
        var livePIDs: [UInt64] = []
        
        for index in 0...entryCount {
            let pid = procList![index].kp_proc.p_pid
            let name = procList![index].kp_proc.p_comm
            let nameString = withUnsafeBytes(of: name) { bytes -> String? in
                let buffer = bytes.bindMemory(to: CChar.self)
                return String(cString: buffer.baseAddress!)
            }

            var procArrIndex = self.procArr.firstIndex(of: DarwinProcess(pid: UInt64(pid), utime: 0, stime: 0) )
            if procArrIndex == nil {
                self.procArr.insert(DarwinProcess(pid: UInt64(pid), utime: 0, stime: 0), at: self.procArr.endIndex)
                procArrIndex = self.procArr.endIndex - 1
            }
            livePIDs.insert(UInt64(pid), at: livePIDs.endIndex)

            let pti = UnsafeMutablePointer<proc_taskinfo>.allocate(capacity: 1)
            let PROC_PIDTASKINFO: Int32 = 4

            proc_pidinfo(Int32(pid), Int32(PROC_PIDTASKINFO),0, pti, Int32(MemoryLayout<proc_taskinfo>.size))
            defer{ pti.deallocate() }

            let user_time_ns = UInt64( Platform_machTicksToNanoseconds(Double(pti.pointee.pti_total_user)  * 41.666  ) )
            let system_time_ns = UInt64( Platform_machTicksToNanoseconds(Double(pti.pointee.pti_total_system)) )
            let total_existing_time_ns = self.procArr[procArrIndex!].stime + self.procArr[procArrIndex!].utime;
            let total_current_time_ns = system_time_ns + user_time_ns
            self.procArr[procArrIndex!].utime = user_time_ns
            self.procArr[procArrIndex!].stime = system_time_ns

            var percent_cpu: Double = 0.0
            if total_existing_time_ns > 0 {
                let total_time_diff_ns: UInt64 = total_current_time_ns - total_existing_time_ns
                percent_cpu = (Double(total_time_diff_ns) / self.time_interval_ns) * 100.0
                let percent_mem: Double = Double(pti.pointee.pti_resident_size) * 100.0 / maxMem
                if (percent_cpu > 1.0) {
                    let procInfoArrIndex = procInfoArr.firstIndex(of: DarwinProcessInfo(pid: UInt64(pid), name: "", cpu_percent: 0.0, mem_percent: 0.0) )
                    if procInfoArrIndex == nil {
                        self.procInfoArr.insert(DarwinProcessInfo(pid: UInt64(pid), name: nameString!, cpu_percent: percent_cpu, mem_percent: percent_mem), at: self.procInfoArr.endIndex)
                    } else {
                        self.procInfoArr[procInfoArrIndex!].name = nameString!
                        self.procInfoArr[procInfoArrIndex!].cpu_percent = percent_cpu
                        self.procInfoArr[procInfoArrIndex!].mem_percent = percent_mem
                    }
                }
            }
        }
        cleanUpDeadProc(livePIDs)
    }
    
}

