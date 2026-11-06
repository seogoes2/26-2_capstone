"""리포트 화면 확인용 목업 서버 (표준 라이브러리만 사용, 설치 불필요).

앱이 호출하는 경로를 그대로 흉내 내서 하루/주간/월간 리포트에 샘플 데이터를 채워 줍니다.
실제 FastAPI 백엔드가 준비되면 이 서버 대신 그걸 켜면 됩니다.

    python3 tools/mock_server.py          # 시뮬레이터용: http://127.0.0.1:8000
    python3 tools/mock_server.py --lan    # 실제 iPhone용: 같은 Wi-Fi에서 접속 허용
    python3 tools/mock_server.py 8001     # 포트 변경
"""

import json
import random
import sys
from datetime import date, datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse


def day_record(d: date):
    """날짜마다 항상 같은 값이 나오도록 날짜를 시드로 사용. 미래 날짜는 기록 없음."""
    if d > date.today():
        return None
    rng = random.Random(d.toordinal())
    if rng.random() < 0.12:  # 가끔 착용 안 한 날
        return None
    return {
        "date": d.isoformat(),
        "wear_minutes": rng.randint(150, 520),
        "overflex_count": rng.randint(0, 14),
        "max_over_angle": rng.randint(46, 72),
        "joint_angle": rng.randint(20, 60),
        "hourly_overflex": [rng.randint(0, 3) for _ in range(24)],
    }


def parse_date(s):
    return date.fromisoformat(s)


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, body):
        data = json.dumps(body, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        url = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(url.query).items()}
        try:
            if url.path == "/metrics/daily":
                rec = day_record(parse_date(q["date"]))
                return self._send(200, rec) if rec else self._send(404, {"detail": "no record"})
            if url.path == "/metrics/days":
                start, end = parse_date(q["start"]), parse_date(q["end"])
                days, d = [], start
                while d <= end:
                    rec = day_record(d)
                    if rec:
                        days.append(rec)
                    d += timedelta(days=1)
                return self._send(200, {"days": days})
            if url.path == "/device/status":
                return self._send(200, {
                    "online": True,
                    "name": "GUPSIN_SENSOR",
                    "battery": 82,
                    "rssi": -58,
                    "today_records": 124,
                    "last_seen": datetime.now(timezone.utc).isoformat(),
                })
            if url.path == "/device/settings":
                return self._send(200, {"rom_limit": 45, "vibration_start_angle": 40, "vibration_seconds": 2})
            if url.path == "/docs":
                return self._send(200, {"mock": True, "paths": ["/metrics/daily", "/metrics/days", "/device/status", "/device/settings"]})
        except (KeyError, ValueError) as e:
            return self._send(422, {"detail": f"bad query: {e}"})
        self._send(404, {"detail": "not found"})

    def do_PUT(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else b"{}"
        self._send(200, json.loads(body or b"{}"))

    do_POST = do_PUT
    do_PATCH = do_PUT


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--lan"]
    lan = "--lan" in sys.argv[1:]
    port = int(args[0]) if args else 8000
    host = "0.0.0.0" if lan else "127.0.0.1"
    if lan:
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
        except OSError:
            ip = "<Mac의 Wi-Fi IP>"
        finally:
            s.close()
        print(f"Mock server (LAN): http://{ip}:{port}  (Ctrl+C로 종료)")
        print(f"  앱 실행: flutter run --dart-define=API_BASE_URL=http://{ip}:{port}")
    else:
        print(f"Mock server: http://127.0.0.1:{port}  (Ctrl+C로 종료)")
    ThreadingHTTPServer((host, port), Handler).serve_forever()
