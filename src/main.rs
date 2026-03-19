#![windows_subsystem = "windows"]

use std::path::PathBuf;
use std::sync::Arc;
use std::thread;
use tao::{
    event::{Event, WindowEvent},
    event_loop::{ControlFlow, EventLoop},
    window::WindowBuilder,
};
use wry::WebViewBuilder;

// ── 內建 HTTP Server（供應 pyodide/ 資料夾給 WebView）────────────────────────

fn start_file_server(pyodide_dir: Arc<PathBuf>, port: u16) {
    thread::spawn(move || {
        let addr = format!("127.0.0.1:{}", port);
        let server = tiny_http::Server::http(&addr)
            .unwrap_or_else(|e| panic!("Cannot bind to {}: {}", addr, e));

        for request in server.incoming_requests() {
            let url_path = request.url().to_owned();

            // 安全性：只允許在 pyodide_dir 內部的路徑，防止路徑穿越
            let rel = url_path.trim_start_matches('/');
            let rel = if rel.is_empty() { "index.html" } else { rel };

            // 阻擋 ".." 路徑穿越攻擊
            if rel.contains("..") {
                let _ = request.respond(
                    tiny_http::Response::empty(403)
                );
                continue;
            }

            let file_path = pyodide_dir.join(rel);

            match std::fs::read(&file_path) {
                Ok(data) => {
                    // 依副檔名推斷 MIME type
                    let mime = mime_guess::from_path(&file_path)
                        .first_or_octet_stream();
                    let mime_str = mime.as_ref();

                    // WASM 檔案必須用正確 MIME，否則瀏覽器拒絕執行
                    let content_type = if mime_str == "application/octet-stream"
                        && file_path.extension().map(|e| e == "wasm").unwrap_or(false)
                    {
                        "application/wasm".to_string()
                    } else {
                        mime_str.to_string()
                    };

                    let response = tiny_http::Response::from_data(data)
                        .with_header(
                            tiny_http::Header::from_bytes(
                                &b"Content-Type"[..],
                                content_type.as_bytes(),
                            )
                            .unwrap(),
                        )
                        // Pyodide WASM 需要這兩個 CORS header
                        .with_header(
                            tiny_http::Header::from_bytes(
                                &b"Cross-Origin-Opener-Policy"[..],
                                &b"same-origin"[..],
                            )
                            .unwrap(),
                        )
                        .with_header(
                            tiny_http::Header::from_bytes(
                                &b"Cross-Origin-Embedder-Policy"[..],
                                &b"require-corp"[..],
                            )
                            .unwrap(),
                        );

                    let _ = request.respond(response);
                }
                Err(_) => {
                    let _ = request.respond(tiny_http::Response::empty(404));
                }
            }
        }
    });
}

// ── 主程式 ───────────────────────────────────────────────────────────────────

fn main() -> wry::Result<()> {
    // 取得 exe 所在目錄，pyodide/ 資料夾必須與 exe 同層
    let exe_dir = std::env::current_exe()
        .expect("Cannot get exe path")
        .parent()
        .expect("Cannot get exe directory")
        .to_path_buf();

    let pyodide_dir = exe_dir.join("pyodide");

    // 如果 pyodide 目錄不存在，顯示錯誤提示頁面
    if !pyodide_dir.exists() {
        return show_error_window(format!(
            "找不到 Pyodide 資料夾：\n{}\n\n請依照 README 說明執行 download_pyodide.bat 下載 runtime。",
            pyodide_dir.display()
        ));
    }

    let pyodide_dir = Arc::new(pyodide_dir);

    // 啟動內建 HTTP server（port 18374，避免與常用 port 衝突）
    let port: u16 = 18374;
    start_file_server(Arc::clone(&pyodide_dir), port);

    // 短暫等待 server 就緒
    thread::sleep(std::time::Duration::from_millis(100));

    // 建立視窗
    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_title("Pyodide Console — Offline")
        .with_inner_size(tao::dpi::LogicalSize::new(1100u32, 750u32))
        .with_min_inner_size(tao::dpi::LogicalSize::new(700u32, 500u32))
        .build(&event_loop)
        .unwrap();

    // 指向本機 HTTP server
    let url = format!("http://127.0.0.1:{}/console.html", port);

    let _webview = WebViewBuilder::new()
        .with_url(&url)
        .build(&window)?;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;
        if let Event::WindowEvent {
            event: WindowEvent::CloseRequested,
            ..
        } = event
        {
            *control_flow = ControlFlow::Exit;
        }
    });
}

// ── pyodide 資料夾不存在時的錯誤視窗 ────────────────────────────────────────

fn show_error_window(msg: String) -> wry::Result<()> {
    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_title("Pyodide Console — 設定錯誤")
        .with_inner_size(tao::dpi::LogicalSize::new(600u32, 300u32))
        .with_resizable(false)
        .build(&event_loop)
        .unwrap();

    let html = format!(r#"<!DOCTYPE html><html><body style="
        background:#1e1e2e;color:#ff5555;font-family:monospace;
        display:flex;align-items:center;justify-content:center;
        height:100vh;margin:0;padding:20px;box-sizing:border-box;
        text-align:center;font-size:14px;line-height:1.8;white-space:pre-wrap;">
{}</body></html>"#, msg);

    let _webview = WebViewBuilder::new()
        .with_html(&html)
        .build(&window)?;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;
        if let Event::WindowEvent {
            event: WindowEvent::CloseRequested,
            ..
        } = event
        {
            *control_flow = ControlFlow::Exit;
        }
    });
}
