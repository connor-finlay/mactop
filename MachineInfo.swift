import Foundation

let HOST_BASIC_INFO_COUNT =  mach_msg_type_number_t(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
let ONE_K: Double = 1024

class MachineInfo : ObservableObject {
    var prevLoad: processor_cpu_load_info_t? = processor_cpu_load_info_t(bitPattern: 0)
    var currLoad: processor_cpu_load_info_t? = processor_cpu_load_info_t(bitPattern: 0)

    @Published var cpuCount: natural_t = 0
    @Published var usages: [Double] = []
    @Published var currMemUsageRaw : Double = 0.0
    @Published var availMemoryRaw : Double = 0.0
    
    init() {
        self.GetSysInfo()
        self.usages = Array(repeating: 0, count: Int(self.cpuCount))
        self.getTotalMemory()
    }
    
    deinit {
        do {
            // Try and free previous load -> to account for timer
            freePreviousCPUInfo()
        }
        freeCurrentCPUInfo()
    }
    
    func freeCurrentCPUInfo() {
        let processorInfo = UnsafeMutableRawPointer(mutating: self.currLoad)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: processorInfo), vm_size_t(Int(self.cpuCount) * MemoryLayout<processor_cpu_load_info>.size))
        self.currLoad = nil
    }
    
    func freePreviousCPUInfo() {
        let processorInfo = UnsafeMutableRawPointer(mutating: self.prevLoad)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: processorInfo), vm_size_t(Int(self.cpuCount) * MemoryLayout<processor_cpu_load_info>.size))
        self.prevLoad = nil
    }
    
    func GetMemUsage(_ vm : inout vm_statistics_data_t){
        let page_K = Double(vm_page_size) / Double(1024)
        let meter_used : Double = Double(vm.active_count + vm.wire_count) * page_K
        self.currMemUsageRaw = meter_used/ONE_K/ONE_K // Get Memory in G
    }
    
    func GetUsagePercentage(_ cpuNum : Int){
        let prev = self.prevLoad![cpuNum]
        let curr = self.currLoad![cpuNum]
        
        let diff_user = Double(curr.cpu_ticks.0) - Double(prev.cpu_ticks.0)
        let diff_system =  Double(curr.cpu_ticks.1) - Double(prev.cpu_ticks.1)
        let diff_idle = Double(curr.cpu_ticks.2) - Double(prev.cpu_ticks.2)
        let diff_nice = Double(curr.cpu_ticks.3) - Double(prev.cpu_ticks.3)
        // CPU_STATE_MAX = 4
        let total : Double = diff_user + diff_system + diff_idle + diff_nice
        
        let userPercentUsage = diff_user  * 100 / total
        let systemPercentUsage = diff_system  * 100 / total
        let nicePercentUsage =  diff_nice  * 100 / total
        
        self.usages[cpuNum]  = userPercentUsage + systemPercentUsage + nicePercentUsage

    }
    
    func GetSysInfo () {
        var infoSize = mach_msg_type_number_t(MemoryLayout<processor_cpu_load_info>.stride)
        self.prevLoad = self.currLoad
        var currInfo = processor_info_array_t(bitPattern: 0)
        
        guard KERN_SUCCESS == host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &self.cpuCount, &currInfo, &infoSize)
        else {
            //Failed to get system info
            return
        }
        
        self.currLoad = currInfo!.withMemoryRebound(to: processor_cpu_load_info.self, capacity: Int(self.cpuCount) * MemoryLayout<processor_cpu_load_info>.size)
                { ptr -> processor_cpu_load_info_t in return ptr }
        currInfo = nil
        
        if (prevLoad != nil) {
            for i in 0...(self.cpuCount-1){
                self.GetUsagePercentage(Int(i))
            }
            self.freePreviousCPUInfo()
        }
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
