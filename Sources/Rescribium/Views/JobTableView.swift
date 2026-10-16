import SwiftUI

struct JobTableView: View {
    @Environment(JobStore.self) private var store

    var body: some View {
        @Bindable var store = store

        Table(store.jobs, selection: $store.selection) {
            TableColumn("文件") { job in
                Label(job.inputURL.lastPathComponent, systemImage: "doc.fill")
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(job.inputURL.path)
            }
            .width(min: 180, ideal: 280)

            TableColumn("状态") { job in
                Label(job.status.title, systemImage: job.status.systemImage)
                    .foregroundStyle(statusColor(for: job.status))
            }
            .width(90)

            TableColumn("进度") { job in
                switch job.status {
                case .processing:
                    ProgressView(value: job.progress)
                case .completed:
                    Text("100%").foregroundStyle(.secondary)
                default:
                    Text("—").foregroundStyle(.tertiary)
                }
            }
            .width(110)

            TableColumn("输出文件") { job in
                Text(job.outputURL.lastPathComponent)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .width(min: 160, ideal: 240)
        }
        .contextMenu(forSelectionType: OCRJob.ID.self) { ids in
            contextMenu(for: ids)
        }
    }

    private func statusColor(for status: OCRJob.Status) -> Color {
        switch status {
        case .pending: .secondary
        case .processing: .blue
        case .completed: .green
        case .failed: .red
        case .cancelled: .orange
        }
    }

    @ViewBuilder
    private func contextMenu(for ids: Set<OCRJob.ID>) -> some View {
        let selected = store.jobs.filter { ids.contains($0.id) }

        if selected.contains(where: { $0.status == .completed }) {
            Button("打开输出文件") {
                selected.filter { $0.status == .completed }.forEach(store.openOutput)
            }
            Button("在 Finder 中显示") {
                selected.filter { $0.status == .completed }.forEach(store.revealOutput)
            }
            Divider()
        }

        if selected.contains(where: { $0.status.isFinished }) {
            Button("重新处理") {
                store.reset(ids: ids)
            }
            Divider()
        }

        Button("从列表移除", role: .destructive) {
            store.remove(ids: ids)
        }
        .disabled(store.isRunning)
    }
}

#Preview {
    let store = JobStore()
    let job = OCRJob(
        inputURL: URL(fileURLWithPath: "/tmp/扫描件.pdf"),
        outputURL: URL(fileURLWithPath: "/tmp/扫描件.ocr.pdf")
    )
    store.jobs = [job]
    return JobTableView().environment(store)
}
