#!/usr/bin/env python3
"""Counts accessibility-relevant patterns in a Flutter app's lib/ folder.

Run from the repository root: python3 tool/a11y_scan.py
Uses text matching only, so treat results as a list of places to look. It
can't say whether an app is accessible. See docs/ACCESSIBILITY_AUDIT.md.
"""
import collections
import glob
import re

FILES = {
    f: open(f, encoding="utf-8").read()
    for f in glob.glob("lib/**/*.dart", recursive=True)
    if "/l10n/" not in f
}


def call(text, start):
    """The balanced (...) beginning at text[start]."""
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
    return text[start:]


def line(text, offset):
    return text[:offset].count("\n") + 1


def near_semantics(text, offset):
    return "Semantics" in text[max(0, offset - 250) : offset]


def check(name, pattern, passes):
    total, misses = 0, []
    for path, text in sorted(FILES.items()):
        for m in re.finditer(pattern, text):
            total += 1
            if not passes(call(text, m.end() - 1), text, m.start()):
                misses.append(f"{path}:{line(text, m.start())}")
    print(f"{name}: {total} found, {len(misses)} to review")
    for where in misses:
        print(f"  {where}")


def count(name, pattern):
    per_file = collections.Counter(
        {f: len(re.findall(pattern, t)) for f, t in FILES.items()}
    )
    per_file += collections.Counter()
    print(f"{name}: {sum(per_file.values())} in {len(per_file)} files")


check(
    "Icon button without tooltip",
    r"\bIconButton(?:\.(?!styleFrom)\w+)?\(",
    lambda a, t, p: "tooltip" in a,
)
check(
    "Floating button without tooltip",
    r"\bFloatingActionButton(?:\.(?!extended)\w+)?\(",
    lambda a, t, p: "tooltip" in a,
)
check(
    "GestureDetector tap without nearby Semantics",
    r"\bGestureDetector\(",
    lambda a, t, p: "onTap" not in a or near_semantics(t, p),
)
check(
    "InkWell without nearby Semantics or text",
    r"\bInkWell\(",
    lambda a, t, p: near_semantics(t, p) or "Text(" in a,
)
check(
    "Image without a label",
    r"\bImage\.(?:network|asset|file|memory)\(",
    lambda a, t, p: "semanticLabel" in a
    or "excludeFromSemantics" in a
    or near_semantics(t, p),
)
count("Text scale clamped or disabled", r"withClampedTextScaling|textScaleFactor|TextScaler\.(?:noScaling|linear)")
count("FittedBox (shrinks text instead of wrapping)", r"\bFittedBox\(")
count("TextOverflow.ellipsis (can hide text at large sizes)", r"TextOverflow\.ellipsis")
count("Reduce-motion checks", r"(?i)disableanimations")
count("Bold-text checks", r"boldTextOf|\.boldText")
count("Semantics widgets", r"\bSemantics\(")
count("Live regions", r"liveRegion")
count("Text not translated", r"\bText\(\s*'[A-Z]")
