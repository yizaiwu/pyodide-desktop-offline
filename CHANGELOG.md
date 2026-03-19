# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.6] - 2026-03-18

### Added
- 發布 Pyodide Console Desktop v2.6 final 版本
- 支援完全離線運作，無需任何網路連線
- 內建 HTTP Server 解決 WebView2 CORS header 限制問題

### Built-in Packages
- numpy - 數值計算
- matplotlib - 繪圖
- scipy - 科學計算
- pandas - 資料處理
- scikit-learn - 機器學習
- pillow - 影像處理
- sympy - 符號運算

### Features
- 完整 Python 3.12 標準函式庫
- 多行輸入模式（`def`/`class`/`for` 等自動切換）
- 指令歷史紀錄（最多 200 筆）
- stdout/stderr 分色顯示
- Ctrl+L 清除 console
- 免安裝設計

### Technical
- 使用 Rust + wry + tao 框架
- 內建 tiny_http 提供靜態檔案服務（port 18374）
- 使用 WebView2 作為前端執行環境

---

## [2.5] - [日期]

### Added
- [待補充]

### Changed
- [待補充]

### Fixed
- [待補充]

---

## [2.0] - [日期]

### Added
- [待補充]

---

## [1.0] - [日期]

### Added
- [待補充]
