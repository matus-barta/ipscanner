#!/usr/bin/env python3

import csv
import re
import sys
import unicodedata

if len(sys.argv) != 3:
    print("Usage: ./generate-oui-min.py ../Resources/oui.csv ../Resources/oui-min.tsv ")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]


def normalize_oui(value: str):
    value = value.strip().upper()

    value = value.replace("-", "")
    value = value.replace(":", "")
    value = value.replace(".", "")
    value = value.replace(" ", "")

    if len(value) < 6:
        return None

    value = value[:6]

    if not re.fullmatch(r"[0-9A-F]{6}", value):
        return None

    return value


def sanitize_vendor(name: str):
    name = unicodedata.normalize("NFC", name)

    cleaned = []

    for ch in name:
        code = ord(ch)

        # Remove control chars
        if code < 32 or code == 127:
            continue

        if 0x80 <= code <= 0x9F:
            continue

        cleaned.append(ch)

    name = "".join(cleaned).strip()

    # Remove wrapping quotes if present
    if len(name) >= 2:
        if (name.startswith('"') and name.endswith('"')) or \
           (name.startswith("'") and name.endswith("'")):
            name = name[1:-1].strip()

    return name

vendors = {}

with open(input_file, "r", encoding="utf-8-sig", newline="") as f:
    reader = csv.reader(f)

    header = next(reader, None)

    for row in reader:
        if len(row) < 3:
            continue

        # IEEE CSV:
        # 0 Registry
        # 1 Assignment
        # 2 Organization Name

        oui = normalize_oui(row[1])

        if oui is None:
            continue

        vendor = sanitize_vendor(row[2])

        if not vendor:
            continue

        vendors.setdefault(oui, vendor)

with open(output_file, "w", encoding="utf-8", newline="\n") as f:
    for oui in sorted(vendors):
        f.write(f"{oui}\t{vendors[oui]}\n")

print(f"Generated {len(vendors):,} entries")
print(f"Output: {output_file}")
