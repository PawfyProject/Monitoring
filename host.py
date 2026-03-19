from flask import Flask, request
import requests
from datetime import datetime, timedelta
import threading, time

app = Flask(__name__)

WEBHOOK = "https://discord.com/api/webhooks/1471107667190612121/vCxaTbWvTNftpvv3o-YmOBH4oJ9KfB36U2wwznOwNtZ2UjRYFNftIWtw-E6AQ36Vz50J"
WEBHOOK_MESSAGE_ID = None

# Config server auto detect (dari conf nanti bisa auto load)
servers = {
    "DONKAY": 0,
    "FERGU": 0,
    "DAWNY": 0,
    "PAWTEST": 0,
    "FERGI": 0,
    "DONKEY": 0,
    "FERGO": 0,
    "DIWNY": 0,
    "DEWNY": 0,
    "DOWNY": 0
}

# Track akun aktif
active_accounts = {}  # {account: {"server": server, "last_seen": datetime, "device": device_id}}

# Heartbeat timeout (detik)
HEARTBEAT_TIMEOUT = 15

# Kirim atau update embed
def send_embed():
    global WEBHOOK_MESSAGE_ID
    desc = ""
    for i, (name, count) in enumerate(servers.items(), start=1):
        desc += f"Server {i} ({name}) : {count} Active\n"
    desc += f"\nServer Stats Monitoring: Last Update {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"

    payload = {
        "username": "Roblox Monitoring",
        "embeds": [{"title": "Roblox Monitoring", "description": desc, "color": 65280}]
    }

    if WEBHOOK_MESSAGE_ID:
        # PATCH embed lama → tidak spam
        requests.patch(f"{WEBHOOK}/messages/{WEBHOOK_MESSAGE_ID}", json=payload)
    else:
        # POST pertama
        r = requests.post(WEBHOOK, json=payload)
        if r.ok:
            data = r.json()
            WEBHOOK_MESSAGE_ID = data.get("id")

# Endpoint update dari executor
@app.route('/update', methods=['POST'])
def update():
    data = request.json
    account = data.get("account")
    server = data.get("server")
    device_id = data.get("device", "unknown")
    status = data.get("status")
    now = datetime.now()

    if status == "active":
        old = active_accounts.get(account)
        if old:
            old_server = old["server"]
            if old_server != server:
                servers[old_server] -= 1
        if not old or old["server"] != server:
            servers[server] += 1
        active_accounts[account] = {"server": server, "last_seen": now, "device": device_id}

    elif status == "offline":
        old = active_accounts.get(account)
        if old:
            servers[old["server"]] -= 1
            del active_accounts[account]

    send_embed()
    return "OK"

# Background Heartbeat → auto OFFLINE
def heartbeat_checker():
    while True:
        now = datetime.now()
        to_remove = []
        for account, info in active_accounts.items():
            if (now - info["last_seen"]).total_seconds() > HEARTBEAT_TIMEOUT:
                servers[info["server"]] -= 1
                to_remove.append(account)
        for account in to_remove:
            del active_accounts[account]
        if to_remove:
            send_embed()
        time.sleep(5)

threading.Thread(target=heartbeat_checker, daemon=True).start()

app.run(host="0.0.0.0", port=5000)
