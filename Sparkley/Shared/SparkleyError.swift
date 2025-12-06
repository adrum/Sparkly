import Foundation

enum SparkleyError: LocalizedError {
    case indexFetchFailed(underlying: Error)
    case indexDecodingFailed(underlying: Error)
    case appcastFetchFailed(URL, underlying: Error)
    case appcastParsingFailed(Error?)
    case simulatorNotFound(String)
    case simulatorBootFailed(String, underlying: Error)
    case installationFailed(String, underlying: Error)
    case launchFailed(String, underlying: Error)
    case downloadFailed(URL, underlying: Error)
    case downloadCancelled
    case extractionFailed(URL, underlying: Error?)
    case cacheStoreFailed(underlying: Error)
    case cacheEvictionFailed(underlying: Error)
    case shellCommandFailed(command: String, exitCode: Int32, output: String?)
    case invalidURL(String)
    case noIndexConfigured
    case unsupportedPlatform(Platform)
    case fileNotFound(URL)
    case adbNotFound
    case emulatorNotFound(String)
    case platformMismatch(expected: Platform, got: Platform)

    var errorDescription: String? {
        switch self {
        case .indexFetchFailed(let error):
            return "Failed to fetch app index: \(error.localizedDescription)"
        case .indexDecodingFailed(let error):
            return "Failed to decode app index: \(error.localizedDescription)"
        case .appcastFetchFailed(let url, let error):
            return "Failed to fetch appcast from \(url): \(error.localizedDescription)"
        case .appcastParsingFailed(let error):
            return "Failed to parse appcast: \(error?.localizedDescription ?? "Unknown error")"
        case .simulatorNotFound(let udid):
            return "Simulator \(udid) not found"
        case .simulatorBootFailed(let udid, let error):
            return "Failed to boot simulator \(udid): \(error.localizedDescription)"
        case .installationFailed(let bundleID, let error):
            return "Failed to install \(bundleID): \(error.localizedDescription)"
        case .launchFailed(let bundleID, let error):
            return "Failed to launch \(bundleID): \(error.localizedDescription)"
        case .downloadFailed(let url, let error):
            return "Failed to download \(url.lastPathComponent): \(error.localizedDescription)"
        case .downloadCancelled:
            return "Download was cancelled"
        case .extractionFailed(let url, let error):
            let base = "Failed to extract \(url.lastPathComponent)"
            if let error {
                return "\(base): \(error.localizedDescription)"
            }
            return base
        case .cacheStoreFailed(let error):
            return "Failed to store in cache: \(error.localizedDescription)"
        case .cacheEvictionFailed(let error):
            return "Failed to evict cache: \(error.localizedDescription)"
        case .shellCommandFailed(let command, let exitCode, let output):
            var message = "Command '\(command)' failed with exit code \(exitCode)"
            if let output, !output.isEmpty {
                message += ": \(output)"
            }
            return message
        case .invalidURL(let string):
            return "Invalid URL: \(string)"
        case .noIndexConfigured:
            return "No index URL configured. Please configure an index URL in Settings."
        case .unsupportedPlatform(let platform):
            return "\(platform.displayName) is not yet supported"
        case .fileNotFound(let url):
            return "File not found: \(url.path)"
        case .adbNotFound:
            return "Android Debug Bridge (adb) not found. Please install Android SDK."
        case .emulatorNotFound(let message):
            return "Android emulator not found: \(message)"
        case .platformMismatch(let expected, let got):
            return "Platform mismatch: expected \(expected.displayName), got \(got.displayName)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .indexFetchFailed, .appcastFetchFailed:
            return "Check your network connection and try again."
        case .noIndexConfigured:
            return "Go to Settings and enter your app index URL."
        case .simulatorNotFound:
            return "Open Xcode and ensure simulators are installed."
        case .downloadCancelled:
            return "You can restart the download from the build list."
        default:
            return nil
        }
    }
}

enum ShellError: LocalizedError {
    case exitCode(Int32, String?)
    case processLaunchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .exitCode(let code, let output):
            var message = "Command exited with code \(code)"
            if let output, !output.isEmpty {
                message += ": \(output.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
            return message
        case .processLaunchFailed(let error):
            return "Failed to launch process: \(error.localizedDescription)"
        }
    }
}
