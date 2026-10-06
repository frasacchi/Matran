#!/usr/bin/env python3
"""Extract machine-readable layouts from the MSC Nastran Quick Reference Guide (QRG).

The QRG PDF is not distributed with Matran. This script reads a local copy and writes
JSON specs that the Matran QRG validation tests (unit_testing/qrg) compare against:

  qrg_bulk.json   Bulk Data entries: field grid of each Format / Alternate Format block
                  (exact 10-column positions), the Example blocks, and for each field the
                  type / range / default specification "(Integer > 0; Default = 0)".
  qrg_exec.json   Executive Control statements and the SOL number table.
  qrg_case.json   Case Control command names.
  qrg_params.json Parameter names.

Only layout facts are extracted (names, positions, types, defaults, example values);
descriptive text is not copied.

Field columns are recovered from word coordinates (PyMuPDF): every Format table has a
header row "1 2 ... 10" whose x-centres define the 10 field columns. The `--md` option
dumps readable markdown of selected entries with the `markitdown` CLI (page subsets are
piped through stdin) for manual review.

Usage:
  python tools/qrg/extract_qrg.py [--pdf QRG.pdf] [--out unit_testing/qrg/spec]
  python tools/qrg/extract_qrg.py --cards CBEAM CONM2 --print
  python tools/qrg/extract_qrg.py --md CBEAM PBAR          # -> tools/qrg/out/md/*.md
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

import pymupdf

REPO = Path(__file__).resolve().parents[2]
DEFAULT_PDF = REPO / "MSC_Nastran_2023.3_Quick_Reference_Guide.pdf"
DEFAULT_OUT = REPO / "unit_testing" / "qrg" / "spec"
MD_OUT = REPO / "tools" / "qrg" / "out" / "md"

# Characters the PDF uses for minus signs, quotes and relations
CHAR_MAP = {
    "–": "-", "—": "-", "−": "-", "‐": "-",
    "‘": "'", "’": "'", "“": '"', "”": '"',
    "≤": "<=", "≥": ">=", "≠": "!=", " ": " ",
    "": "<=", "": ">=", "": "!=", "": "<", "": ">",
    "": "=", "": "-", "": "+",
}


def norm(text: str) -> str:
    for k, v in CHAR_MAP.items():
        text = text.replace(k, v)
    # remaining Symbol-font private-use glyphs (U+F020..U+F07E) -> their ASCII slot
    return re.sub(r"[-]", lambda m: chr(ord(m.group(0)) - 0xF000), text)


# ----------------------------------------------------------------------------- TOC
def toc_sections(doc):
    """Return dicts of {name: (first_page, last_page, title)} for bulk entries, executive
    statements, case control commands and parameters (1-based PDF page numbers)."""
    toc = doc.get_toc()
    flat = [(lvl, norm(t).strip(), p) for lvl, t, p in toc]

    def first_page(title, level):
        for lvl, t, p in flat:
            if lvl == level and t == title:
                return p
        raise KeyError(title)

    bulk_lo = first_page("Entries A - B", 2)
    bulk_hi = first_page("Appendix A: Configuring the Runtime Environment", 1)
    exec_lo = first_page("Executive Control Statement Descriptions", 2)
    exec_hi = first_page("Chapter 5: Case Control Commands", 1)
    case_lo = first_page("Case Control Commands", 2)
    case_hi = first_page("Case Control Applicability Tables", 2)
    par_lo = first_page("Parameter Descriptions", 2)
    par_hi = first_page("Parameter Applicability Tables", 2)

    def entries(lo, hi, level=3):
        sel = [(t, p) for lvl, t, p in flat if lvl <= level and lo <= p < hi]
        out = {}
        for i, (t, p) in enumerate(sel):
            nxt = sel[i + 1][1] if i + 1 < len(sel) else hi
            last = max(p, nxt - 1) if nxt > p else p
            out.setdefault(t, (p, last))
        return out

    bulk = {k: v for k, v in entries(bulk_lo, bulk_hi).items() if not k.startswith("Entries ")}
    return {
        "bulk": bulk,
        "exec": entries(exec_lo, exec_hi),
        "case": entries(case_lo, case_hi),
        "params": entries(par_lo, par_hi),
    }


# ----------------------------------------------------------------------------- page rows
def page_rows(page, ytol=2.0):
    """Group the words of a page into rows (sorted top to bottom, left to right)."""
    words = [(w[0], w[1], w[2], w[3], norm(w[4])) for w in page.get_text("words")]
    words.sort(key=lambda w: (round(w[1], 1), w[0]))
    rows = []
    for w in words:
        if rows and abs(rows[-1]["y"] - w[1]) <= ytol:
            rows[-1]["w"].append(w)
        else:
            rows.append({"y": w[1], "w": [w]})
    for r in rows:
        r["w"].sort(key=lambda w: w[0])
        r["text"] = " ".join(w[4] for w in r["w"])
    return rows


def is_header(row):
    toks = [w[4] for w in row["w"]]
    return toks[:10] == [str(i) for i in range(1, 11)] and len(toks) == 10


def column_edges(row):
    cen = [(w[0] + w[2]) / 2 for w in row["w"][:10]]
    pitch = (cen[-1] - cen[0]) / 9
    edges = [cen[0] - pitch / 2] + [(cen[i] + cen[i + 1]) / 2 for i in range(9)] + [cen[9] + pitch / 2]
    return edges


def to_columns(row, edges):
    cols = [""] * 10
    for w in row["w"]:
        xc = (w[0] + w[2]) / 2
        for i in range(10):
            if edges[i] <= xc < edges[i + 1]:
                cols[i] = (cols[i] + " " + w[4]).strip()
                break
    return cols


def in_table(row, edges):
    """True when all words of the row lie inside the 10-column table."""
    lo, hi = edges[0] - 15, edges[10] + 15
    return all(lo <= w[0] and w[2] <= hi for w in row["w"])


# ----------------------------------------------------------------------------- bulk entry
LABEL_RE = re.compile(r"^(Format|Formats|Example|Examples|Alternate|Alternative|Continuation|Field|Describer|Remarks)\b", re.I)
SPEC_RE = re.compile(r"\(([^()]*(?:\([^()]*\)[^()]*)*)\)")
TYPE_WORDS = ("Integer", "Real", "Character", "Blank", "blank", "Complex")


def parse_bulk_entry(doc, name, first, last):
    rows_all = []
    for p in range(first, last + 1):
        page = doc[p - 1]
        rows = page_rows(page)
        # drop running headers / footers (top ~35pt, "Main Index" footer)
        rows = [r for r in rows if r["y"] > 30 and "Main Index" not in r["text"]]
        for r in rows:
            r["page"] = p
        rows_all.extend(rows)

    title = ""
    first_rows = [r for r in page_rows(doc[first - 1]) if r["y"] < 30]
    if len(first_rows) >= 2:
        title = first_rows[1]["text"]

    blocks = []          # {"kind": "format"|"example", "label": str, "rows": [[10 cols]]}
    edges = None
    section = None       # current label text
    sec_blocks = 0       # number of entry blocks started in the current labelled section
    current = None
    prev_row = None
    describer_at = None

    for idx, r in enumerate(rows_all):
        text = r["text"]
        if is_header(r):
            edges = column_edges(r)
            continue
        m = LABEL_RE.match(text)
        if m:
            key = m.group(1).lower()
            if key in ("describer", "field", "remarks"):
                if key != "remarks" and ("Meaning" in text or "Contents" in text or key == "describer"):
                    describer_at = idx
                    break
                if key == "remarks":
                    break
            section = text
            sec_blocks = 0
            current = None
            # label rows sometimes carry the first table row too (rare): ignore
            continue
        if edges is None or not in_table(r, edges):
            current = None
            continue
        cols = to_columns(r, edges)
        # second text line of a cell ("THETA or" / "MCID"): rows ~7pt apart -> merge
        if (current is not None and current["rows"] and prev_row is not None
                and prev_row["page"] == r["page"] and r["y"] - prev_row["y"] < 9.5):
            last = current["rows"][-1]
            current["rows"][-1] = [(a + " " + b).strip() for a, b in zip(last, cols)]
            prev_row = r
            continue
        prev_row = r
        c1 = cols[0]
        base = name.upper().split(",")[0].strip()
        starts_entry = "," not in c1 and c1.upper().rstrip("*") == base
        is_cont = c1 == "" or c1.startswith(("+", "*"))
        lower_words = sum(1 for w in r["w"] if re.search(r"[a-z]{3,}", w[4]))
        prose = lower_words >= 2 or any(len(c.split()) > 2 for c in cols) or "," in c1
        if prose and current is not None and current["kind"] == "format":
            continue                # remark text inside a Format table (e.g. PBEAM)
        if starts_entry:
            sec = (section or "Format:").lower()
            if "example" in sec and ("format" in sec or "alternate" in sec):
                kind = "format" if sec_blocks == 0 else "example"
            elif "example" in sec:
                kind = "example"
            else:
                kind = "format"
            current = {"kind": kind, "label": section or "Format:", "page": r["page"],
                       "large_field": c1.endswith("*"), "rows": []}
            blocks.append(current)
            sec_blocks += 1
        elif current is None or not is_cont or (prose and current["kind"] == "example"):
            current = None          # text / free-field illustration between tables
            continue
        current["rows"].append(cols)

    fields = parse_describers(rows_all[describer_at:] if describer_at is not None else [])
    return {
        "name": name,
        "page": first,
        "last_page": last,
        "title": title,
        "formats": [b for b in blocks if b["kind"] == "format"],
        "examples": [b for b in blocks if b["kind"] == "example"],
        # list (not object): field names such as "12I/T**3" must survive MATLAB jsondecode
        "fields": [dict(name=k, **v) for k, v in fields.items()],
    }


def parse_describers(rows):
    """Field specs from the Describer / Meaning table: {name: {"spec": [...], "default": str}}."""
    if not rows:
        return {}
    head = rows[0]
    split = None
    for w in head["w"]:
        if w[4] in ("Meaning", "Contents"):
            split = w[0] - 4
    if split is None:
        split = head["w"][0][0] + 60
    entries = []
    for r in rows[1:]:
        if r["text"].startswith("Remarks"):
            break
        left = [w for w in r["w"] if w[2] <= split + 2]
        right = [w for w in r["w"] if w[2] > split + 2]
        lname = " ".join(w[4] for w in left)
        if lname in ("Describer", "Field", "Describer Meaning") or lname.startswith("*"):
            continue                    # repeated table header / footnote
        if left:
            entries.append({"name": lname, "text": " ".join(w[4] for w in right)})
        elif entries:
            entries[-1]["text"] += " " + " ".join(w[4] for w in right)
    out = {}
    for e in entries:
        specs = [s.strip() for s in SPEC_RE.findall(e["text"]) if any(t in s for t in TYPE_WORDS)]
        dflt = None
        for s in specs:
            dm = re.search(r"Default\s*=\s*([^;)]+)", s)
            if dm:
                dflt = dm.group(1).strip()
                break
        names = [n.strip() for n in re.split(r",|\band\b|\bthrough\b", e["name"]) if n.strip()]
        # uniform keys so MATLAB jsondecode returns struct arrays (default: null -> [])
        rec = {"describer": e["name"], "spec": specs, "default": dflt}
        for n in names or [e["name"]]:
            out.setdefault(n, rec)
    return out


# ----------------------------------------------------------------------------- exec / case / params
def parse_sol_table(doc, first, last):
    sols = {}
    cur = None
    for p in range(first, last + 1):
        for r in page_rows(doc[p - 1]):
            toks = r["text"].split()
            if (len(toks) >= 2 and re.fullmatch(r"\d{3}", toks[0]) and re.fullmatch(r"[A-Z][A-Z0-9]+", toks[1])
                    and toks[1] != "SOL"):
                cur = toks[0]
                sols[cur] = {"name": toks[1], "description": " ".join(toks[2:])}
            elif cur and r["text"] and r["w"][0][0] > 200 and not r["text"].startswith(("Main Index", "SOL ")):
                # wrapped description lines of the current SOL
                if len(sols[cur]["description"]) < 120:
                    sols[cur]["description"] = (sols[cur]["description"] + " " + r["text"]).strip()
    return sols


def entry_titles(doc, entries, suffix=""):
    out = {}
    for name, (first, last) in entries.items():
        if suffix and not name.endswith(suffix):
            continue
        name = name[: len(name) - len(suffix)].strip() if suffix else name
        rows = [r for r in page_rows(doc[first - 1]) if r["y"] < 30]
        out[name] = {"name": name, "page": first, "last_page": last,
                     "title": rows[1]["text"] if len(rows) > 1 else ""}
    return out


def param_names(entries):
    """Parameter names and first page (several parameters share a page, so defaults are not
    attributed automatically)."""
    return {n: {"name": n, "page": p} for n, (p, _) in entries.items()
            if re.fullmatch(r"[A-Z][A-Z0-9_,]*", n)}


# ----------------------------------------------------------------------------- markitdown
def dump_markdown(pdf, doc, sections, names):
    MD_OUT.mkdir(parents=True, exist_ok=True)
    for n in names:
        rng = None
        for kind in ("bulk", "case", "exec", "params"):
            if n in sections[kind]:
                rng = sections[kind][n]
                break
        if rng is None:
            print(f"[md] {n}: not found", file=sys.stderr)
            continue
        sub = pymupdf.open()
        sub.insert_pdf(doc, from_page=rng[0] - 1, to_page=rng[1] - 1)
        res = subprocess.run(["markitdown", "-x", "pdf"], input=sub.tobytes(), capture_output=True)
        if res.returncode != 0:
            print(f"[md] {n}: markitdown failed: {res.stderr.decode(errors='replace')}", file=sys.stderr)
            continue
        (MD_OUT / f"{n.replace(',', '_').replace(' ', '')}.md").write_bytes(res.stdout)
        print(f"[md] {n} -> {MD_OUT / (n + '.md')}")


# ----------------------------------------------------------------------------- main
def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pdf", type=Path, default=DEFAULT_PDF)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--cards", nargs="*", help="only these bulk entries (debugging)")
    ap.add_argument("--print", action="store_true", help="print the parsed entries instead of writing JSON")
    ap.add_argument("--md", nargs="*", help="markitdown dumps of these entries to tools/qrg/out/md")
    args = ap.parse_args(argv)

    if not args.pdf.is_file():
        sys.exit(f"QRG PDF not found: {args.pdf}")
    doc = pymupdf.open(args.pdf)
    sections = toc_sections(doc)

    if args.md is not None:
        dump_markdown(args.pdf, doc, sections, args.md)
        return

    names = args.cards or sorted(sections["bulk"])
    bulk = {}
    for n in names:
        if n not in sections["bulk"]:
            print(f"unknown entry {n}", file=sys.stderr)
            continue
        first, last = sections["bulk"][n]
        try:
            bulk[n] = parse_bulk_entry(doc, n, first, last)
        except Exception as exc:  # keep going, report
            print(f"{n}: {exc}", file=sys.stderr)

    if args.print:
        print(json.dumps(bulk, indent=1))
        return

    meta = {"source": "MSC Nastran 2023.3 Quick Reference Guide", "pdf_pages": doc.page_count,
            "generator": "tools/qrg/extract_qrg.py"}
    sol_rng = sections["exec"].get("SOL")
    out = {
        "qrg_bulk.json": {"meta": meta, "cards": bulk},
        "qrg_exec.json": {"meta": meta, "statements": entry_titles(doc, sections["exec"]),
                          "sol": parse_sol_table(doc, sol_rng[0], sol_rng[1] + 2) if sol_rng else {}},
        "qrg_case.json": {"meta": meta, "commands": entry_titles(doc, sections["case"], suffix="(Case)")},
        "qrg_params.json": {"meta": meta, "params": param_names(sections["params"])},
    }
    args.out.mkdir(parents=True, exist_ok=True)
    for fname, data in out.items():
        (args.out / fname).write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"wrote {args.out / fname}")


if __name__ == "__main__":
    main()
