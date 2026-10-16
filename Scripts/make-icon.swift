// 生成 Rescribium 应用图标的 1024×1024 主图。
// 用法：swift Scripts/make-icon.swift <输出.png>
import AppKit

guard CommandLine.arguments.count > 1 else {
    fputs("用法: swift make-icon.swift <output.png>\n", stderr)
    exit(2)
}
let outputPath = CommandLine.arguments[1]

let size: CGFloat = 1024
guard let context = CGContext(
    data: nil,
    width: Int(size), height: Int(size),
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("无法创建位图上下文") }

// MARK: - 圆角矩形底（蓝紫渐变）

let iconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let iconPath = CGPath(roundedRect: iconRect, cornerWidth: 186, cornerHeight: 186, transform: nil)

context.saveGState()
context.addPath(iconPath)
context.clip()
let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        CGColor(red: 0.42, green: 0.67, blue: 1.00, alpha: 1), // 顶部亮蓝
        CGColor(red: 0.24, green: 0.39, blue: 0.95, alpha: 1), // 底部蓝紫
    ] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
context.restoreGState()

// MARK: - 文档（带投影与折角）

let docRect = CGRect(x: 322, y: 262, width: 380, height: 500)
let fold: CGFloat = 92

context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -14), blur: 36, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))

// 文档主体：右上角切掉折角
let docPath = CGMutablePath()
docPath.move(to: CGPoint(x: docRect.minX, y: docRect.minY))
docPath.addLine(to: CGPoint(x: docRect.maxX, y: docRect.minY))
docPath.addLine(to: CGPoint(x: docRect.maxX, y: docRect.maxY - fold))
docPath.addLine(to: CGPoint(x: docRect.maxX - fold, y: docRect.maxY))
docPath.addLine(to: CGPoint(x: docRect.minX, y: docRect.maxY))
docPath.closeSubpath()
context.addPath(docPath)
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
context.fillPath()
context.restoreGState()

// 折角三角
let foldPath = CGMutablePath()
foldPath.move(to: CGPoint(x: docRect.maxX - fold, y: docRect.maxY))
foldPath.addLine(to: CGPoint(x: docRect.maxX, y: docRect.maxY - fold))
foldPath.addLine(to: CGPoint(x: docRect.maxX - fold, y: docRect.maxY - fold))
foldPath.closeSubpath()
context.addPath(foldPath)
context.setFillColor(CGColor(red: 0.82, green: 0.86, blue: 0.94, alpha: 1))
context.fillPath()

// MARK: - 文档上的文字行

func textLine(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, gray: CGFloat) {
    let path = CGPath(roundedRect: CGRect(x: x, y: y, width: width, height: height),
                      cornerWidth: height / 2, cornerHeight: height / 2, transform: nil)
    context.addPath(path)
    context.setFillColor(CGColor(red: gray, green: gray + 0.02, blue: gray + 0.06, alpha: 1))
    context.fillPath()
}

let lineX = docRect.minX + 60
textLine(x: lineX, y: 636, width: 170, height: 30, gray: 0.45) // 标题行
textLine(x: lineX, y: 568, width: 260, height: 22, gray: 0.78)
textLine(x: lineX, y: 512, width: 260, height: 22, gray: 0.78)
textLine(x: lineX, y: 456, width: 200, height: 22, gray: 0.78)

// MARK: - 取景框四角（Live Text 括号）

let bracketColor = CGColor(red: 0.38, green: 0.93, blue: 0.85, alpha: 1)
let L: CGFloat = 78          // 括号臂长
let insetX = docRect.minX - 44
let insetY = docRect.minY - 44
let outsetX = docRect.maxX + 44
let outsetY = docRect.maxY + 44

let corners: [(CGPoint, CGPoint, CGPoint)] = [
    // (端点1, 拐角, 端点2)
    (CGPoint(x: insetX + L, y: outsetY), CGPoint(x: insetX, y: outsetY), CGPoint(x: insetX, y: outsetY - L)), // 左上
    (CGPoint(x: outsetX - L, y: outsetY), CGPoint(x: outsetX, y: outsetY), CGPoint(x: outsetX, y: outsetY - L)), // 右上
    (CGPoint(x: insetX + L, y: insetY), CGPoint(x: insetX, y: insetY), CGPoint(x: insetX, y: insetY + L)), // 左下
    (CGPoint(x: outsetX - L, y: insetY), CGPoint(x: outsetX, y: insetY), CGPoint(x: outsetX, y: insetY + L)), // 右下
]
context.setStrokeColor(bracketColor)
context.setLineWidth(26)
context.setLineCap(.round)
context.setLineJoin(.round)
for (a, corner, b) in corners {
    let path = CGMutablePath()
    path.move(to: a)
    path.addLine(to: corner)
    path.addLine(to: b)
    context.addPath(path)
    context.strokePath()
}

// MARK: - 导出 PNG

guard let cgImage = context.makeImage() else { fatalError("无法生成图像") }
let rep = NSBitmapImageRep(cgImage: cgImage)
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("无法编码 PNG") }
do {
    try png.write(to: URL(fileURLWithPath: outputPath))
    print("已生成 \(outputPath)")
} catch {
    fputs("写入失败: \(error)\n", stderr)
    exit(1)
}
