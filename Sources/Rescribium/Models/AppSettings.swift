import Foundation
import Observation

/// 识别与输出选项，持久化到 UserDefaults。
@Observable
@MainActor
final class AppSettings {
    enum RecognitionMode: String, CaseIterable, Identifiable {
        case liveText = "livetext"
        case accurate
        case fast

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .liveText: "Live Text（推荐，支持竖排文字）"
            case .accurate: "精确"
            case .fast: "快速"
            }
        }
    }

    /// 对已有文本层的页面的处理方式。
    enum TextMode: String, CaseIterable, Identifiable {
        case skipText = "skip-text"
        case redoOCR = "redo-ocr"
        case forceOCR = "force-ocr"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .skipText: "跳过已有文本的页面"
            case .redoOCR: "重做 OCR（保留原页面）"
            case .forceOCR: "强制对所有页面 OCR"
            }
        }
    }

    private let defaults = UserDefaults.standard

    var language: OCRLanguage { didSet { defaults.set(language.rawValue, forKey: "language") } }
    var recognitionMode: RecognitionMode { didSet { defaults.set(recognitionMode.rawValue, forKey: "recognitionMode") } }
    var textMode: TextMode { didSet { defaults.set(textMode.rawValue, forKey: "textMode") } }
    var rotatePages: Bool { didSet { defaults.set(rotatePages, forKey: "rotatePages") } }
    var deskew: Bool { didSet { defaults.set(deskew, forKey: "deskew") } }
    var disableCorrection: Bool { didSet { defaults.set(disableCorrection, forKey: "disableCorrection") } }
    var optimize: Int { didSet { defaults.set(optimize, forKey: "optimize") } }
    var jobs: Int { didSet { defaults.set(jobs, forKey: "jobs") } }
    var outputPDFA: Bool { didSet { defaults.set(outputPDFA, forKey: "outputPDFA") } }
    /// 自定义 ocrmypdf 可执行文件路径，空字符串表示自动检测。
    var customOCRPath: String { didSet { defaults.set(customOCRPath, forKey: "customOCRPath") } }

    init() {
        let defaults = UserDefaults.standard
        language = OCRLanguage(rawValue: defaults.string(forKey: "language") ?? "") ?? .chiSim
        recognitionMode = RecognitionMode(rawValue: defaults.string(forKey: "recognitionMode") ?? "") ?? .liveText
        textMode = TextMode(rawValue: defaults.string(forKey: "textMode") ?? "") ?? .skipText
        rotatePages = defaults.object(forKey: "rotatePages") as? Bool ?? true
        deskew = defaults.bool(forKey: "deskew")
        disableCorrection = defaults.bool(forKey: "disableCorrection")
        let savedOptimize = defaults.object(forKey: "optimize") as? Int ?? 1
        optimize = max(0, min(3, savedOptimize))
        let savedJobs = defaults.integer(forKey: "jobs")
        jobs = savedJobs > 0 ? savedJobs : 4
        outputPDFA = defaults.object(forKey: "outputPDFA") as? Bool ?? true
        customOCRPath = defaults.string(forKey: "customOCRPath") ?? ""
    }

    /// 参数组合是否可运行，返回错误描述（nil 表示可运行）。
    var validationError: String? {
        if language == .und && recognitionMode == .liveText {
            return "Live Text 模式不支持自动语言检测，请选择具体语言，或改用“精确/快速”模式。"
        }
        return nil
    }
}
