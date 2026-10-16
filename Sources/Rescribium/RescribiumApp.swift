import SwiftUI

@main
struct RescribiumApp: App {
    @State private var settings = AppSettings()
    @State private var store = JobStore()
    @State private var backend = BackendService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .environment(store)
                .environment(backend)
                .frame(minWidth: 760, minHeight: 440)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("添加 PDF…") {
                    store.isImporterPresented = true
                }
                .keyboardShortcut("o")
            }
            CommandMenu("任务") {
                Button(store.isRunning ? "停止处理" : "开始处理") {
                    store.requestStart(settings: settings, backend: backend)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(!store.isRunning && store.pendingCount == 0)

                Button("清除已完成") {
                    store.clearFinished()
                }
                .disabled(store.isRunning || !store.jobs.contains { $0.status.isFinished })

                Button("移除所选") {
                    store.remove(ids: store.selection)
                }
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled(store.isRunning || store.selection.isEmpty)
            }
        }

        Settings {
            SettingsView()
                .environment(settings)
                .environment(backend)
        }
    }
}
