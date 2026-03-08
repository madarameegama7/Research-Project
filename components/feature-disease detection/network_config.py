#!/usr/bin/env python3
"""
Quick Network Diagnostics
Find your computer's IP for mobile app configuration
"""

import socket
import subprocess
import sys

def get_local_ips():
    """Get all local IP addresses"""
    ips = []

    try:
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        if local_ip and not local_ip.startswith('127'):
            ips.append(('Default', local_ip))
    except:
        pass

    # Try to get more detailed info
    try:
        if sys.platform == 'win32':
            # Windows
            result = subprocess.run(['ipconfig'], capture_output=True, text=True)
            lines = result.stdout.split('\n')

            for line in lines:
                if 'IPv4 Address' in line:
                    parts = line.split(':')
                    if len(parts) > 1:
                        ip = parts[1].strip()
                        if ip and not ip.startswith('127'):
                            ips.append(('IPv4', ip))
        else:
            # Mac/Linux
            result = subprocess.run(['ifconfig'], capture_output=True, text=True)
            lines = result.stdout.split('\n')

            for line in lines:
                if 'inet ' in line and '127.0.0.1' not in line:
                    parts = line.strip().split()
                    if len(parts) > 1:
                        ip = parts[1]
                        ips.append(('Interface', ip))
    except:
        pass

    return ips

def main():
    print("\n" + "="*60)
    print("NETWORK CONFIGURATION")
    print("="*60)

    print("\n📡 Your Computer's IP Addresses:")
    print("-" * 60)

    ips = get_local_ips()

    if ips:
        for label, ip in ips:
            print(f"  {label:15} {ip}")
    else:
        print("  Could not detect IP addresses")

    print("\n" + "-" * 60)
    print("\n📱 Mobile App Configuration:")
    print("-" * 60)

    if ips:
        first_ip = ips[0][1]
        print(f"\n  For physical phone on your WiFi network:")
        print(f"    Change in: disease_detection_service.dart")
        print(f"    Line 12, change to:")
        print(f"    static const String baseUrl = 'http://{first_ip}:5001/api';")

        print(f"\n  For Android Emulator:")
        print(f"    static const String baseUrl = 'http://10.0.2.2:5001/api';")
    else:
        print("  Could not determine IP - run: ipconfig (Windows) or ifconfig (Mac/Linux)")

    print("\n" + "="*60)
    print("\n✅ Once configured, run: START_SERVER.bat")
    print("   Then use your mobile app")
    print("\n" + "="*60 + "\n")

if __name__ == '__main__':
    main()

