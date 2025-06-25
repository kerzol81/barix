#!/usr/bin/env python3
# KZ 2025.05.21. Enhanced with numbered list, SSH credential prompts, host key cleanup, and pexpect fallback
import socket
import time
import sys
import subprocess
import getpass
from datetime import datetime
from collections import OrderedDict

# Try to import pexpect for automated password entry
try:
    import pexpect
    HAVE_PEXPECT = True
except ImportError:
    HAVE_PEXPECT = False

# ANSI colors

def rgb_hex(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def color(text, hexcode):
    r, g, b = rgb_hex(hexcode)
    return f"\033[38;2;{r};{g};{b}m{text}\033[0m"

def clear_screen():
    sys.stdout.write("\033[2J\033[H")
    sys.stdout.flush()

# BOOTSTRAP colors
INFO    = "#0d6efd"  # blue
SUCCESS = "#28a745"  # green
ERROR   = "#dc3545"  # red
WARN    = "#ffc107"  # yellow

BCAST_ADDR        = "255.255.255.255"
PORT              = 30718
TIMEOUT           = 2.0   # seconds to listen per cycle
INTERVAL          = 5.0   # seconds between broadcasts
BARIX_PREFIX      = bytes.fromhex("0008E1")
DISCOVERY_PAYLOAD = bytes.fromhex("81 88 53 81 01")


def send_discovery():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    s.bind(("", PORT))
    s.sendto(DISCOVERY_PAYLOAD, (BCAST_ADDR, PORT))
    s.close()


def discover_once():
    send_discovery()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(TIMEOUT)
    sock.bind(("", PORT))

    start = time.time()
    replies = []
    while True:
        rem = TIMEOUT - (time.time() - start)
        if rem <= 0:
            break
        sock.settimeout(rem)
        try:
            data, addr = sock.recvfrom(2048)
        except socket.timeout:
            break
        replies.append(data)
    sock.close()
    return replies


def fmt_mac(b):
    return ":".join(f"{x:02X}" for x in b)


def main():
    devices = OrderedDict()  # mac -> ip

    try:
        while True:
            clear_screen()
            print(color("Discovering Barix devices (CTRL-C to stop)", INFO))
            header = f"{'#':>2s}  {'Device IP':15s}  {'MAC Address':17s}"
            print(color(header, INFO))
            print(color("-" * len(header), INFO))

            # discovery cycle
            for data in discover_once():
                if len(data) < 15:
                    continue
                mac = data[5:11]
                ip_bytes = data[11:15]
                if not mac.startswith(BARIX_PREFIX):
                    continue
                payload_ip = ".".join(str(b) for b in ip_bytes)
                if mac not in devices:
                    devices[mac] = payload_ip

            # print devices
            if devices:
                for idx, (mac, ip) in enumerate(devices.items(), start=1):
                    print(color(f"{idx:2d}) {ip:15s}  {fmt_mac(mac):17s}", SUCCESS))
            else:
                ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                print(color(f"{ts} No devices found yet.", WARN))

            # prompt for SSH
            if devices:
                choice = input(color("Select device number to SSH (or press Enter to refresh): ", INFO)).strip()
                if choice.isdigit():
                    num = int(choice)
                    if 1 <= num <= len(devices):
                        mac = list(devices.keys())[num-1]
                        ip = devices[mac]
                        username = input(color("SSH username: ", INFO)).strip()
                        # remove old host key
                        subprocess.call(["ssh-keygen", "-R", ip],
                                        stdout=subprocess.DEVNULL,
                                        stderr=subprocess.DEVNULL)
                        if HAVE_PEXPECT:
                            password = getpass.getpass(color("SSH password: ", INFO))
                            print(color(f"Connecting via SSH to {username}@{ip}...", INFO))
                            try:
                                child = pexpect.spawn(f"ssh {username}@{ip}")
                                i = child.expect([r"[Pp]assword:", pexpect.EOF, pexpect.TIMEOUT], timeout=10)
                                if i == 0:
                                    child.sendline(password)
                                child.interact()
                            except Exception as e:
                                print(color(f"SSH error: {e}", ERROR), file=sys.stderr)
                        else:
                            subprocess.call(["ssh", f"{username}@{ip}"])
            # wait before next cycle
            time.sleep(INTERVAL)

    except KeyboardInterrupt:
        print(color(f"\nDone — found {len(devices)} device(s).", SUCCESS))
        sys.exit(0)
    except Exception as e:
        print(color(f"Error: {e}", ERROR), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
