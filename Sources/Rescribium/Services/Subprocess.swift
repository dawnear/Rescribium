import Foundation

struct SubprocessResult: Sendable {
    var status: Int32
    var output: String
}

/// 运行外部进程，合并 stdout/stderr 并流式回调输出。
final class Subprocess: @unchecked Sendable {
    private let process = Process()
    private let pipe = Pipe()
    private let lock = NSLock()
    private nonisolated(unsafe) var buffer = ""

    /// - Parameters:
    ///   - pseudoTTY: 为 true 时通过 /usr/bin/script 分配伪终端，
    ///     让 ocrmypdf 等工具输出进度条；退出码会透传。
    ///   - onOutput: 每收到一段输出就回调一次（在后台线程）。
    /// - Returns: 退出码与完整输出。
    func run(
        executable: URL,
        arguments: [String],
        extraPathEntries: [String] = ["/opt/homebrew/bin", "/usr/local/bin"],
        pseudoTTY: Bool = false,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws -> SubprocessResult {
        if pseudoTTY {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/script")
            process.arguments = ["-q", "/dev/null", executable.path] + arguments
            process.standardInput = FileHandle.nullDevice
        } else {
            process.executableURL = executable
            process.arguments = arguments
        }

        var environment = ProcessInfo.processInfo.environment
        let existingPath = environment["PATH"] ?? "/usr/bin:/bin"
        environment["PATH"] = (extraPathEntries + [existingPath]).joined(separator: ":")
        process.environment = environment

        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            self.lock.lock()
            self.buffer += text
            self.lock.unlock()
            onOutput?(text)
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { process in
                    self.pipe.fileHandleForReading.readabilityHandler = nil
                    let rest = self.pipe.fileHandleForReading.readDataToEndOfFile()
                    if let text = String(data: rest, encoding: .utf8), !text.isEmpty {
                        self.lock.lock()
                        self.buffer += text
                        self.lock.unlock()
                        onOutput?(text)
                    }
                    self.lock.lock()
                    let output = self.buffer
                    self.lock.unlock()
                    continuation.resume(returning: SubprocessResult(status: process.terminationStatus, output: output))
                }
                do {
                    try process.run()
                } catch {
                    process.terminationHandler = nil
                    pipe.fileHandleForReading.readabilityHandler = nil
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            self.process.terminate()
        }
    }
}
