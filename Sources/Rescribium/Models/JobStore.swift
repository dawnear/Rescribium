import AppKit
import Foundation
import Observation

/// 任务队列：按顺序运行待处理任务。
@Observable
@MainActor
final class JobStore {
    var jobs: [OCRJob] = []
    var selection = Set<OCRJob.ID>()
    var isImporterPresented = false
    var isRunning = false
    /// 点击“开始”时的错误（后端缺失、参数非法等），由界面弹窗展示。
    var startError: String?

    private var runTask: Task<Void, Never>?

    var pendingCount: Int { jobs.count { $0.status == .pending } }

    var finishedCount: Int { jobs.count { $0.status.isFinished } }

    var overallProgress: Double {
        guard !jobs.isEmpty else { return 0 }
        let total = jobs.reduce(0.0) { $0 + ($1.status.isFinished ? 1 : $1.progress) }
        return total / Double(jobs.count)
    }

    func add(urls: [URL]) {
        let existing = Set(jobs.map(\.inputURL))
        for url in urls where url.pathExtension.lowercased() == "pdf" && !existing.contains(url) {
            jobs.append(OCRJob(inputURL: url, outputURL: Self.defaultOutputURL(for: url)))
        }
    }

    func remove(ids: Set<OCRJob.ID>) {
        jobs.removeAll { ids.contains($0.id) && $0.status != .processing }
        selection.subtract(ids)
    }

    func clearFinished() {
        let finished = Set(jobs.filter { $0.status.isFinished }.map(\.id))
        remove(ids: finished)
    }

    /// 把任务重置为待处理，可再次运行。
    func reset(ids: Set<OCRJob.ID>) {
        for job in jobs where ids.contains(job.id) && job.status != .processing {
            job.status = .pending
            job.progress = 0
        }
    }

    func openOutput(_ job: OCRJob) {
        NSWorkspace.shared.open(job.outputURL)
    }

    func revealOutput(_ job: OCRJob) {
        NSWorkspace.shared.activateFileViewerSelecting([job.outputURL])
    }

    /// “开始/停止”按钮的唯一入口。
    func requestStart(settings: AppSettings, backend: BackendService) {
        if isRunning {
            stop()
            return
        }
        guard pendingCount > 0 else { return }
        if let message = settings.validationError {
            startError = message
            return
        }
        guard let toolURL = backend.toolURL else {
            startError = "未找到可用的 OCRmyPDF 后端，请在“设置”中检查安装。"
            return
        }
        start(settings: settings, toolURL: toolURL)
    }

    func stop() {
        runTask?.cancel()
    }

    private func start(settings: AppSettings, toolURL: URL) {
        guard !isRunning else { return }
        isRunning = true
        runTask = Task { [weak self] in
            guard let self else { return }
            for job in self.jobs where job.status == .pending {
                if Task.isCancelled { break }
                await self.run(job: job, settings: settings, toolURL: toolURL)
            }
            self.isRunning = false
        }
    }

    private func run(job: OCRJob, settings: AppSettings, toolURL: URL) async {
        job.status = .processing
        job.progress = 0
        job.logText = ""

        // ocrmypdf 不会覆盖已存在的输出文件，运行前重新取一个可用文件名。
        if FileManager.default.fileExists(atPath: job.outputURL.path) {
            job.outputURL = Self.defaultOutputURL(for: job.inputURL)
        }

        var arguments = OCRCommandBuilder.arguments(input: job.inputURL, output: job.outputURL, settings: settings)
        job.logText = "$ ocrmypdf \(arguments.joined(separator: " "))\n\n"

        do {
            var result = try await Self.execute(toolURL: toolURL, arguments: arguments, job: job)

            // PDF/A 转换因源文件缺内嵌字体而失败（中文扫描书常见）：自动改用普通 PDF 重试。
            if result.status != 0, settings.outputPDFA, OutputSanitizer.isPDFAFontError(result.output) {
                job.logText += "\nPDF/A 转换失败：源文件含未内嵌的 CID 中文字体。自动改用普通 PDF 输出重试…\n\n"
                job.progress = 0
                arguments = OCRCommandBuilder.arguments(
                    input: job.inputURL, output: job.outputURL, settings: settings, forcePlainPDF: true
                )
                result = try await Self.execute(toolURL: toolURL, arguments: arguments, job: job)
            }

            if Task.isCancelled {
                job.status = .cancelled
            } else if result.status == 0 {
                job.status = .completed
                job.progress = 1
            } else {
                job.status = .failed
            }
        } catch {
            job.status = .failed
            job.logText += "\n无法启动 ocrmypdf：\(error.localizedDescription)"
        }
    }

    private static func execute(
        toolURL: URL, arguments: [String], job: OCRJob
    ) async throws -> SubprocessResult {
        try await Subprocess().run(executable: toolURL, arguments: arguments, pseudoTTY: true) { chunk in
            Task { @MainActor [weak job] in
                guard let job else { return }
                Self.ingest(chunk: chunk, into: job)
            }
        }
    }

    private static func ingest(chunk: String, into job: OCRJob) {
        if let fraction = OutputSanitizer.progress(in: chunk) {
            job.progress = max(job.progress, min(1, fraction))
        }
        let cleaned = OutputSanitizer.clean(chunk)
        job.logText += cleaned
        if job.logText.count > 200_000 {
            job.logText = String(job.logText.suffix(100_000))
        }
    }

    static func defaultOutputURL(for input: URL) -> URL {
        let base = input.deletingPathExtension()
        var candidate = base.appendingPathExtension("ocr.pdf")
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = base.appendingPathExtension("ocr-\(counter).pdf")
            counter += 1
        }
        return candidate
    }
}
