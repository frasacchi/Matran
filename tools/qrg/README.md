# QRG spec extraction

`extract_qrg.py` reads a local copy of the *MSC Nastran 2023.3 Quick Reference Guide*
(`MSC_Nastran_2023.3_Quick_Reference_Guide.pdf` in the repo root, not tracked) and writes the
layout specs used by the QRG validation tests in `unit_testing/qrg`:

| File | Content |
|---|---|
| `unit_testing/qrg/spec/qrg_bulk.json` | Bulk Data entries: 10-column field grid of every Format / Alternate Format block, the Example blocks, field type / default specs |
| `unit_testing/qrg/spec/qrg_exec.json` | Executive Control statements, SOL number table |
| `unit_testing/qrg/spec/qrg_case.json` | Case Control command names |
| `unit_testing/qrg/spec/qrg_params.json` | Parameter names |

Requirements: Python 3.10+, `pymupdf`; `markitdown` (CLI) for the optional markdown dumps.

```
python tools/qrg/extract_qrg.py                      # regenerate all specs
python tools/qrg/extract_qrg.py --cards CBEAM --print  # inspect one entry
python tools/qrg/extract_qrg.py --md CBEAM PBAR        # readable dumps -> tools/qrg/out/md (gitignored)
```

Field columns come from word coordinates: each Format table has a header row `1 2 ... 10` whose
x-centres define the field columns, so blank fields keep their position. Only layout facts are
stored (field names, positions, types, defaults, example values).
