"""Check that every file of the server's code (app/) has at most 100 lines,
so each one does a single job.

Run from the backend folder:

    python tool/check_size.py
    python tool/check_size.py --update-baseline

The files that were longer before this check existed are listed in
tool/size_baseline.txt with the size they had. The check fails on a new
file over the limit and on a listed file that grew. Updating the baseline
only drops the files that are short enough now and lowers the others;
it never adds a file.
"""

import sys
from pathlib import Path

LIMIT = 100
BASELINE = Path("tool/size_baseline.txt")


def sizes() -> dict[str, int]:
    """The number of lines of every Python file under app/."""
    return {
        path.as_posix(): len(path.read_text(encoding="utf-8").splitlines())
        for path in sorted(Path("app").rglob("*.py"))
    }


def read_baseline() -> dict[str, int]:
    """The listed files and their sizes; lines starting with # are notes."""
    if not BASELINE.exists():
        return {}
    listed = {}
    for line in BASELINE.read_text(encoding="utf-8").splitlines():
        entry = line.split("#")[0].split()
        if len(entry) == 2:
            listed[entry[0]] = int(entry[1])
    return listed


def write_baseline(listed: dict[str, int]) -> None:
    """Keep the files still over the limit, each at its smaller size."""
    lines = [
        "# Files of app/ longer than 100 lines before tool/check_size.py",
        "# existed, with their size. Split them; never add one.",
        "",
    ] + [f"{path} {size}" for path, size in sorted(listed.items())]
    BASELINE.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    """Print every problem and answer 1 if there is one."""
    found = sizes()
    listed = read_baseline()
    problems = []
    for path, size in found.items():
        if size <= LIMIT:
            continue
        if path not in listed:
            problems.append(f"new   {path}: {size} lines, limit {LIMIT}")
        elif size > listed[path]:
            problems.append(f"grew  {path}: {size} lines, was {listed[path]}")
    if "--update-baseline" in sys.argv:
        write_baseline({
            path: min(size, listed[path])
            for path, size in found.items()
            if size > LIMIT and path in listed
        })
    left = sum(1 for path in listed if found.get(path, 0) > LIMIT)
    for problem in problems:
        print(problem)
    print(f"{len(problems)} problem(s); {left} listed file(s) still to split.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
