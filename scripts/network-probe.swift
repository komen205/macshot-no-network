import Foundation
import Darwin

// Run only against the loopback fixture in check-no-network.py.
guard CommandLine.arguments.count == 2, let port = UInt16(CommandLine.arguments[1]) else {
    exit(2)
}
var address = sockaddr_in()
address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
address.sin_family = sa_family_t(AF_INET)
address.sin_port = port.bigEndian
address.sin_addr.s_addr = inet_addr("127.0.0.1")

func connectSocket(_ kind: Int32) -> [String: Int] {
    let descriptor = socket(AF_INET, kind, 0)
    guard descriptor >= 0 else { return ["result": -1, "errno": Int(errno)] }
    defer { close(descriptor) }
    let result = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            Darwin.connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
    let failure = result < 0 ? Int(errno) : 0
    if result == 0, kind == SOCK_DGRAM {
        let payload: [UInt8] = [1]
        _ = payload.withUnsafeBytes { send(descriptor, $0.baseAddress, $0.count, 0) }
    }
    return ["result": Int(result), "errno": failure]
}

var results: [String: Any] = ["tcp": connectSocket(SOCK_STREAM), "udp": connectSocket(SOCK_DGRAM)]
let completed = DispatchSemaphore(value: 0)
let config = URLSessionConfiguration.ephemeral
config.timeoutIntervalForRequest = 3
config.timeoutIntervalForResource = 3
let session = URLSession(configuration: config)
session.dataTask(with: URL(string: "http://127.0.0.1:\(port)/")!) { data, response, error in
    results["http"] = ["success": (response as? HTTPURLResponse)?.statusCode == 200,
                       "error": error?.localizedDescription ?? ""]
    completed.signal()
}.resume()
if completed.wait(timeout: .now() + 5) == .timedOut { exit(3) }
session.invalidateAndCancel()
let json = try JSONSerialization.data(withJSONObject: results, options: [.sortedKeys])
print(String(decoding: json, as: UTF8.self))
