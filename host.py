import os
from flask import Flask, request
import requests
from datetime import datetime, timedelta
import threading, time

app = Flask(__name__)

# CONFIG
CONFIG_FILE = "/storage/emulated/0/Download/WinterHub/auto_rejoin.conf"
WEBHOOK = "https://discord.com/api/webhooks/1471107667190612121/vCxaTbWvTNftpvv3o-YmOBH4oJ9KfB36U2wwznOwNtZ2UjRYFNftIWtw-E6AQ36Vz50J"
WEBHOOK_MESSAGE_ID = None
HEARTBEAT_TIMEOUT = 120  # 2 menit

# LOAD CONFIG
servers = {}
if os.path.exists(CONFIG_FILE):
    with open(CONFIG_FILE) as f:
        lines = f.readlines()
    shared_links_count = 0
    config_dict = {}
    for line in lines:
        if "=" in line:
            k,v = line.strip().split("=",1)
            config_dict[k] = v
    shared_links_count = int(config_dict.get("shared_links_count","0"))
    for i in range(1, shared_links_count+1):
        name = config_dict.get(f"shared_link_{i}_name")
        if name:
            servers[name] = 0
else:
    print("Config file not found!")

active_accounts = {}  # account_name -> {"server":server,"last_seen":datetime,"device":device_id}

# SEND OR PATCH EMBED
def send_embed():
    global WEBHOOK_MESSAGE_ID
    desc = ""
    for i,(name,count) in enumerate(servers.items(),1):
        desc += f"Server {i} ({name}) : {count} Active\n"
    desc += f"\nServer Stats Monitoring: Last Update {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    payload = {"username":"Roblox Monitoring","embeds":[{"title":"Roblox Monitoring","description":desc,"color":65280}]}

    if WEBHOOK_MESSAGE_ID:
        try:
            requests.patch(f"{WEBHOOK}/messages/{WEBHOOK_MESSAGE_ID}", json=payload)
        except:
            requests.post(WEBHOOK, json=payload)
    else:
        r = requests.post(WEBHOOK,json=payload)
        if r.ok:
            data = r.json()
            WEBHOOK_MESSAGE_ID = data.get("id")

# UPDATE ENDPOINT
@app.route('/update',methods=['POST'])
def update():
    data = request.json
    account = data.get("account")
    server = data.get("server")
    device_id = data.get("device","unknown")
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
        active_accounts[account] = {"server":server,"last_seen":now,"device":device_id}

    elif status == "offline":
        old = active_accounts.get(account)
        if old:
            servers[old["server"]] -= 1
            del active_accounts[account]

    send_embed()
    return "OK"

# HEARTBEAT CHECKER
def heartbeat_checker():
    while True:
        now = datetime.now()
        to_remove = []
        for account,info in active_accounts.items():
            if (now - info["last_seen"]).total_seconds() > HEARTBEAT_TIMEOUT:
                servers[info["server"]] -= 1
                to_remove.append(account)
        for account in to_remove:
            del active_accounts[account]
        if to_remove:
            send_embed()
        time.sleep(5)

threading.Thread(target=heartbeat_checker,daemon=True).start()
app.run(host="0.0.0.0",port=5000)
