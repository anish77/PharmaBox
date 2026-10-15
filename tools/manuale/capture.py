"""Capture original Android screenshots for the PharmaBox manual (ADB required).

Examples: python tools/manuale/capture.py shot 01-liste
          python tools/manuale/capture.py ui
          python tools/manuale/capture.py tap 220 140
Coordinates use a 448 x 997 reference viewport and scale to the device.
Set ANDROID_SERIAL to select an emulator (default: emulator-5556).
"""
import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ADB = Path(os.environ['LOCALAPPDATA']) / 'Android/sdk/platform-tools/adb.exe'
SERIAL = os.environ.get('ANDROID_SERIAL', 'emulator-5556')


def adb(*args):
    return subprocess.check_output([str(ADB), '-s', SERIAL, *args])


def main():
    action, *args = sys.argv[1:]
    size = re.findall(r'(\d+)x(\d+)', adb('shell', 'wm', 'size').decode())[-1]
    width, height = map(int, size)

    def xy(x, y):
        return str(round(float(x) * width / 448)), str(round(float(y) * height / 997))

    if action == 'tap':
        adb('shell', 'input', 'tap', *xy(*args))
    elif action == 'swipe':
        adb('shell', 'input', 'swipe', *xy(*args[:2]), *xy(*args[2:4]), '450')
    elif action == 'back':
        adb('shell', 'input', 'keyevent', '4')
    elif action == 'text':
        adb('shell', 'input', 'text', args[0].replace(' ', '%s'))
    elif action == 'shot':
        time.sleep(0.6)
        dest = ROOT / 'docs/manuale-utente/screenshots' / (args[0] + '.png')
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(adb('exec-out', 'screencap', '-p'))
        print(dest)
    elif action == 'ui':
        adb('shell', 'uiautomator', 'dump', '/sdcard/pharmabox-manuale-ui.xml')
        root = ET.fromstring(adb('shell', 'cat', '/sdcard/pharmabox-manuale-ui.xml'))
        for node in root.iter('node'):
            label = node.get('text') or node.get('content-desc')
            if label:
                nums = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if len(nums) == 4:
                    x = (nums[0] + nums[2]) / 2 / width * 448
                    y = (nums[1] + nums[3]) / 2 / height * 997
                    print(f'{x:.0f},{y:.0f}: {label}')
    else:
        raise SystemExit('Use shot, ui, tap, swipe, text or back')
    if action in {'tap', 'swipe', 'back', 'text'}:
        time.sleep(0.8)


if __name__ == '__main__':
    main()
