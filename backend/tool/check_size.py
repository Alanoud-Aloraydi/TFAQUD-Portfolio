"""Check that every file of the server's code (app/) has at most 300 lines.

Run from the backend folder:

    python tool/check_size.py

A file holds code that belongs together: about 200 lines is usual, and 300
is the most. Past that, the file is two jobs; split it where the jobs part,
never just to make it shorter.
"""

import sys
from pathlib import Path

LIMIT = 300


def main() -> int:
    """Print every file over the limit and answer 1 if there is one."""
    too_long = []
    for path in sorted(Path("app").rglob("*.py")):
        size = len(path.read_text(encoding="utf-8").splitlines())
        if size > LIMIT:
            too_long.append(f"{path.as_posix()}: {size} lines, limit {LIMIT}")
    for line in too_long:
        print(line)
    print(f"{len(too_long)} file(s) over {LIMIT} lines.")
    return 1 if too_long else 0


if __name__ == "__main__":
    sys.exit(main())
