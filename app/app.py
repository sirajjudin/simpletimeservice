from flask import Flask, request, jsonify
from datetime import datetime
from zoneinfo import ZoneInfo   # <-- built-in timezone library (Python 3.9+)

app = Flask(__name__)

def get_client_ip():
    xff = request.headers.get("X-Forwarded-For")
    if xff:
        return xff.split(",")[0].strip()
    return request.remote_addr or "unknown"

@app.route("/")
def home():
    # India timezone (Asia/Kolkata)
    ist_time = datetime.now(ZoneInfo("Asia/Kolkata")).isoformat()

    return jsonify({
        "timestamp": ist_time,
        "ip": get_client_ip()
    })

@app.route("/health")
def health():
    return "ok", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
