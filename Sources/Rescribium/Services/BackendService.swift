import Foundation
import Observation

/// 检测 OCR 后端（OCRmyPDF + Apple OCR 插件）是否可用。
@Observable
@MainActor
final class BackendService {
    enum State: Equatable {
        case unknown
        case checking
        case ready(version: String)
        case missingOCRmyPDF
        case missingPlugin
        case failed(String)
    }

    private(set) var state: State = .unknown
    private(set) var toolURL: URL?

    func refresh(customPath: String) async {
        state = .checking
        toolURL = nil

        guard let url = await OCRmyPDFLocator.locate(customPath: customPath) else {
            state = .missingOCRmyPDF
            return
        }

        do {
            let version = try await Subprocess().run(executable: url, arguments: ["--version"])
            guard version.status == 0 else {
                state = .failed("OCRmyPDF 无法运行（退出码 \(version.status)）")
                return
            }
            let help = try await Subprocess().run(executable: url, arguments: ["--help"])
            guard help.output.contains("appleocr") else {
                state = .missingPlugin
                return
            }
            toolURL = url
            state = .ready(version: version.output.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
