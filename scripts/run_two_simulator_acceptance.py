#!/usr/bin/env python3
"""Run the V1 core loop with an independent Host and Player on two iOS simulators.
Requires a seeded local demo-whosdown emulator and an existing build-for-testing.
"""
import glob
import os
import plistlib
import subprocess
import sys
import uuid
from pathlib import Path

build = Path(os.environ.get("WHOSDOWN_TEST_BUILD", "/tmp/whosdown-build"))
original = Path(glob.glob(str(build / "Build/Products/WhosDown_WhosDown_*.xctestrun"))[0])
title = "Phase8 " + uuid.uuid4().hex[:10]
devices = ["75E3D983-E064-4EE0-A7E9-356BFB9E3936", "3BF99680-80CA-410D-A758-C51244A2087B"]
roles = [("host", "testHostPublishesApprovesAndChats"), ("player", "testPlayerDiscoversRequestsAndChats")]
processes = []
print("Acceptance Match:", title, flush=True)
Path("/tmp/whosdown-two-device-title.txt").write_text(title)
for device, (role, method) in zip(devices, roles):
    subprocess.run(["xcrun", "simctl", "boot", device], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["xcrun", "simctl", "bootstatus", device, "-b"], check=True, stdout=subprocess.DEVNULL)
    subprocess.run(["xcrun", "simctl", "location", device, "set", "40.4433,-79.9436"], check=True)
    subprocess.run(["xcrun", "simctl", "privacy", device, "grant", "location", "edu.cmu.whosdown"], check=True)
    data = plistlib.loads(original.read_bytes())
    for configuration in data["TestConfigurations"]:
        for target in configuration["TestTargets"]:
            if target.get("BlueprintName") == "WhosDownUITests":
                target.setdefault("EnvironmentVariables", {}).update({"WHOSDOWN_TWO_DEVICE": "1", "WHOSDOWN_QA_TITLE": title})
    path = original.with_name(f"WhosDown-two-{role}.xctestrun")
    path.write_bytes(plistlib.dumps(data))
    log = Path(f"/tmp/whosdown-two-{role}.log").open("w")
    command = ["xcodebuild", "test-without-building", "-xctestrun", str(path),
               "-destination", f"platform=iOS Simulator,id={device}", "-parallel-testing-enabled", "NO",
               f"-only-testing:WhosDownUITests/TwoDeviceAcceptanceTests/{method}",
               "-resultBundlePath", f"/tmp/whosdown-two-{role}-{title.replace(' ', '-')}.xcresult"]
    processes.append((role, subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT), log))
failed = False
for role, process, log in processes:
    code = process.wait()
    log.close()
    print(role, "PASS" if code == 0 else f"FAIL ({code})", flush=True)
    failed |= code != 0
sys.exit(1 if failed else 0)
