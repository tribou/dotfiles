#!/usr/bin/env python3
"""Minimal HTTP server to receive browser-open requests from remote SSH sessions.

Runs on localhost:15679. When it receives /open?url=..., it opens the URL in the
local default browser.

Usage:
    dotfiles_local_browser_helper.sh [PORT]

RAM usage: ~5-8 MB idle (Python stdlib only, no external dependencies).
"""
import http.server
import socketserver
import sys
import urllib.parse
import webbrowser

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 15679


class SilentHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/open?'):
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            if 'url' in params:
                webbrowser.open(params['url'][0], new=2)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'ok\n')
                return
        self.send_response(404)
        self.end_headers()
        self.wfile.write(b'not found\n')

    def log_message(self, format, *args):
        pass  # Suppress all request logging


if __name__ == '__main__':
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", PORT), SilentHandler) as httpd:
        httpd.serve_forever()
