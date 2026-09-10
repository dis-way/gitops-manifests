#!/usr/bin/env python3
"""Write a GitHub "create a blob" request body for a file, to stdout.

Used by refresh-envoy-gateway-crds.yml. The body goes to `gh api --input`
rather than an inline `-f content=...` argument: the base64 of the vendored CRD
manifest is ~3.4 MB, and Linux caps a single argv entry at 128 KB
(MAX_ARG_STRLEN), so passing it inline fails with "Argument list too long".
"""

import base64
import json
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <path>", file=sys.stderr)
        return 2
    with open(sys.argv[1], "rb") as handle:
        content = base64.b64encode(handle.read()).decode("ascii")
    json.dump({"content": content, "encoding": "base64"}, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
