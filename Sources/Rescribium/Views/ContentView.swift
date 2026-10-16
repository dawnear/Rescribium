import SwiftUI

struct ContentView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(JobStore.self) private var store
    @Environment(BackendService.self) private var backend

    @State private var showInspector = true
    @State private var inspectorTab: InspectorTab = .options
    @State private var isDropTargeted = false

    private enum InspectorTab: String, CaseIterable, Identifiable {
        case options, log

        var id: Self { self }

        var title: String {
            switch self {
            case .options: "选项"
            case .log: "日志"
            }
        }
    }

    var body: some View {
        @Bindable var store = store

        mainContent
            .navigationTitle("Rescribium")
            .toolbar { toolbarContent }
            .inspector(isPresented: $showInspector) {
                inspectorContent
                    .inspectorColumnWidth(min: 250, ideal: 300, max: 420)
            }
            .fileImporter(
                isPresented: $store.isImporterPresented,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    store.add(urls: urls)
                }
            }
            .fileDialogMessage("选择要 OCR 的 PDF 文件")
            .dropDestination(for: URL.self) { urls, _ in
                store.add(urls: urls)
                return true
            } isTargeted: { targeted in
                isDropTargeted = targeted
            }
            .alert("无法开始处理", isPresented: startErrorPresented, presenting: store.startError) { _ in
                Button("好", role: .cancel) {}
            } message: { message in
                Text(message)
            }
            .task {
                await backend.refresh(customPath: settings.customOCRPath)
            }
            .onChange(of: settings.customOCRPath) {
                Task { await backend.refresh(customPath: settings.customOCRPath) }
            }
    }

    private var startErrorPresented: Binding<Bool> {
        Binding(
            get: { store.startError != nil },
            set: { if !$0 { store.startError = nil } }
        )
    }

    // MARK: - 主内容

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            if store.jobs.isEmpty {
                emptyState
            } else {
                JobTableView()
            }
            Divider()
            footerBar
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.blue, lineWidth: 3)
                    .padding(4)
                    .allowsHitTesting(false)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("将扫描版 PDF 拖到这里", systemImage: "doc.text.viewfinder")
        } description: {
            Text("也可以点击工具栏的“添加”按钮选择文件。\nOCR 引擎：Apple Vision（通过 OCRmyPDF 调用）。")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerBar: some View {
        HStack(spacing: 12) {
            backendIndicator
            Spacer()
            if store.isRunning {
                ProgressView(value: store.overallProgress)
                    .frame(width: 160)
                Text("\(store.finishedCount)/\(store.jobs.count)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            } else {
                Text("\(store.jobs.count) 个任务 · \(store.pendingCount) 个待处理")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var backendIndicator: some View {
        switch backend.state {
        case .unknown, .checking:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("正在检测 OCR 后端…").foregroundStyle(.secondary)
            }
        case .ready(let version):
            Label("OCRmyPDF \(version) · Apple OCR", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .missingOCRmyPDF:
            Label("未找到 OCRmyPDF（见“设置”）", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .missingPlugin:
            Label("缺少 ocrmypdf-appleocr 插件（见“设置”）", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .failed:
            Label("OCR 后端不可用（见“设置”）", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    // MARK: - 工具栏

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                store.isImporterPresented = true
            } label: {
                Label("添加", systemImage: "plus")
            }
            .help("添加 PDF 文件 (⌘O)")

            Button {
                store.requestStart(settings: settings, backend: backend)
            } label: {
                Label(
                    store.isRunning ? "停止" : "开始",
                    systemImage: store.isRunning ? "stop.fill" : "play.fill"
                )
            }
            .disabled(!store.isRunning && store.pendingCount == 0)
            .help(store.isRunning ? "停止处理 (⌘⏎)" : "开始处理待处理任务 (⌘⏎)")

            Button {
                showInspector.toggle()
            } label: {
                Label("检查器", systemImage: "sidebar.trailing")
            }
            .help("显示/隐藏检查器")
        }
    }

    // MARK: - 检查器

    private var inspectorContent: some View {
        VStack(spacing: 0) {
            Picker("检查器", selection: $inspectorTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .padding(8)

            switch inspectorTab {
            case .options:
                OptionsPane()
            case .log:
                LogPane()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppSettings())
        .environment(JobStore())
        .environment(BackendService())
}
