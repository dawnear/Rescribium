import AppKit
import SwiftUI

/// 选中任务的 ocrmypdf 运行日志。
struct LogPane: View {
    @Environment(JobStore.self) private var store

    private var selectedJob: OCRJob? {
        store.jobs.first { store.selection.contains($0.id) }
    }

    var body: some View {
        if let job = selectedJob {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(job.logText.isEmpty ? "（暂无日志）" : job.logText)
                                .font(.caption.monospaced())
                                .foregroundStyle(job.logText.isEmpty ? .secondary : .primary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Color.clear
                                .frame(height: 1)
                                .id("logBottom")
                        }
                        .padding(8)
                    }
                    .onChange(of: job.logText) {
                        proxy.scrollTo("logBottom")
                    }
                }

                Divider()

                HStack {
                    Text(job.inputURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(job.logText, forType: .string)
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                    .disabled(job.logText.isEmpty)
                }
                .padding(8)
            }
        } else {
            ContentUnavailableView(
                "未选择任务",
                systemImage: "doc.text.magnifyingglass",
                description: Text("在列表中选择一个任务以查看日志。")
            )
        }
    }
}

#Preview {
    let store = JobStore()
    let job = OCRJob(
        inputURL: URL(fileURLWithPath: "/tmp/扫描件.pdf"),
        outputURL: URL(fileURLWithPath: "/tmp/扫描件.ocr.pdf")
    )
    job.logText = "$ ocrmypdf --ocr-engine appleocr …\n\nScanning contents ━━━━ 100%\nOCR ━━━━ 100%\nDone."
    job.status = .completed
    store.jobs = [job]
    store.selection = [job.id]
    return LogPane().environment(store)
}
