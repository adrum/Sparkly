import Foundation

@discardableResult
func shell(_ args: String...) async throws -> Data {
    try await shell(args)
}

@discardableResult
func shell(_ args: [String]) async throws -> Data {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = args

    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr

    return try await withCheckedThrowingContinuation { continuation in
        process.terminationHandler = { process in
            let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
            let errorData = stderr.fileHandleForReading.readDataToEndOfFile()

            if process.terminationStatus == 0 {
                continuation.resume(returning: outputData)
            } else {
                let errorOutput = String(data: errorData, encoding: .utf8)
                    ?? String(data: outputData, encoding: .utf8)
                continuation.resume(throwing: ShellError.exitCode(
                    process.terminationStatus,
                    errorOutput
                ))
            }
        }

        do {
            try process.run()
        } catch {
            continuation.resume(throwing: ShellError.processLaunchFailed(error))
        }
    }
}

func shellOutput(_ args: String...) async throws -> String {
    let data = try await shell(args)
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}
