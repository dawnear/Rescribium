import Foundation

/// 由设置构造 ocrmypdf 命令行参数。
@MainActor
enum OCRCommandBuilder {
    static func arguments(input: URL, output: URL, settings: AppSettings, forcePlainPDF: Bool = false) -> [String] {
        var args: [String] = [
            "--ocr-engine", "appleocr",
            "-l", settings.language.rawValue,
            "--appleocr-recognition-mode", settings.recognitionMode.rawValue,
            "--\(settings.textMode.rawValue)",
            "--output-type", settings.outputPDFA && !forcePlainPDF ? "pdfa" : "pdf",
            "-O", String(settings.optimize),
            "-j", String(settings.jobs),
        ]
        if settings.rotatePages { args.append("--rotate-pages") }
        if settings.deskew { args.append("--deskew") }
        if settings.disableCorrection { args.append("--appleocr-disable-correction") }
        args.append(input.path)
        args.append(output.path)
        return args
    }
}

/// 清理并解析 ocrmypdf 输出。
enum OutputSanitizer {
    private static let ansiRegex = try! NSRegularExpression(pattern: "\\x1B\\[[0-9;?]*[A-Za-z]")
    private static let percentRegex = try! NSRegularExpression(pattern: "(\\d{1,3})%")
    private static let fractionRegex = try! NSRegularExpression(pattern: "(\\d{1,5})\\s*/\\s*(\\d{1,5})")

    /// 去掉 ANSI 转义序列和进度条行，供日志显示。
    static func clean(_ text: String) -> String {
        let range = NSRange(text.startIndex..., in: text)
        let noAnsi = ansiRegex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
        let normalized = noAnsi
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized
            .components(separatedBy: "\n")
            .filter { !$0.contains("━") && !$0.contains("─") }
        return lines.joined(separator: "\n")
    }

    /// 输出是否是“PDF/A 需要内嵌字体但源文件缺失”的错误（中文扫描书常见）。
    static func isPDFAFontError(_ output: String) -> Bool {
        output.contains("NonEmbeddedFontsError")
            || output.contains("PDF/A requires all fonts to be embedded")
    }

    /// 从一段输出中提取进度（0…1）。优先取 “已完成/总数”，其次取百分比。
    static func progress(in text: String) -> Double? {
        let range = NSRange(text.startIndex..., in: text)

        let fractions = fractionRegex.matches(in: text, range: range)
        if let last = fractions.last,
           let doneRange = Range(last.range(at: 1), in: text),
           let totalRange = Range(last.range(at: 2), in: text),
           let done = Double(text[doneRange]),
           let total = Double(text[totalRange]),
           total > 0, done <= total {
            return done / total
        }

        let percents = percentRegex.matches(in: text, range: range)
        if let last = percents.last,
           let valueRange = Range(last.range(at: 1), in: text),
           let percent = Double(text[valueRange]),
           percent <= 100 {
            return percent / 100
        }
        return nil
    }
}
