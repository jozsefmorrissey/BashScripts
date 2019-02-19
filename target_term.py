#!/usr/bin/env python3

import subprocess
import os
import sys
import time
import getpass
#--- set your terminal below
application = "gnome-terminal"
#---

option = sys.argv[1]
data = os.environ["HOME"]+"/.opsc/target_term/.term_list"
pidDir = os.environ["HOME"]+"/.opsc/target_term/pids/"

def current_windows():
    w_list = subprocess.check_output(["wmctrl", "-lp"]).decode("utf-8")
    w_lines = [l for l in w_list.splitlines()]
    try:
        pid = subprocess.check_output(["pgrep", application]).decode("utf-8").strip()
        return [l for l in w_lines if str(pid) in l]
    except subprocess.CalledProcessError:
        return []

def arr_windows(n):
    w_count1 = current_windows()
    for requested in range(n):
        subprocess.Popen([application])
    called = []
    while len(called) < n:
        time.sleep(1)
        w_count2 = current_windows()
        add = [w for w in w_count2 if not w in w_count1]
        [called.append(w.split()[0]) for w in add if not w in called]
        w_count1 = w_count2
    return called

def run_intterm(w, command):
    subprocess.call(["xdotool", "windowfocus", "--sync", w])
    subprocess.call(["xdotool", "type", command+"\n"])


def killProcess(id):
    try:
        pidFile = pidDir + str(id)
        pid = open(pidFile).read().strip()
        print("Killing Process: " +  pid)
        w_count2 = arr_windows(1)
        t_term = w_count2[0]
        run_intterm(t_term, "kill -9 " + pid)
        run_intterm(t_term, "rm " + pidFile)
        run_intterm(t_term, "exit")
        time.sleep(1)
    except:
        print("No Process to Kill.")

def addWindows():
    n = int(sys.argv[2])
    new = arr_windows(n)
    index = 0
    ct = len(open(data).read().splitlines())
    for w in new:
        index += 1
        open(data, "a").write(w+"\n")
        id = str(ct + index)
        print("Process " + id + " Started")
        run_intterm(w, "echo $$ >" + pidDir + id)

# ----------------------------- Command functions ------------------------------
def pid():
    procId = open(data).read().splitlines()[int(sys.argv[2])-1];
    try:
        print("procId: " + procId)
        print(procId.pid)
        proc = subprocess.Popen([procId], shell=True);
        print("PID: " + proc.pid)
    except:
        proc.kill()

def add():
    addWindows()

def set():
    killAll()
    open(data, "w").write("")
    addWindows()

def run():
    t_term = open(data).read().splitlines()[int(sys.argv[2])-1]
    command = (" ").join(sys.argv[3:])
    run_intterm(t_term, command)

def kill():
    killProcess(sys.argv[2])

def killAll():
    files=os.listdir(pidDir)
    for file in files:
        killProcess(file)

def install():
    password = getpass.getpass("Admin Password: ");
    w_count2 = arr_windows(1)
    t_term = w_count2[0]
    run_intterm(t_term, "sudo apt-get install wmctrl xdotool")
    run_intterm(t_term, password)
    cmd="python " + os.path.abspath(__file__) + ' "$@"';
    run_intterm(t_term, "echo -e '#!/usr/bin/env bash\n" + cmd + "' | sudo tee /bin/target_term")
    run_intterm(t_term, "mkdir -p " + pidDir)
    time.sleep(10)
    run_intterm(t_term, "exit")

def count():
    print(len(open(data).read().splitlines()))

eval(option + "()")
