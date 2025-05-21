#!/usr/bin/env python3
# KZ 2025.05.21.
import socket, time, sys
from datetime import datetime

# ANSI color helpers

def rgb_hex(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def color(text, hexcode):
    r, g, b = rgb_hex(hexcode)
    return f"\033[38;2;{r};{g};{b}m{text}\033[0m"

def move_up(n=1):
    return f"\033[{n}F"

def clear_line():
    return "\033[K"

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
    seen = set()
    printed_warning = False

    # print header
    print(color("Discovering Barix devices (CTRL-C to stop)\n", INFO))
    header = f"{'Device IP':15s}  {'MAC Address':17s}"
    print(color(header, INFO))
    print(color("-" * len(header), INFO))

    try:
        while True:
            any_found = False
            # clear previous warning if we will print devices
            if printed_warning:
                sys.stdout.write(move_up(1) + clear_line())
                printed_warning = False

            # discovery cycle
            for data in discover_once():
                if len(data) < 15:
                    continue
                mac = data[5:11]
                ip_bytes = data[11:15]
                if not mac.startswith(BARIX_PREFIX) or mac in seen:
                    continue
                seen.add(mac)
                payload_ip = ".".join(str(b) for b in ip_bytes)
                print(color(f"{payload_ip:15s}  {fmt_mac(mac):17s}", SUCCESS))
                any_found = True

            if not any_found:
                ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                msg = color(f"{ts} No devices found in this cycle.", WARN)
                print(msg)
                printed_warning = True

            time.sleep(INTERVAL)
    except KeyboardInterrupt:
        print(color(f"\nDone — found {len(seen)} device(s).", SUCCESS))
        sys.exit(0)
    except Exception as e:
        print(color(f"Error: {e}", ERROR), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
