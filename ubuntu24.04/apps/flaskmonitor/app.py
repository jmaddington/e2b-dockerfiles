from flask import Flask, render_template, jsonify
import psutil
import os
import socket

app = Flask(__name__)

def get_system_stats():
    return {
        'cpu_percent': psutil.cpu_percent(),
        'memory_percent': psutil.virtual_memory().percent,
        'disk_percent': psutil.disk_usage('/').percent
    }

def get_log_tail(n=10):
    log_dir = '/var/log'
    result = {}
    try:
        for filename in os.listdir(log_dir):
            file_path = os.path.join(log_dir, filename)
            if os.path.isfile(file_path):
                try:
                    with open(file_path, 'r') as f:
                        lines = f.readlines()
                        result[filename] = lines[-n:]
                except Exception as e:
                    result[filename] = [f"Error reading {filename}: {e}"]
    except Exception as e:
        result["error"] = [f"Error reading log directory: {e}"]
    return result

def get_top_cpu_processes(n=20):
    processes = []
    procs = {p.pid: p for p in psutil.process_iter(['name', 'memory_percent'])}
    psutil.cpu_percent(interval=0.1)
    for pid in procs:
        try:
            p = procs[pid]
            cpu_percent = p.cpu_percent()
            processes.append({
                'pid': pid,
                'name': p.info['name'],
                'cpu_percent': cpu_percent,
                'memory_percent': p.info['memory_percent']
            })
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    
    processes.sort(key=lambda x: x['cpu_percent'], reverse=True)
    return processes[:n]

def get_listening_ports():
    """
    Return a list of dictionaries with information about listening TCP ports.
    Each entry: { 'laddr': 'host:port', 'pid': pid_or_None, 'process': process_name_or_None }
    """
    listening = []
    conns = psutil.net_connections(kind='inet')
    # Filter for TCP listening ports
    for c in conns:
        if c.status == psutil.CONN_LISTEN:
            laddr = f"{c.laddr.ip}:{c.laddr.port}" if c.laddr else None
            pid = c.pid
            pname = None
            if pid:
                try:
                    p = psutil.Process(pid)
                    pname = p.name()
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
            listening.append({
                'laddr': laddr,
                'pid': pid,
                'process': pname
            })
    return listening

@app.route('/')
def index():
    system_stats = get_system_stats()
    log_tail = get_log_tail()
    top_cpu = get_top_cpu_processes()
    return render_template('index.html',
                           system_stats=system_stats,
                           log_tail=log_tail,
                           top_cpu=top_cpu)

@app.route('/api/stats')
def get_stats():
    return jsonify({
        'system': get_system_stats(),
        'log_tail': get_log_tail()
    })

@app.route('/api/top_cpu') 
def get_top_cpu():
    return jsonify(get_top_cpu_processes())

@app.route('/api/listening_ports')
def api_listening_ports():
    return jsonify(get_listening_ports())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=4999)
