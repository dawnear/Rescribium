import Foundation

/// 定位 ocrmypdf 可执行文件。
enum OCRmyPDFLocator {
    static func locate(customPath: String) async -> URL? {
        let fm = FileManager.default
        func existing(_ path: String) -> URL? {
            fm.isExecutableFile(atPath: path) ? URL(fileURLWithPath: path) : nil
        }

        if !customPath.isEmpty, let url = existing(customPath) {
            return url
        }
        if let envPath = ProcessInfo.processInfo.environment["OCRMYPDF_PATH"],
           let url = existing(envPath) {
            return url
        }

        let candidates = [
            fm.currentDirectoryPath + "/.venv/bin/ocrmypdf",
            "/opt/homebrew/bin/ocrmypdf",
            "/usr/local/bin/ocrmypdf",
            NSHomeDirectory() + "/.local/bin/ocrmypdf",
        ]
        for path in candidates {
            if let url = existing(path) {
                return url
            }
        }

        if let found = await findInLoginShell(), let url = existing(found) {
            return url
        }
        return nil
    }

    /// 在登录 shell 中查找（覆盖 pipx、conda 等 PATH 配置）。
    private static func findInLoginShell() async -> String? {
        let result = try? await Subprocess().run(
            executable: URL(fileURLWithPath: "/bin/zsh"),
            arguments: ["-lc", "command -v ocrmypdf"],
            extraPathEntries: []
        )
        guard let result, result.status == 0 else { return nil }
        return result.output
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespaces)
            .nilIfEmpty
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
