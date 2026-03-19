#!/usr/bin/env python3
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
"""
Check GDScript files for diagnostics using Godot's built-in LSP server.

Usage:
    python tools/check-gdscript-lsp-diagnostics.py [--godot GODOT] [--port PORT] [file1.gd ...]

If no files are given, all .gd files under the current directory are checked,
except for a hardcoded list of exceptions.
"""

import argparse
import json
import os
import pathlib
import select
import signal
import socket
import subprocess
import sys
import time
from contextlib import contextmanager

LSP_INITIALIZE_TIMEOUT = 10  # seconds to wait for Godot LSP to accept connections
DIAGNOSTIC_TIMEOUT = 5  # seconds to wait for diagnostics after last message
EXCLUDED = [
    "script_templates",
    "scenes/quests/story_quests",
]


@contextmanager
def godot_lsp(executable: str, port: int, project_root: pathlib.Path):
    """Launch Godot as a headless LSP server and terminate it on exit."""
    cmd = [
        executable,
        "--headless",
        "--editor",
        "--lsp-port",
        str(port),
        "--path",
        str(project_root),
    ]
    print(f"Launching: {' '.join(cmd)}", file=sys.stderr)
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        yield proc
    finally:
        proc.send_signal(signal.SIGTERM)
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


def path_to_uri(path: pathlib.Path) -> str:
    return path.absolute().as_uri()


class LspClient:
    def __init__(self, sock: socket.socket):
        self._sock = sock
        self._msg_id = 0

    def __enter__(self):
        return self

    def __exit__(self, *_):
        try:
            self._sock.close()
        except OSError:
            pass

    def _send(self, msg: dict) -> None:
        body = json.dumps(msg, separators=(",", ":"))
        frame = f"Content-Length: {len(body)}\r\n\r\n{body}".encode()
        self._sock.sendall(frame)

    def request(self, method: str, params: dict) -> int:
        self._msg_id += 1
        self._send(
            {"jsonrpc": "2.0", "id": self._msg_id, "method": method, "params": params}
        )
        return self._msg_id

    def notify(self, method: str, params: dict) -> None:
        self._send({"jsonrpc": "2.0", "method": method, "params": params})

    def recv(self) -> dict | None:
        """Read one LSP message. Returns None on EOF."""
        raw = b""
        while b"\r\n\r\n" not in raw:
            chunk = self._sock.recv(1)
            if not chunk:
                return None
            raw += chunk

        header, _ = raw.split(b"\r\n\r\n", 1)
        content_length = None
        for line in header.split(b"\r\n"):
            if line.lower().startswith(b"content-length:"):
                content_length = int(line.split(b":", 1)[1].strip())
        if content_length is None:
            raise ValueError(f"No Content-Length in LSP header: {header!r}")

        body = b""
        while len(body) < content_length:
            chunk = self._sock.recv(content_length - len(body))
            if not chunk:
                return None
            body += chunk

        return json.loads(body)

    def recv_until_idle(self, timeout: float) -> list[dict]:
        """Collect messages until no new message arrives within timeout seconds."""
        messages = []
        last_message_time = time.monotonic()
        while True:
            remaining = timeout - (time.monotonic() - last_message_time)
            if remaining <= 0:
                break
            ready = select.select([self._sock], [], [], remaining)
            if not ready[0]:
                break
            msg = self.recv()
            if msg is None:
                break
            last_message_time = time.monotonic()
            messages.append(msg)
        return messages


def connect_with_retry(port: int, deadline: float, proc=None) -> socket.socket:
    while True:
        try:
            return socket.create_connection(("127.0.0.1", port), timeout=1)
        except (ConnectionRefusedError, TimeoutError, OSError):
            if time.monotonic() > deadline:
                raise TimeoutError(f"Timed out waiting for Godot LSP on port {port}.")
            if proc is not None and proc.poll() is not None:
                raise RuntimeError(f"Godot exited early (code {proc.returncode}).")
            time.sleep(0.2)


