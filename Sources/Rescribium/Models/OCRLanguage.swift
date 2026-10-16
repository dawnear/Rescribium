import Foundation

/// OCRmyPDF-AppleOCR 插件支持的语言（macOS 26）。
enum OCRLanguage: String, CaseIterable, Identifiable {
    case und
    case eng, fra, ita, deu, spa, por
    case chiSim = "chi_sim"
    case chiTra = "chi_tra"
    case yueSim = "yue_sim"
    case yueTra = "yue_tra"
    case kor, jpn, rus, ukr, tha, vie, ara, ars, tur, ind
    case ces, dan, nld, nor, nno, nob, msa, pol, ron, swe

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .und: "自动检测"
        case .eng: "英语"
        case .fra: "法语"
        case .ita: "意大利语"
        case .deu: "德语"
        case .spa: "西班牙语"
        case .por: "葡萄牙语"
        case .chiSim: "简体中文"
        case .chiTra: "繁体中文"
        case .yueSim: "粤语（简体）"
        case .yueTra: "粤语（繁体）"
        case .kor: "韩语"
        case .jpn: "日语"
        case .rus: "俄语"
        case .ukr: "乌克兰语"
        case .tha: "泰语"
        case .vie: "越南语"
        case .ara: "阿拉伯语"
        case .ars: "阿拉伯语（纳季德）"
        case .tur: "土耳其语"
        case .ind: "印尼语"
        case .ces: "捷克语"
        case .dan: "丹麦语"
        case .nld: "荷兰语"
        case .nor: "挪威语"
        case .nno: "挪威语（尼诺斯克）"
        case .nob: "挪威语（书面）"
        case .msa: "马来语"
        case .pol: "波兰语"
        case .ron: "罗马尼亚语"
        case .swe: "瑞典语"
        }
    }

    /// LiveText 模式不支持自动语言检测。
    var supportsLiveText: Bool { self != .und }
}
