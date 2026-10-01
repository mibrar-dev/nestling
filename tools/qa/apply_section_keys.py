#!/usr/bin/env python3
"""One-off helper: add stable `ds-section-<slug>` keys to gallery section labels.

Keys only — no widget is wrapped, no layout changes. Idempotent: a label that
already carries a `ds-section-` key is left alone.
"""
from __future__ import annotations

import pathlib
import sys

WIDGETS = pathlib.Path(
    "app/lib/features/design_system_gallery/presentation/widgets"
)

TARGETS = {
    "gallery_parent_a.dart": {
        "Buttons": "buttons",
        "Cards": "cards",
        "Lists": "lists",
        "Chips": "chips",
        "Segmented": "segmented",
        "Toggles": "toggles",
        "Stepper": "stepper",
    },
    "gallery_parent_b.dart": {
        "Avatars": "avatars",
        "Coin · Money · Progress · Badge": "coin-money-progress",
        "Quest cards": "quest-cards",
        "Nav bars": "nav-bars",
        "Tab bar": "tab-bar",
        "Bottom CTA": "bottom-cta",
        "FAB · Lock · Pager": "fab-lock-pager",
    },
    "gallery_forms.dart": {
        "Text fields": "inputs",
        "Day picker": "day-picker",
        "Keypad + PIN": "keypad",
    },
    "gallery_overlays.dart": {
        "Overlays": "overlays",
        "Empty state": "empty-state",
    },
}


def main() -> int:
    for name, labels in TARGETS.items():
        path = WIDGETS / name
        text = path.read_text(encoding="utf-8")
        for label, slug in labels.items():
            old = f"NestSectionLabel(label: '{label}')"
            new = (
                f"NestSectionLabel(\n"
                f"          key: const ValueKey('ds-section-{slug}'),\n"
                f"          label: '{label}',\n"
                f"        )"
            )
            if f"ds-section-{slug}" in text:
                print(f"skip  {name}: {slug} already keyed")
                continue
            count = text.count(old)
            if count != 1:
                print(f"FAIL  {name}: {label!r} matched {count} times", file=sys.stderr)
                return 1
            text = text.replace(old, new)
            print(f"keyed {name}: ds-section-{slug}")
        path.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
