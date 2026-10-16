import SwiftUI

/// 识别与输出选项（写入 AppSettings，作用于之后开始的任务）。
struct OptionsPane: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("识别") {
                Picker("识别语言", selection: $settings.language) {
                    ForEach(OCRLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }

                Picker("识别模式", selection: $settings.recognitionMode) {
                    ForEach(AppSettings.RecognitionMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Picker("已有文本的页面", selection: $settings.textMode) {
                    ForEach(AppSettings.TextMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Toggle("自动校正页面方向", isOn: $settings.rotatePages)
                Toggle("去倾斜", isOn: $settings.deskew)
                Toggle("停用语言纠正", isOn: $settings.disableCorrection)
            }

            Section("输出") {
                Stepper("优化等级：\(settings.optimize)", value: $settings.optimize, in: 0 ... 3)
                Stepper("并行页数：\(settings.jobs)", value: $settings.jobs, in: 1 ... 8)
                Toggle("输出为 PDF/A", isOn: $settings.outputPDFA)
            }

            if let error = settings.validationError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    OptionsPane()
        .environment(AppSettings())
}
