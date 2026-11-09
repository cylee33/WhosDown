#!/usr/bin/env python3
"""Run normal/maximum-text audits of every V1 screen against deterministic UI fixtures."""
import argparse
import glob
import os
import plistlib
import subprocess
import uuid
from pathlib import Path
parser = argparse.ArgumentParser()
parser.add_argument("--device", default="75E3D983-E064-4EE0-A7E9-356BFB9E3936")
parser.add_argument("--method", default="")
parser.add_argument("--start", type=int, default=0)
parser.add_argument("--end", type=int, default=45)
args = parser.parse_args()
build = Path(os.environ.get("WHOSDOWN_AUDIT_BUILD", "/tmp/whosdown-audit-build"))
original = Path(glob.glob(str(build / "Build/Products/WhosDown_WhosDown_*.xctestrun"))[0])
data = plistlib.loads(original.read_bytes())
for config in data["TestConfigurations"]:
    for target in config["TestTargets"]:
        if target.get("BlueprintName") == "WhosDownUITests":
            target.setdefault("EnvironmentVariables", {}).update({"WHOSDOWN_FULL_AUDIT": "1", "WHOSDOWN_AUDIT_START": str(args.start), "WHOSDOWN_AUDIT_END": str(args.end)})
identifier = uuid.uuid4().hex[:8]
path = original.with_name(f"WhosDown-full-screen-audit-{identifier}.xctestrun")
path.write_bytes(plistlib.dumps(data))
result = "/tmp/whosdown-screen-audit-" + identifier + ".xcresult"
print("Audit result:", result, flush=True)
Path("/tmp/whosdown-screen-audit-result.txt").write_text(result)
raise SystemExit(subprocess.call(["xcodebuild", "test-without-building", "-xctestrun", str(path),
    "-destination", f"platform=iOS Simulator,id={args.device}",
    "-parallel-testing-enabled", "NO", "-only-testing:WhosDownUITests/ScreenAuditTests" + (f"/{args.method}" if args.method else ""), "-resultBundlePath", result]))
