import Foundation


class MachineInfoTest : ObservableObject {
    
    struct cpu_ticks {
        var CPU_STATE_USER : UInt32
        var CPU_STATE_SYSTEM : UInt32
        var CPU_STATE_IDLE : UInt32
        var CPU_STATE_NICE : UInt32
    }

    @Published var cpuCount: natural_t = 0
    var prevusages: [cpu_ticks] = []
    var currusages: [cpu_ticks] = []
    @Published var usages: [Double] = []
    @Published var currMemUsageRaw : Double = 0.0
    @Published var availMemoryRaw : Double = 0.0
    
    init() {
        var infoSize = mach_msg_type_number_t(MemoryLayout<processor_cpu_load_info>.stride)
        var currInfo = processor_info_array_t(bitPattern: 0)
        
        guard KERN_SUCCESS == host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &self.cpuCount, &currInfo, &infoSize)
        else {
            //Failed to get system info
            return
        }
        
        let currLoad : processor_cpu_load_info_t = currInfo!.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(self.cpuCount) * MemoryLayout<processor_cpu_load_info>.size)
                { ptr -> processor_cpu_load_info_t in return ptr }
        currInfo = nil
        
        let processorInfo = UnsafeMutableRawPointer(mutating: currLoad)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: processorInfo), vm_size_t(Int(self.cpuCount) * MemoryLayout<processor_cpu_load_info>.size))
        
        self.prevusages = Array(repeating: cpu_ticks(CPU_STATE_USER: 0, CPU_STATE_SYSTEM: 0, CPU_STATE_IDLE: 0, CPU_STATE_NICE: 0), count: Int(self.cpuCount))
        self.currusages = Array(repeating: cpu_ticks(CPU_STATE_USER: 0, CPU_STATE_SYSTEM: 0, CPU_STATE_IDLE: 0, CPU_STATE_NICE: 0), count: Int(self.cpuCount))
        self.usages = Array(repeating: 0, count: Int(self.cpuCount))
        self.GetSysInfo()
        self.getTotalMemory()
    }
    
    func GetMemUsage(_ vm : inout vm_statistics_data_t){
        let page_K = Double(vm_page_size) / Double(1024)
        let meter_used : Double = Double(vm.active_count + vm.wire_count) * page_K
        self.currMemUsageRaw = meter_used/ONE_K/ONE_K // Get Memory in G
    }
    
    func GetUsagePercentage(_ cpuNum : Int){
        let prev = self.prevusages[cpuNum]
        let curr = self.currusages[cpuNum]
        var total : UInt32 = 0
        
        let diff_user = curr.CPU_STATE_USER - prev.CPU_STATE_USER
        let diff_system = curr.CPU_STATE_SYSTEM - prev.CPU_STATE_SYSTEM
        let diff_nice = curr.CPU_STATE_NICE - prev.CPU_STATE_NICE
        
        total += diff_user
        total += diff_system
        total += curr.CPU_STATE_IDLE - prev.CPU_STATE_IDLE
        total += diff_nice
        // CPU_STATE_MAX = 4
        /*
        let userPercentUsage = diff_user * 100 / total
        let systemPercentUsage = diff_system * 100 / total
        let nicePercentUsage = diff_nice * 100 / total
        self.usages[cpuNum] = userPercentUsage + systemPercentUsage + nicePercentUsage
        */
        self.usages[cpuNum] = Double( (diff_user + diff_system + diff_nice) * 100 / total )
    }
    
    func GetSysInfo () {
        var infoSize = mach_msg_type_number_t(MemoryLayout<processor_cpu_load_info>.stride)
        var currInfo = processor_info_array_t(bitPattern: 0)
        
        guard KERN_SUCCESS == host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &self.cpuCount, &currInfo, &infoSize)
        else {
            //Failed to get system info
            return
        }
        
        let currLoad : processor_cpu_load_info_t = currInfo!.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(self.cpuCount) * MemoryLayout<processor_cpu_load_info>.size)
                { ptr -> processor_cpu_load_info_t in return ptr }
        currInfo = nil
        
        
        for i in 0...(self.cpuCount-1){
            let index = Int(i)
            self.currusages[index].CPU_STATE_USER = currLoad[index].cpu_ticks.0
            self.currusages[index].CPU_STATE_SYSTEM = currLoad[index].cpu_ticks.1
            self.currusages[index].CPU_STATE_IDLE = currLoad[index].cpu_ticks.2
            self.currusages[index].CPU_STATE_USER = currLoad[index].cpu_ticks.3
            self.GetUsagePercentage(index)
        }
        
        let processorInfo = UnsafeMutableRawPointer(mutating: currLoad)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: processorInfo), vm_size_t(Int(self.cpuCount) * MemoryLayout<processor_cpu_load_info>.size))
    }
    
    func getTotalMemory() {
        var info_size : mach_msg_type_number_t = HOST_BASIC_INFO_COUNT
        let tmp_host_info = host_info_t.allocate(capacity: Int(HOST_BASIC_INFO_COUNT))
        
        guard KERN_SUCCESS == host_info(mach_host_self(), HOST_BASIC_INFO, tmp_host_info, &info_size)
        else {
            //Failed to get host_info
            return
        }
        
        let host_info = tmp_host_info.withMemoryRebound(to:  host_basic_info_data_t.self, capacity: Int(HOST_BASIC_INFO_COUNT))
                { ptr -> host_basic_info_data_t in return ptr.pointee }
        self.availMemoryRaw = Double(host_info.max_mem)/ONE_K/ONE_K/ONE_K // Get Memory in G
        tmp_host_info.deallocate()
    }
    
    func getVMStats() {
        var info_size : mach_msg_type_number_t = HOST_BASIC_INFO_COUNT
        let tmp_vm_stats = UnsafeMutablePointer<integer_t>.allocate(capacity: Int(HOST_BASIC_INFO_COUNT))
        
        guard KERN_SUCCESS == host_statistics(mach_host_self(), HOST_VM_INFO, tmp_vm_stats, &info_size)
        else {
            //Failed to get memory info
            return
        }
        var vm_stats = tmp_vm_stats.withMemoryRebound(to:  vm_statistics_data_t.self, capacity: Int(HOST_BASIC_INFO_COUNT))
                { ptr -> vm_statistics_data_t in return ptr.pointee }
        self.GetMemUsage(&vm_stats)
        tmp_vm_stats.deallocate()
    }

}
