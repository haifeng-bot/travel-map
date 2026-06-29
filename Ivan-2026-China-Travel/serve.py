#!/usr/bin/env python3
"""
serve.py — 在本地起一个静态文件服务，再用 cloudflared 建一条 quick tunnel
把整个 travel_map/Ivan-2026-China-Travel/ 目录暴露到 trycloudflare.com

用法:
  python3 serve.py            # 启动（默认 8000 端口）
  python3 serve.py 9000       # 自定义端口
  Ctrl+C 退出

启动后会打印形如 https://xxxx.trycloudflare.com 的公网链接，
map.html 是中文版，map_en.html 是英文版。
"""
import http.server
import socketserver
import subprocess
import sys
import os
import re
import signal
import time
import threading

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
HERE = os.path.dirname(os.path.abspath(__file__))
CLOUDFLARED = "/usr/local/bin/cloudflared"

class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # 防 Leaflet/OSM tile 在某些网络下被 CORS 拦掉
        self.send_header("Cache-Control", "no-store")
        super().end_headers()
    def log_message(self, fmt, *args):
        # 简化日志，只打印非 200
        if not (len(args) >= 1 and str(args[0]).startswith("200")):
            super().log_message(fmt, *args)

def start_http():
    os.chdir(HERE)
    with socketserver.TCPServer(("", PORT), QuietHandler) as httpd:
        print(f"[http]  serving {HERE} on http://127.0.0.1:{PORT}", flush=True)
        httpd.serve_forever()

def start_tunnel():
    proc = subprocess.Popen(
        [CLOUDFLARED, "tunnel", "--url", f"http://127.0.0.1:{PORT}", "--no-autoupdate"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1
    )
    url = None
    for line in proc.stdout:
        line = line.rstrip()
        print(f"[cfd]  {line}", flush=True)
        if url is None:
            m = re.search(r"(https://[a-z0-9-]+\.trycloudflare\.com)", line)
            if m:
                url = m.group(1)
                print(f"\n[✓]  公网访问地址: {url}", flush=True)
                print(f"     中文版: {url}/map.html", flush=True)
                print(f"     英文版: {url}/map_en.html\n", flush=True)
    return proc

if __name__ == "__main__":
    # 后台跑 HTTP
    t = threading.Thread(target=start_http, daemon=True)
    t.start()
    time.sleep(0.5)

    print(f"[boot] cloudflared quick tunnel starting...", flush=True)
    proc = start_tunnel()

    def shutdown(*_):
        print("\n[exit] shutting down...", flush=True)
        proc.terminate()
        sys.exit(0)
    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    proc.wait()