def run(
    port: int, project_root: pathlib.Path, gd_files: list[pathlib.Path], proc=None
) -> dict[str, list]:
    deadline = time.monotonic() + LSP_INITIALIZE_TIMEOUT
    sock = connect_with_retry(port, deadline, proc)
    sock.setblocking(False)

    with LspClient(sock) as lsp:
        # Handshake
        init_id = lsp.request(
            "initialize",
            {
                "processId": os.getpid(),
                "rootUri": path_to_uri(project_root),
                "capabilities": {
                    "textDocument": {
                        "publishDiagnostics": {"relatedInformation": False}
                    }
                },
            },
        )

        # Wait for initialize response
        while True:
            ready = select.select([sock], [], [], 10)
            if not ready[0]:
                raise TimeoutError("No response to initialize request.")
            msg = lsp.recv()
            if msg is None:
                raise RuntimeError("LSP server closed connection.")
            if msg.get("id") == init_id:
                break

        lsp.notify("initialized", {})

        for path in gd_files:
            lsp.notify(
                "textDocument/didOpen",
                {
                    "textDocument": {
                        "uri": path_to_uri(path),
                        "languageId": "gdscript",
                        "version": 1,
                        "text": path.read_text(encoding="utf-8"),
                    }
                },
            )

        diagnostics: dict[str, list] = {}
        for msg in lsp.recv_until_idle(DIAGNOSTIC_TIMEOUT):
            if msg.get("method") == "textDocument/publishDiagnostics":
                params = msg.get("params", {})
                uri = params.get("uri", "")
                diags = params.get("diagnostics", [])
                if diags:
                    diagnostics[uri] = diags
                elif uri in diagnostics:
                    del diagnostics[uri]

        for path in gd_files:
            lsp.notify(
                "textDocument/didClose", {"textDocument": {"uri": path_to_uri(path)}}
            )

    return diagnostics


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--godot", default="godot", help="Godot executable (default: godot)"
    )
    parser.add_argument(
        "--port", type=int, default=6005, help="LSP port (default: 6005)"
    )
    parser.add_argument(
        "--no-launch",
        action="store_true",
        help="Don't launch Godot; connect to an already-running LSP server",
    )
    parser.add_argument("files", nargs="*", help=".gd files to check")
    args = parser.parse_args()

    project_root = pathlib.Path(".").absolute()

    if args.files:
        gd_files = [pathlib.Path(f).absolute() for f in args.files]
    else:
        gd_files = sorted(
            p
            for p in project_root.rglob("*.gd")
            if not any(p.is_relative_to(project_root / e) for e in EXCLUDED)
        )

    if not gd_files:
        print("No .gd files found.", file=sys.stderr)
        return 0

    try:
        if args.no_launch:
            diagnostics = run(args.port, project_root, gd_files)
        else:
            with godot_lsp(args.godot, args.port, project_root) as proc:
                diagnostics = run(args.port, project_root, gd_files, proc)
    except (TimeoutError, RuntimeError) as e:
        print(str(e), file=sys.stderr)
        return 1

    if not diagnostics:
        print(f"No diagnostics in {len(gd_files)} files.")
        return 0

    # Severity 1=error, 2=warning, 3=info, 4=hint
    severity_names = {1: "error", 2: "warning", 3: "info", 4: "hint"}
    # GitHub Actions workflow command levels (info/hint fall back to "notice")
    gha_levels = {1: "error", 2: "warning", 3: "notice", 4: "notice"}
    in_gha = "GITHUB_ACTIONS" in os.environ
    exit_code = 0

    for uri, diags in sorted(diagnostics.items()):
        try:
            rel = pathlib.Path(uri.removeprefix("file://")).relative_to(project_root)
        except ValueError:
            rel = uri
        for d in diags:
            severity = d.get("severity", 1)
            name = severity_names.get(severity, "diagnostic")
            start = d.get("range", {}).get("start", {})
            line = start.get("line", 0) + 1
            col = start.get("character", 0) + 1
            message = d.get("message", "")
            if in_gha:
                level = gha_levels.get(severity, "notice")
                print(f"::{level} file={rel},line={line},col={col}::{message}")
            else:
                print(f"{rel}:{line}:{col}: {name}: {message}")
            if severity <= 2:  # error or warning
                exit_code = 1

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
