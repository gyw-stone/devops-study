import os
import json
import gzip
from collections import Counter
from datetime import datetime, timezone, timedelta
from collections import Counter

LOG_DIR = "/Users/stone/Desktop/waflogs"   # 你下载的日志目录
#LOG_DIR = "/Users/stone/Desktop/test"
START_TIME = "2025-12-01 10:00:00"
END_TIME = "2025-12-01 10:20:00"

bj = timezone(timedelta(hours=8))
start_ts = int(datetime.strptime(START_TIME, "%Y-%m-%d %H:%M:%S").replace(tzinfo=bj).timestamp() * 1000)
end_ts = int(datetime.strptime(END_TIME, "%Y-%m-%d %H:%M:%S").replace(tzinfo=bj).timestamp() * 1000)

def load_log_file(filepath):
    """支持 .gz 和普通 .log 文件"""
    if filepath.endswith(".gz"):
        with gzip.open(filepath, "rt", encoding="utf-8") as f:
            for line in f:
                yield line
    else:
        with open(filepath, "r", encoding="utf-8") as f:
            for line in f:
                yield line


def analyze_logs():
    uri_counter = Counter()
    ip_counter = Counter()
    ua_counter = Counter()
    geo_counter = Counter()
    httpMethod_counter = Counter()
 
    matched_count = 0
    files = [os.path.join(LOG_DIR, f) for f in os.listdir(LOG_DIR) if f.endswith(("gz", "log"))]

    print(f"▶ Found {len(files)} log files to analyze.\n")
    print(f" start timestamp is {start_ts}")
    print(f" end timestamp is {end_ts}")
    for file in files:
        print(f"📌 Processing: {os.path.basename(file)}")
        for line in load_log_file(file):
            try:
                entry = json.loads(line.strip())
                ts = entry.get("timestamp")

                # 没有 timestamp 的跳过
                if not isinstance(ts, (int, float)):
                    continue

                # 按范围过滤
                if not (start_ts <= ts <= end_ts):
                    continue

                matched_count += 1
                
                entry = json.loads(line.strip())
                req = entry.get("httpRequest", {})

                uri = req.get("uri", "")
                ip = req.get("clientIp", "")
                httpMethod = req.get("httpMethod", "")
                ua = req.get("user-agent", [{}])[0].get("value", "")
                geo = req.get("country", "")

                if uri: uri_counter[uri] += 1
                if ip: ip_counter[ip] += 1
                if ua: ua_counter[ua] += 1
                if geo: geo_counter[geo] += 1
                if httpMethod: httpMethod_counter[str(httpMethod)] += 1

            except Exception:
                continue

    print("\n=== 🔥 Top 10 Requested URIs ===")
    for uri, count in uri_counter.most_common(10):
        print(f"{uri}: {count}")

    print("\n=== 👥 Top 10 Client IPs ===")
    for ip, count in ip_counter.most_common(10):
        print(f"{ip}: {count}")

    print("\n=== 📡 Top 10 User-Agent ===")
    for ua, count in ua_counter.most_common(10):
        print(f"{ua[:80]}...: {count}")

    print("\n=== 📡 Top 10 Country ===")
    for geo, count in geo_counter.most_common(10):
        print(f"{geo}: {count}")

    print("\n=== 📊 HTTP Status Code Counts ===")
    for code, count in httpMethod_counter.most_common():
        print(f"{code}: {count}")


if __name__ == "__main__":
    analyze_logs()

