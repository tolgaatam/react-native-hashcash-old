import Foundation
import CommonCrypto
import Dispatch

// commenting out in order to allow apps targeting below iOS 13 to be able to compile
/*
actor Counter {
    private var count: Int64 = 0
    func fetchIncrement(by: Int64) -> Int64 {
        let currVal = count
        count += by
        return currVal
    }

    func set(val: Int64) {
        count = val
    }
}
*/

// uses old-style Dispatch queues for concurrency
public func calculateHashcashQueue(k: UInt, identifier: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyMMdd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    let ts = formatter.string(from: Date())

    let challenge = "1:\(k):\(ts):\(identifier)::\(salt(length: 16)):"

    let binaryDigitsToConsider = Int(ceil((Double(k) / 8)))
    let limitBeginningSetBits = binaryDigitsToConsider * 8 - Int(k)
    let limitBeginningNum = Int(round(pow(Double(2), Double(limitBeginningSetBits))))
    let limitBeginning = [UInt8](repeating: 0, count: binaryDigitsToConsider-1) + [UInt8](repeating: UInt8(limitBeginningNum), count: 1)

    let processorCount = Int(ProcessInfo.processInfo.activeProcessorCount)

    let threadCount: Int = processorCount*2

    let threadCountLog = Int64(floor(log2(Double(threadCount))));

    let iterationPerThreadPerRound: Int64 = Int64(1) << (Int64(k) - Int64(5) - threadCountLog);

    var lastCounterEnd: Int64 = 0 // counter to be shared by the threads
    var result = ""
    let semaphore = DispatchSemaphore(value: 1)
    
    let _ = DispatchQueue.global(qos: .userInitiated) // this is told to somehow affect the concurrentPerform's qos, and it's true.
    DispatchQueue.concurrentPerform(iterations: threadCount) { index in
        
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        while true {
            semaphore.wait()
            let counterStart = lastCounterEnd
            lastCounterEnd += iterationPerThreadPerRound
            semaphore.signal()

            if counterStart < 0 {
                return // somebody else finished
            }

            let counterEnd = counterStart + iterationPerThreadPerRound
            
            for counter in counterStart..<counterEnd {
                let data = (challenge + String(counter)).data(using: String.Encoding.utf8)!
                data.withUnsafeBytes{ (bytes: UnsafeRawBufferPointer) in
                    _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
                }

                for i in 0..<binaryDigitsToConsider {
                    if hash[i] > limitBeginning[i] {
                        break
                    } else if hash[i] < limitBeginning[i] {
                        semaphore.wait()
                        lastCounterEnd = (Int64(1) << Int64(47)) * Int64(-1)
                        result = challenge + String(counter)
                        semaphore.signal()
                    }
                }
            }
        }
    }

    return result

}

// uses new async/await and actors
// commenting out in order to allow apps targeting below iOS 13 to be able to compile
/*
public func calculateHashcashTask(k: UInt, identifier: String) async -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyMMdd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    let ts = formatter.string(from: Date())

    let challenge = "1:\(k):\(ts):\(identifier)::\(salt(length: 16)):"

    let binaryDigitsToConsider = Int(ceil((Double(k) / 8)))
    let limitBeginningSetBits = binaryDigitsToConsider * 8 - Int(k)
    let limitBeginningNum = Int(round(pow(Double(2), Double(limitBeginningSetBits))))
    let limitBeginning = [UInt8](repeating: 0, count: binaryDigitsToConsider-1) + [UInt8](repeating: UInt8(limitBeginningNum), count: 1)

    let processorCount = Int(ProcessInfo.processInfo.activeProcessorCount)

    let threadCount: Int = processorCount

    let threadCountLog = Int64(floor(log2(Double(threadCount))));

    let iterationPerThreadPerRound: Int64 = Int64(1) << (Int64(k) - Int64(5) - threadCountLog);

    let lastCounterEnd = Counter()

    let results : [String] = await withTaskGroup(of: String.self) { group in 
        for _ in 0..<threadCount {
            group.addTask(priority: .userInitiated) {

                var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
                while true {
                    let counterStart = await lastCounterEnd.fetchIncrement(by: iterationPerThreadPerRound)

                    if counterStart < 0 {
                        return ""; // somebody else finished
                    }       

                    let counterEnd = counterStart + iterationPerThreadPerRound
                    
                    for counter in counterStart..<counterEnd {
                        let data = (challenge + String(counter)).data(using: String.Encoding.utf8)!
                        data.withUnsafeBytes{ (bytes: UnsafeRawBufferPointer) in
                            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
                        }

                        for i in 0..<binaryDigitsToConsider {
                            if hash[i] > limitBeginning[i] {
                                break
                            } else if hash[i] < limitBeginning[i] {
                                await lastCounterEnd.set(val: (Int64(1) << Int64(47)) * Int64(-1))
                                return challenge + String(counter)
                            }
                        }
                    }
                }
                
            }
        }

        var array = [String]()
        for await value in group {
            array.append(value)
        }
        return array
    }

    for result in results {
        if result != "" {
            return result
        }
    }

    return "" // we will never hit this case

}
*/

// sequential base implementation
public func calculateHashcashSequential(k: UInt, identifier: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyMMdd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    let ts = formatter.string(from: Date())

    let challenge = "1:\(k):\(ts):\(identifier)::\(salt(length: 16)):"

    var counter = 0

    let binaryDigitsToConsider = Int(ceil((Double(k) / 8)))
    let limitBeginningSetBits = binaryDigitsToConsider * 8 - Int(k)
    let limitBeginningNum = Int(round(pow(Double(2), Double(limitBeginningSetBits))))
    let limitBeginning = [UInt8](repeating: 0, count: binaryDigitsToConsider-1) + [UInt8](repeating: UInt8(limitBeginningNum), count: 1)

    var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
    while true {
        let data = (challenge + String(counter)).data(using: String.Encoding.utf8)!
        data.withUnsafeBytes{ (bytes: UnsafeRawBufferPointer) in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
        }
        
        for i in 0..<binaryDigitsToConsider {
            if hash[i] > limitBeginning[i] {
                break
            } else if hash[i] < limitBeginning[i] {
                return challenge + String(counter)
            }
        }
        
        counter += 1
    }
}

internal func salt(length: UInt) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+/"
  return String((0..<Int(length)).map{ _ in letters.randomElement()! })
}
