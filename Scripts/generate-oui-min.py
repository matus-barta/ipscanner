#!/usr/bin/env python3

# Copyright © 2026 Matúš Barta.
# SPDX-License-Identifier: GPL-3.0-only
# App Store exception: see APP_STORE_EXCEPTION.md.
#
# Generates oui-min.tsv from the IEEE Registration Authority
# MA-L public assignment listing.
#
# Source:
# https://standards.ieee.org/products-programs/regauth/
#
# The generated file contains assignment prefixes and organization
# names used for local MAC vendor lookup.

import csv
import re
import sys
import unicodedata
from datetime import date
from pathlib import Path


def normalize_oui(value: str) -> str | None:
    normalized = (
        value
        .strip()
        .upper()
        .replace("-", "")
        .replace(":", "")
        .replace(".", "")
        .replace(" ", "")
    )

    if len(normalized) < 6:
        return None

    prefix = normalized[:6]

    if not re.fullmatch(r"[0-9A-F]{6}", prefix):
        return None

    return prefix


def sanitize_vendor(name: str) -> str:
    normalized = unicodedata.normalize(
        "NFC",
        name
    )

    cleaned: list[str] = []

    for character in normalized:
        code_point = ord(character)

        # Remove C0 and DEL control characters.
        if code_point < 32 or code_point == 127:
            continue

        # Remove C1 control characters.
        if 0x80 <= code_point <= 0x9F:
            continue

        cleaned.append(character)

    result = "".join(cleaned).strip()

    # Remove matching wrapping quotes.
    if len(result) >= 2:
        is_double_quoted = (
            result.startswith('"')
            and result.endswith('"')
        )

        is_single_quoted = (
            result.startswith("'")
            and result.endswith("'")
        )

        if is_double_quoted or is_single_quoted:
            result = result[1:-1].strip()

    return result


def load_vendors(
    input_file: Path
) -> dict[str, str]:
    vendors: dict[str, str] = {}

    with input_file.open(
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as file:
        reader = csv.reader(file)

        header = next(reader, None)

        if header is None:
            raise ValueError(
                "The input CSV file is empty."
            )

        if len(header) < 3:
            raise ValueError(
                "The input CSV does not contain the expected columns."
            )

        for row_number, row in enumerate(
            reader,
            start=2
        ):
            if len(row) < 3:
                print(
                    f"Warning: skipping incomplete row "
                    f"{row_number}",
                    file=sys.stderr
                )
                continue

            # Expected IEEE CSV layout:
            # 0: Registry
            # 1: Assignment
            # 2: Organization Name

            registry = row[0].strip().upper()

            # This generator is intended for MA-L assignments.
            if registry != "MA-L":
                continue

            oui = normalize_oui(row[1])

            if oui is None:
                continue

            vendor = sanitize_vendor(row[2])

            if not vendor:
                continue

            # Preserve the first published organization name if the
            # input unexpectedly contains duplicate assignments.
            vendors.setdefault(
                oui,
                vendor
            )

    return vendors


def write_database(
    output_file: Path,
    vendors: dict[str, str]
) -> None:
    output_file.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    with output_file.open(
        "w",
        encoding="utf-8",
        newline="\n"
    ) as file:
        file.write(
            "# Generated from the IEEE Registration Authority "
            "MA-L public assignment listing.\n"
        )
        file.write(
            "# Source: "
            "https://standards.ieee.org/products-programs/regauth/\n"
        )
        file.write(
            f"# Generated: {date.today().isoformat()}\n"
        )
        file.write(
            "# Format: OUI<TAB>Organization Name\n"
        )

        for oui in sorted(vendors):
            file.write(
                f"{oui}\t{vendors[oui]}\n"
            )


def main() -> int:
    if len(sys.argv) != 3:
        executable = Path(sys.argv[0]).name

        print(
            "Usage:\n"
            f"  ./{executable} INPUT.csv OUTPUT.tsv\n\n"
            "Example:\n"
            f"  ./{executable} "
            "../macOS/Resources/oui.csv "
            "../macOS/Resources/oui-min.tsv",
            file=sys.stderr
        )

        return 1

    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2])

    if not input_file.is_file():
        print(
            f"Error: input file not found: {input_file}",
            file=sys.stderr
        )
        return 1

    try:
        vendors = load_vendors(
            input_file
        )

        if not vendors:
            print(
                "Error: no valid MA-L assignments were found.",
                file=sys.stderr
            )
            return 1

        write_database(
            output_file,
            vendors
        )
    except (OSError, csv.Error, ValueError) as error:
        print(
            f"Error: {error}",
            file=sys.stderr
        )
        return 1

    print(
        f"Generated {len(vendors):,} entries"
    )
    print(
        f"Output: {output_file}"
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())