import Foundation
import Observation

/// 单个 OCR 任务。
@Observable
@MainActor
final class OCRJob: Identifiable {
    enum Status: Equatable {
        case pending
        case processing
        case completed
        case failed
        case cancelled

        var isFinished: Bool {
            switch self {
            case .completed, .failed, .cancelled: true
            case .pending, .processing: false
            }
        }

        var title: String {
            switch self {
            case .pending: "等待中"
            case .processing: "处理中"
            case .completed: "已完成"
            case .failed: "失败"
            case .cancelled: "已取消"
            }
        }

        var systemImage: String {
            switch self {
            case .pending: "clock"
            case .processing: "gearshape.2"
            case .completed: "checkmark.circle.fill"
            case .failed: "exclamationmark.circle.fill"
            case .cancelled: "stop.circle"
            }
        }
    }

    let id = UUID()
    let inputURL: URL
    var outputURL: URL
    var status: Status = .pending
    /// 0…1，仅处理中有意义。
    var progress: Double = 0
    var logText = ""

    init(inputURL: URL, outputURL: URL) {
        self.inputURL = inputURL
        self.outputURL = outputURL
    }
}
