import SwiftUI

/// 设置窗口：OCR 后端配置与状态。
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(BackendService.self) private var backend

    @State private var isToolImporterPresented = false

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                LabeledContent("OCRmyPDF 路径") {
                    TextField("留空则自动检测", text: $settings.customOCRPath)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Button("选择…") {
                        isToolImporterPresented = true
                    }
                    Button("自动检测") {
                        settings.customOCRPath = ""
                    }
                    Spacer()
                    Button("重新检测") {
                        Task { await backend.refresh(customPath: settings.customOCRPath) }
                    }
                    .disabled(backend.state == .checking)
                }

                statusRow
            } header: {
                Text("OCR 后端")
            } footer: {
                Text("需要 OCRmyPDF 17 及以上版本，并安装 ocrmypdf-appleocr 插件（通过 pip 安装，调用 Apple Vision / Live Text）。")
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 560)
        .fixedSize(horizontal: false, vertical: true)
        .fileImporter(
            isPresented: $isToolImporterPresented,
            allowedContentTypes: [.item]
        ) { result in
            if case .success(let url) = result {
                settings.customOCRPath = url.path
            }
        }
        .task {
            if backend.state == .unknown {
                await backend.refresh(customPath: settings.customOCRPath)
            }
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        switch backend.state {
        case .unknown:
            EmptyView()
        case .checking:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("正在检测…").foregroundStyle(.secondary)
            }
        case .ready(let version):
            Label("OCRmyPDF \(version) · Apple OCR 插件已就绪", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .missingOCRmyPDF:
            Label("未找到 OCRmyPDF", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .missingPlugin:
            Label("已找到 OCRmyPDF，但缺少 ocrmypdf-appleocr 插件", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .failed(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings())
        .environment(BackendService())
}
