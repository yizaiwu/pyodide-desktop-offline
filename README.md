# Pyodide Console Desktop (Offline)

[![License: MIT + Commercial](https://img.shields.io/badge/License-MIT%20%2B%20Commercial-blue.svg)](LICENSE)
[![Python 3.12](https://img.shields.io/badge/Python-3.12-green.svg)](https://python.org)
[![Rust](https://img.shields.io/badge/Rust-2021-orange.svg)](https://rust-lang.org)

**完全離線的 Python REPL 桌面程式**，使用 Rust + wry + Pyodide WASM 製作。適用於需要在無網路環境中執行 Python 程式碼的場景。

---

## 目錄

- [專案 Tech Stack](#專案-tech-stack)
- [專案 Build 說明](#專案-build-說明)
- [程式使用說明](#程式使用說明)
- [如何手動安裝離線套件](#如何手動安裝離線套件)
- [License：雙重授權模式](#license雙重授權模式)
- [常見問題](#常見問題)

---

## 專案 Tech Stack

此專案採用 Rust 作為後端，搭配 WebView2 與 Pyodide WASM 實現離線 Python 執行環境。

### 後端技術（Rust）

| 技術 | 版本 | 用途說明 |
|------|------|----------|
| **Rust** | 2021 edition | 程式語言 |
| **wry** | 0.47 | 嵌入 WebView2 瀏覽器元件 |
| **tao** | 0.33 | 建立原生 Windows 視窗 |
| **tiny_http** | 0.12 | 內建 HTTP Server（port 18374）提供靜態檔案 |
| **mime_guess** | 2.0 | 依副檔名自動推斷 MIME type |
| **ctrlc** | 3.4 | 處理 Ctrl+C 中斷訊號 |

### 前端技術

| 技術 | 用途說明 |
|------|----------|
| **WebView2** | Windows 11 內建的嵌入式瀏覽器（Edge Chromium） |
| **Pyodide** | 在瀏覽器中執行 Python 的 WASM 實現 |
| **console.html** | Python REPL 網頁介面 |

### 架構示意圖

```
┌─────────────────────────────────────────────────────────────┐
│                    pyodide-desktop.exe                      │
├─────────────────────────────────────────────────────────────┤
│  Rust (tao)       → 建立原生 Windows 視窗                    │
│  Rust (wry)       → 嵌入 WebView2                            │
│  Rust (tiny_http)→ 內建 HTTP Server (127.0.0.1:18374)       │
│                    → 提供 pyodide/ 靜態檔案                  │
│                    → 設定必要的 CORS Headers                 │
├─────────────────────────────────────────────────────────────┤
│                      WebView2                                │
│    └── console.html + Pyodide WASM                          │
│          → 執行 Python 3.12 程式碼                           │
└─────────────────────────────────────────────────────────────┘
```

### 為何需要內建 HTTP Server？

WebView2 的 `file://` 協定無法設定 `Cross-Origin-Opener-Policy` 等必要 header，而 Pyodide 的 SharedArrayBuffer 需要這些 header 才能運作。內建 tiny_http 解決此問題，且對效能無影響（全在本機 127.0.0.1）。

---

## 專案 Build 說明

### 前置需求

- **Rust 開發環境**：請至 [rustup.rs](https://rustup.rs/) 安裝
- **Windows 10/11 作業系統**
- **WebView2 執行環境**（Windows 11 內建，Windows 10 可自動下載）

### 建置步驟

#### 步驟一：編譯 exe（只需執行一次）

```cmd
rustup default stable-x86_64-pc-windows-msvc
cargo build --release
```

編譯完成後，產物位於：`target\release\pyodide-desktop.exe`

#### 步驟二：下載 Pyodide Runtime（只需執行一次，需要網路）

```cmd
scripts\download_pyodide.bat
```

此腳本會自動下載約 **17 MB** 的必要檔案，包括：
- Python WASM 核心（約 10 MB）
- Python 標準函式庫（約 3 MB）
- 科學計算套件：numpy、matplotlib、scipy、pandas、scikit-learn、pillow、sympy

#### 步驟三：佈署目錄結構

將編譯產出的 exe 與下載的 pyodide 資料夾放在**同一個目錄**中：

```
任意資料夾\
├── pyodide-desktop.exe    ← 編譯產物
└── pyodide\
    ├── console.html
    ├── pyodide.js
    ├── pyodide.asm.js
    ├── pyodide.asm.wasm    ← Python WASM 核心
    ├── python_stdlib.zip   ← Python 標準函式庫
    ├── pyodide-lock.json
    ├── pyodide.mjs
    ├── numpy-*.whl
    ├── matplotlib-*.whl
    └── ...（其他套件）
```

#### 步驟四：執行

直接雙擊 `pyodide-desktop.exe`，**從此刻起即可完全離線運作**。

---

## 程式使用說明

### 功能特性

| 功能 | 說明 |
|------|------|
| 完全離線 | 無任何外部網路請求 |
| Python REPL | 完整 Python 3.12 標準函式庫 |
| 多行輸入 | `def`/`class`/`for` 等自動切換 `...` 模式，空行送出 |
| ↑↓ 歷史紀錄 | 最多 200 筆指令歷史 |
| stdout/stderr | 分色顯示（stdout 白色，stderr 紅色） |
| Ctrl+L | 清除 console |
| 免安裝 | 只依賴 Windows 系統 DLL + WebView2 |

### 內建套件

以下科學計算套件已預設安裝，可直接 import 使用：

- **numpy** - 數值計算
- **matplotlib** - 繪圖
- **scipy** - 科學計算
- **pandas** - 資料處理
- **scikit-learn** - 機器學習
- **pillow** - 影像處理
- **sympy** - 符號運算

### 離線安裝額外套件

若需要安裝其他 Python 套件（例如 flask、requests 等），請參考下方的「如何手動安裝離線套件」說明。

---

## 如何手動安裝離線套件

Pyodide Console Desktop 預設已內建常用科學計算套件。若需要安裝其他 Python 套件，可依照以下步驟離線安裝：

### 步驟一：查詢套件資訊

打開 `pyodide/pyodide-lock.json` 檔案，搜尋您要安裝的套件名稱。

**舉例**（flask）：
```json
"flask": {
  "name": "flask",
  "version": "3.0.0",
  "file_name": "flask-3.0.0-py3-none-any.whl",
  "depends": ["werkzeug", "jinja2", "click", "blinker", "itsdangerous"]
}
```

### 步驟二：下載 .whl 檔案

從以下網址下載（需網路連線）：
```
https://cdn.jsdelivr.net/pyodide/v0.27.3/full/<file_name>
```

### 步驟三：放置檔案

將下載的 `.whl` 檔案放入 `pyodide/` 目錄中。

### 步驟四：重啟並使用

重啟 `pyodide-desktop.exe`，執行以下 Python 程式碼即可使用：

```python
import micropip
await micropip.install("flask")
import flask
```

⚠️ **注意**：依賴套件也需安裝！例如 flask 依賴 werkzeug、jinja2、click、blinker、itsdangerous，這些也需要依序下載放入 `pyodide/` 目錄。

---

## License：雙重授權模式

本專案採用**雙重授權**模式，適用於不同使用場景：

### MIT 授權（個人與非商業用途）

```
MIT License

Copyright (c) 2024 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 商業授權（公司使用）

本軟體的 MIT 授權**僅適用於個人與非商業用途**。如需用於**商業用途**，您必須：

1. **聯繫作者**取得商業授權
2. **支付授權費用**
3. **簽署正式授權合約**

未經授權之商業使用將視為侵權行為。

#### 聯繫方式

- X：[@Yizai_Wu](https://x.com/Yizai_Wu)
- Threads：[@yizaiwu](https://www.threads.com/@yizaiwu)

---

## 常見問題

### Q1：為何需要 WebView2？

Pyodide 需要在瀏覽器環境中執行，而 WebView2 是 Windows 平台上效能最佳的嵌入式瀏覽器解決方案。Windows 11 內建 WebView2，Windows 10 使用者首次執行時會自動下載安裝。

### Q2：可以完全離線使用嗎？

是的。一旦完成建置並下載 Pyodide Runtime 後，即可完全離線運作，無需任何網路連線。

### Q3：如何確保公司使用是經過授權的？

您可以在軟體中加入授權驗證機制，例如檢查授權金鑰或連線至授權伺服器驗證。具體實作方式可聯繫作者討論。

### Q4：支援哪些 Python 套件？

Pyodide 支援絕大多數純 Python 套件，以及許多已編譯為 WASM 的科學計算套件。部分需要 C/C++ 擴充的套件可能無法使用。

### Q5：如何回報問題或提出功能建議？

請至 GitHub Issues 頁面提問：https://github.com/your-username/pyodide-desktop/issues

---

## 感謝

- [Pyodide](https://pyodide.org/) - 讓 Python 可以直接在瀏覽器中執行
- [Rust](https://www.rust-lang.org/) - 高效能且安全的程式語言
- [wry](https://github.com/tauri-apps/wry) / [tao](https://github.com/tauri-apps/tao) - 跨平台 GUI 框架
