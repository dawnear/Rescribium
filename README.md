# Rescribium

A native macOS app that adds a searchable, selectable OCR text layer to scanned PDFs using **Apple Vision** — with [OCRmyPDF](https://github.com/ocrmypdf/OCRmyPDF) handling the PDF pipeline via the [OCRmyPDF-AppleOCR](https://github.com/mkyt/OCRmyPDF-AppleOCR) plugin. Fast, accurate, and 100% on-device.

Built with SwiftUI. No Electron, no cloud, no Tesseract.

## Features

- Drag & drop or batch-import PDFs, sequential queue with live progress and per-job logs
- Apple Vision / Live Text OCR: Simplified/Traditional Chinese, Japanese, Korean, English, and 25+ other languages, including vertical CJK text
- Live Text / accurate / fast recognition modes, optional language correction
- Page rotation correction and deskew; skip, redo, or force OCR on pages with existing text
- PDF/A output with automatic fallback to plain PDF when source fonts prevent PDF/A conversion
- Output written next to the source as `<name>.ocr.pdf`, never overwriting existing files

## Requirements

- macOS 15 or later, Apple Silicon
- [Homebrew](https://brew.sh) (for the OCR backend setup)

## Getting started

```sh
# System dependencies for OCRmyPDF
brew install python@3.13 ghostscript qpdf

# Project-local OCR backend: .venv + ocrmypdf + ocrmypdf-appleocr
./Scripts/setup-backend.sh

# Build and run
./Scripts/build-app.sh
open Rescribium.app
```

The app auto-detects the OCR backend at launch (status shown in the bottom-left corner); a custom `ocrmypdf` path can be set in Settings.

For development, `swift build` and `swift run` work as usual.

## Project layout

```
Sources/Rescribium/
  Models/     # Job queue, job model, persisted settings (@Observable)
  Services/   # Subprocess runner (PTY), backend discovery, CLI arguments, log/progress parsing
  Views/      # Main window, job table, options/log inspector, Settings scene
Scripts/      # Backend setup, app bundling, icon generation
Resources/    # App icon
Config/       # Info.plist
```

## License

Apache 2.0 — Copyright 2026 Dawnear and Ecotone Studio
