# Matran: QRG validation, full .bdf import, bdf → baff → ADS round trip

Living document: findings, plan, decisions, progress log. Updated as work proceeds.

## 1. Goal
1. Validate Matran (`tbx/+mni`) card reading (`+bulk`) and writing (`+printing/+cards`) against the
   MSC Nastran 2023.3 Quick Reference Guide (QRG, `MSC_Nastran_2023.3_Quick_Reference_Guide.pdf`, untracked).
2. `mni.import_matran` imports *any* .bdf completely, including executive / case control: the solution (SOL) and
   its settings are flagged in a separate output (analysis info / cards imported).
3. With an option flag, convert the imported bdf into a pure `baff.Model` using only the bdf (frames of reference,
   parent/child tree, stations, aero, control surfaces, masses, constraints).
4. Verify: bdf → Matran → baff → ADS (`ads.baff.baff2fe`) → fe → .bdf, compare with the original (model compare +
   Nastran SOL101/103).

## 2. Decisions (user)
| Topic | Decision |
|---|---|
| baff / ADS changes | Free to modify (current branches, alongside existing WIP). Every change logged in §7. |
| Content baff cannot represent | Approximate + report. Loads, SPC sets, aero settings stay in the analysis info; the round-trip harness re-applies them. |
| Verification depth | Model comparison + Nastran SOL103 (frequencies, MAC) and SOL101 (static, GPWG) with local MSC Nastran 2023.2. |
| QRG artefacts in repo | Commit the extractor script and the derived field-layout JSON; the PDF stays untracked (.gitignore). |

## 3. Environment
- MATLAB R2025b (also R2024b). Startup mpm "dev" collection adds Matran, ads, baff, ... to the path.
- MSC Nastran 2023.2: `C:\Program Files\MSC.Software\MSC_Nastran\2023.2\bin\nastran.exe`.
- Nastran TPL (657 decks): `C:\Program Files\MSC.Software\MSC_Nastran_Documentation\2023.2\tpl` (extra import corpus).
- QRG PDF: 3076 pages. Bulk Data ch.9 pp.1097–3038 (930 entries); bulk format rules pp.1041–1054; exec control
  pp.142–204 (SOL p.183); case control pp.205–696; parameters pp.834–953.
- PDF tools: PyMuPDF 1.28 (word coordinates → exact 10-column field grids), `markitdown` CLI (readable dumps;
  page subsets piped through stdin), `pdftotext`.

## 4. Findings (exploration)

### 4.1 Matran
- Import chain: `import_matran` → `private/importBulkData` → `readCharDataFromFile` → `splitInputFile` →
  `extractBulkData` → `extractParameters` → `extractIncludeFiles` → `extractCards` (`isMatranClass` + `defineBulkMask`).
- Executive / case control are split off and discarded; PARAM/MDLPRM are extracted then discarded.
- Problems found while reading the code (to be confirmed by tests):
  - `splitInputFile`: `CEND` / `BEGIN BULK` found with `contains` anywhere (several hits break indexing), case
    sensitive; lines with 1 < length < 8 are dropped (short free-field cards such as `GRID,1`).
  - `extractParameters`: substring match on `PARAM`; only the first value kept.
  - `extractBulkData`: any line containing `*` treated as large field; the exponent fix regex also edits character
    labels (`AIL1-2` → `AIL1E-2`).
  - `PBAR` bulk layout misses the blank field 9 → C, D, E, F, K, I12 shifted by one field.
  - Printing `CBEAM` OFFT list contains `GoG` (QRG: `GOG`).
  - `CoordSystem.getRotationMatrix`: x axis (C−A) not orthogonalised against z; `getPosition(...,'Recursive',false)`
    condition inverted; only CORD2R supported.
  - `extractIncludeFiles`: relative paths tried against the MATLAB current folder first; missing absolute paths error.
- Typed bulk import covers about 50 cards. Missing for the examples: AESURF, AESTAT, DMI, FORCE, MOMENT, GRAV, LOAD,
  SPCADD, PBEAML, PBUSH, CBUSH, RJOINT, TRIM/TRIM2, SUPORT, other CORD types, DMIG, PROD, ...
- `unit_testing/TestMatran` fails at class load when `../Matran_test_data` is missing, so no test runs.

### 4.2 baff (target)
- `baff.Element`: `A` (child → parent rotation), `Offset` (parent frame), `Eta`, `EtaLength`, `Parent`, `Children`.
  Global position `X = Offset + A*(GetPos(Eta) + off)`, recursively through the parent at `obj.Eta`.
- Beam / Wing stations (`baff.station.Beam`): Eta, EtaDir (locus direction, element frame), StationDir (section y),
  A, I (3x3), J, tau, Mat, DMIG. Locus = cumsum(ΔEta·EtaDir)·EtaLength; properties interpolate linearly.
- Wing frame: x spanwise, y forward (leading edge at +y), z up. AeroStations: Chord, Twist, BeamLoc, Airfoil,
  ThicknessRatio, LiftCurveSlope, LinearDensity, LinearInertia, MassLoc. ControlSurfaces: Name, Etas, pChord.
- ShellStation (WIP): Nodes in element frame, quad Shells (G(4,1), Mat, Thickness, PSHELL/PCOMP, BendRatio, NSM),
  rib hubs (SecondaryEta/Nodes), ConstrainedEta/Nodes, SecondaryBeams (LBeam), SplineNodes.
- Mass, Point (Force/Moment), Constraint (ComponentNums), Hinge (HingeVector, Rotation [deg], K, C, isLocked),
  BluffBody (Body stations), Fuel, Payload.

### 4.3 ADS (baff → fe → bdf)
- `ads.baff.baff2fe` → `element2fe` (recursive) → type converters → `finishSectionOffsets` → `Flatten`;
  `Component.UpdateIDs()` then `Component.Export(file)`. ID starts: CID 101, GID 1001, EID 10001, PID 101, MID 1, SID 1.
- Every element gets a CORD2R (A = Origin, B = Origin + A·ez, C = Origin + A·ex, RID = parent CID); child origin
  = Offset + parent.GetPos(child.Eta). The CORD2R RID chain therefore mirrors the baff tree.
- Children attach with RBE2 123456 (closest parent attachment node independent; constraints reversed). Plain masses
  (A = I, no children) get no CS: their GRID is written in the parent CS.
- beam2fe: nodes at station etas ∪ child etas; CBEAM + tapered PBEAM per segment; section
  `BeamSection(A, I1 = I(3,3), I2 = I(2,2), I12 = −I(2,3), J)`; CBEAM v = StationDir in GA output CS; E = inf → RBE2 chain.
- hinge2fe: two coincident GRIDs (CP = CD = hinge CS, x = hinge vector), RJOINT (CB 12356) + CBUSH (CID) + PBUSH
  (K4, B4); locked → RBE2; children use CS = A·R(hv, Rotation).
- mass2fe → CONM2 (CID = point CS, inertia from baff InertiaTensor as-is); point2fe → FORCE/MOMENT; constraint2fe → SPC1.
- wing2fe: beam2fe/shell2fe + LE/TE spline nodes (RBE2), streamwise CAERO1 (CP = wing CS; chord along AERO ACSID x),
  DMI W2GJ (twist) / WKK (lift slope), PAERO1, SPLINE1 (shell) / SPLINE4 (beam) + AELIST/SET1, AESURF, lumped masses.
- shell2fe: GRIDs (CP = wing CS), CQUAD4 + PSHELL per shell, one MAT per material, RBE3 rib hubs (Ci 123),
  RBE2 at constrained stations, LBeam stringers.
- AERO/AEROS (`fe.AeroSettings`) and panel counts are set at FE level, not in baff.
- Cards ADS writes: GRID CORD2R CBEAM CBAR PBEAM PBAR PBEAML CQUAD4 PSHELL PCOMP MAT1 MAT8 CONM2 CONM1 RBE2 RBE3 SPC1
  SUPORT SUPORT1 FORCE MOMENT RJOINT CBUSH PBUSH CAERO1 PAERO1 AEFACT AELIST SET1 SPLINE1/4/6/7 DMI AESURF AELINK
  AERO AEROS DMIG GENEL CELAS2 CDAMP2, plus solution cards (EIGRL/EIGR, TRIM, FLUTTER, MKAERO1, FLFACT, GUST, TABDMP1, ...).
- Possible ADS issues to check in the round trip: child beam yDir rotated by one parent level only; CONM2 I21/I31/I32
  sign convention (QRG CONM2 remark 5 applies the minus sign itself).

### 4.4 Example decks
- `bwb` (ADS output, shell wing): CORD2R 102 (wing, RID 0), 103 (child, RID 102), 104 (aero ACSID), 105–108 (AESURF
  hinge CS); 2518 GRID (CP 102); 2688 CQUAD4 + 2688 PSHELL; MAT1; 23 RBE3; 45 RBE2; 6 CAERO1 (AEFACT LCHORD);
  6 SPLINE1; 4 AESURF/AELIST; DMI W2GJ/WKK; SPC1 246 on root nodes; FORCE/MOMENT in CID 102. `sol101.bdf`: SOL 101,
  SPC = 73, 6 subcases with LOAD, PARAMs, SPCADD, LOAD, GRAV; reference `bin/sol101.h5/.f06`. The workspace .mat
  holds no baff model (no ground truth) → compare FE models and Nastran results.
- `example_1_semispan_model`: CBEAM (v vector) + PBEAML BAR, PLOTEL, CONM2, RBE2, RBE3, CORD2R + DMI in an INCLUDE,
  hinge as coincident GRIDs (CP 3) + RBE2; CAERO1/PAERO1/SPLINE4/SET1/AELIST/AESTAT; f06 for SOL 101/103/144.
- `example_2_a320`: GRIDs in CP 0 with CD = local CS, CONM2 with offsets, CBEAM + PBEAM, CBUSH + PBUSH (K 1e11) +
  RJOINT (123456) as joints, SPLINE7, AESURF, TRIM2, SUPORT, AEROS, free-field cards; SOL 144 and SOL 103 decks.

## 5. Plan
| Phase | Content | Status |
|---|---|---|
| 0 | Housekeeping: .gitignore (PDF, tool output, validation results); TestMatran loads without `Matran_test_data`; baseline tests | done |
| 1 | QRG spec extraction: `tools/qrg/extract_qrg.py` → `unit_testing/qrg/spec/*.json` (bulk layouts, examples, field types/defaults, SOL table, case control list, parameters) + manual overrides | done |
| 2 | QRG validation tests for `+bulk` layouts, QRG example parsing, `+printing` columns, print → import round trip; fix every discrepancy (logged in §6) | done (`TestQrgPrinting`: 45 card fixtures, small + large field, re-import) |
| 3 | Full import: new tokenizer, section splitter, INCLUDE tree, exec/case control parser → `mni.analysis.buildInfo`; new card classes + `GenericCard` fallback; `import_matran` outputs `[data, info, baffModel]` | done |
| 4 | bdf → baff converter (`+mni/+baff`): frames, components, stations, aero, control surfaces, masses, constraints, hinges, provenance (`Meta.bdf`), conversion report | done (refined during phase 5) |
| 5 | Round trip + Nastran: `mni.validation.roundTrip` on all examples; model compare; SOL103/SOL101; fix baff/ADS where needed | done (results §8, 2026-10-05; harness test `unit_testing/TestRoundTrip`) |
| 6 | Documentation: final report here, CLAUDE.md updates (Matran, baff, ADS), changelogs, usage examples | done (§9 final report) |

### 5.1 Phase 4 design notes (bdf → baff)
- Global geometry: resolve all CORD chains (R/C/S), GRID global positions and displacement frames (CD).
- Components: connected CQUAD4/CTRIA3 sets → `baff.Wing` with ShellStation; chains of CBEAM/CBAR/CROD (break at
  junctions, material changes, property discontinuities) → `baff.Beam`, or `baff.Wing` when an aero surface is splined to it.
- Frames: if a component's GRIDs share one non-basic CP, use that CORD2R as the element frame (exact for ADS decks);
  otherwise derive x = span (chain direction), y = forward (−aero x projected), z = x × y.
- Stations: Eta from arc length, EtaDir from segment directions, EtaLength = locus length; StationDir from CBEAM v
  (or G0) in the element frame; PBEAM/PBAR/PBEAML → A, I, J (inverse of the ADS mapping).
- Tree: root = constrained component (else largest); children via RBE2 / joints / shared nodes;
  child.A = R_parentᵀ·R_child, child.Eta = eta of the parent attachment node, child.Offset = rest of the origin offset.
- RJOINT + CBUSH + PBUSH → `baff.Hinge` (released DOF gives the axis; K, C from PBUSH); fully rigid joints → plain attachment.
- CONM2 → `baff.Mass` (offsets, CID frame → Mass.A); SPC set selected by case control → `baff.Constraint`
  (or `ConstraintDoFs` when every station node but the first carries it). Loads stay in the analysis info.
- CAERO1 strips → AeroStations (eta and BeamLoc from the chord line / beam locus closest point; twist from DMI W2GJ,
  lift slope from DMI WKK); AESURF + AELIST + LCHORD → ControlSurface (Etas, pChord); AELINK → linked surface.
- ADS decorations (LE/TE spline nodes, lumped mass nodes, rib hubs) are recognised and not turned into baff elements.
- `Meta.bdf` keeps source IDs (GRIDs per node/station, EIDs, PIDs, CIDs). A conversion report lists every
  approximation.

## 6. QRG discrepancy log
QRG page = PDF page of the entry. Tests: `unit_testing/qrg` (`TestQrgBulkLayout`, `TestQrgBulkExamples`).

| # | Card / area | QRG ref | Issue | Fix | Status |
|---|---|---|---|---|---|
| 1 | PBAR | p.2419 | Blank field 9 missing → C1…F2, K1, K2, I12 read one field early | blank `'b'` added after NSM | fixed |
| 2 | EIGR | p.1788 | NORM, G, C are on the continuation (fields 8-9 of line 1 blank); Matran read them from fields 8, 9, 10 | two blanks added | fixed |
| 3 | MAT3 | p.2020 | `NUXTHZ` should be `NUTHZ`; fields 2-3 of the continuation are blank (GZX at field 4) | renamed, two blanks added | fixed |
| 4 | CTRIA3 | p.1540 | TFLAG/T1-T3 one field early (two blank fields before TFLAG, not one) | blank added | fixed |
| 5 | SPLINE2 | p.2837 | USAGE is field 5 of the continuation (field 4 blank) | blank added | fixed |
| 6 | SPLINE3 | p.2839 | Layout is G1 C1 A1 USAGE / G2 C2 A2 …; Matran had G1 C1 A1 G2 C2 A2 USAGE. Draw used non-existent ID1/ID2 | USAGE moved, (Gi, Ci, Ai) list for the continuation triplets; draw uses BOXID | fixed |
| 7 | SPLINE5 | p.2843 | Continuation is DTHX DTHY _ USAGE METH _ FTYPE RCORE (two blanks missing) | blanks added | fixed |
| 8 | SPLINE7 | p.2848 | CID is field 9 of line 1; continuation is _ _ _ USAGE METHOD DZR IA2 EPSBM. Matran had USAGE at field 9 → SPLINE7 cards (A320 example) read CID/USAGE/METHOD wrongly | reordered + 3 blanks | fixed |
| 9 | CBAR | p.1351 | Continuation PA PB W1A…W3B not read | added (as CBEAM) | fixed |
| 10 | CBAR / CBEAM OFFT | p.1351, 1358 | Only `GGG` accepted; other QRG values (BGG, GGO, BGO, GOG, BOG, GOO, BOO) silently replaced by the default | full QRG list | fixed |
| 11 | BulkData.getBulkMeta | – | Blank `'b'` types combined with masked properties only aligned by coincidence; mask order had to match the property order | rewritten (explicit walk over types / masks) | fixed |
| 12 | PBEAM | p.2438 | Parser: inverted continuation test, off-by-one (`propData(32:end)`), no optional C(A) line, no intermediate stations, J defaulted to (I1+I2)/2 (QRG: 0.0), end B blanks not taken from end A, NSI(B)/CW(B)/M(B)/N(B) defaults wrong; I12 forced non-negative | rewritten per QRG remarks 4-8; intermediate stations kept in `Stations`; I12 sign free | fixed |
| 13 | PBAR | p.2419 | I12 forced non-negative (QRG: I1·I2 − I12² > 0) | attribute removed | fixed |
| 14 | RBE2 | p.2687 | ALPHA taken from the last field (lost the last GM when no ALPHA; with ALPHA → GM list empty); no TREF | parser: GM integers until the first real, then ALPHA, TREF | fixed |
| 15 | RBE3 | p.2692 | "UM" and "ALPHA" keyword lines not supported (import error) | parser with UM (GMi, CMi) and ALPHA (ALPHA, TREF) | fixed |
| 16 | SET1 | p.2801 | "SKIN" option → import error | stored in `Skin` | fixed |
| 17 | CELAS1/2, CMASS1/2/3/4 | p.1384-1433 | Blank G/S (grounded) rejected as missing data; CMASS3 PID typed real | defaults 0, PID integer | fixed |
| 18 | AEROS, MAT3, MAT8 | – | Classes defined but missing from the hand-written card→class map → never imported | `defineBulkMask` now built from the mni.bulk class constructors | fixed |
| 19 | ASET, ASET1 | p.1152-1153 | No ID property → import error | ID optional | fixed |
| 20 | FEModel.combine | – | `NumBulk` not updated when entries from INCLUDE files are appended | `BulkData.append` updates NumBulk and per-entry extra data | fixed |
| 21 | MAT8 | p.2025 | HFAIL/HTAPE/HFABR keyword lines not imported | documented gap (`QrgKnownGaps`) | open (by design) |
| 22 | AERO (printing) | AERO entry | `mni.printing.cards.AERO` rejected ACSID = 0 (validator `x>0`); QRG: Integer ≥ 0, default basic. ADS export of AeroSettings with ACSID 0 errored | validator `isempty(x)\|\|x>=0` | fixed |
| 23 | MAT1 (import) | p.~2010 (MAT1) | Blank E / G / NU defaulted to 0.0, so the QRG two-of-three rule could not be applied (blank G must be E/(2(1+NU))). Found by the round trip: converted G = 0 → ADS MAT1 G = 0 → Nastran EMG 2040 singular CBEAM. NU range was `< 0.5` (QRG: `≤ 0.5`) | defaults NaN (blank), NU ≤ 0.5; `collectModel.i_mat1` completes the third value | fixed (QRG suites re-run 2026-10-05: green) |
| 24 | PBARL / PBEAML properties (`mni.bulk.beamSection`) | PBARL Figures 9-106…9-109 (p.2424–2427) | Figure axes read as horizontal = y_elem; the QRG figures have horizontal = **z_elem**, vertical = y_elem → I1 / I2 swapped for every type (BAR 0.03×0.005: I1 = 1.125e-8 instead of 3.125e-10). BOX: DIM3 is the top/bottom wall, DIM4 the side wall (were swapped). H: flanges are 0.5·DIM2 each; CROSS: arms 0.5·DIM1 each (full DIM used). Found by the example_1 modal gap (first two bending modes swapped, MAC 0.94 crosswise); `compareModels` was blind to it (both sides use `beamSection`) | rewritten; verified with MSC Nastran 2023.2: cantilever CBEAM, PBEAML vs PBEAM from `beamSection`, mass and tip bending rotations equal for ROD, TUBE, TUBE2, BAR, BOX, I, T, L (I12 sign too), CHAN, H, CROSS. J (approximation): < 2.5 % for ROD…CHAN, 6 % BOX, 8 % CROSS, 23 % H (documented in the function) | fixed, test `TestQrgCustomCards/beamSectionProperties` |
| 25 | PBAR (printing) | p.2419 | I12 (line 3, field 4) never written | written after K1, K2 | fixed |
| 26 | SUPORT1 (printing) | SUPORT1 entry | 4th pair written into field 9 of line 1 (QRG: blank) | blank inserted after the third pair | fixed |
| 27 | CBUSH (printing) | p.~1370 | 'X' form wrote an empty G0 instead of X1–X3 (orientation lost) | X1–X3 written | fixed |
| 28 | PBUSH (printing) | PBUSH entry | RCV line appended an extra real field per value (consumed non-existent data) | removed | fixed |
| 29 | CBAR (printing) | – | X / Wa / Wb defaults were the validator function handles → error when omitted | defaults [NaN×3] / zeros; OFFT validated against the QRG list | fixed |
| 30 | CBEAM (printing) | p.1358 | OFFT list had `GoG` (QRG `GOG`) | `GOG` accepted (`GoG` kept for compatibility), written in upper case | fixed |
| 31 | Large field (printing, `BaseCard.fprint_nas`) | "Continuations" | New-line code `n` in large field jumped to the next *physical* line (half a logical line): MKAERO1 k values landed in fields 6… instead of the next logical line; after a full line `n` wrote an empty continuation | `n` pads the logical line (Nastran keeps a blank `*` half line: checked with ECHO=SORT); no-op at the start of a logical line | fixed |
| 33 | CORD1R/C/S (import) | CORD1x entries | Found by the cloud review: CORD1x objects have no CID/RID/A/B/C properties, but `CoordSystem.getPosition` / `getVector` (used by `Node` global coordinates) read them → error for a GRID with CP/CD in a CORD1x system | frames resolved in basic at import (`import_matran` → `CoordSystem.resolveFrames` with `mni.util.Geometry`, hidden `Resolved` property); sealed methods share one `frameData` helper | fixed, test `TestQrgCustomCards/cord1GridPositions` |
| 32 | PCOMP (import) | p.~2470 | SOUTi text → import error; blank ply fields removed before the list split | dedicated parser: plies of 4 fields, blank MIDi / Ti = previous ply, THETAi 0, SOUTi NO | fixed |

## 7. Changes outside Matran (baff, ADS)
| Repo | File | Change | Reason |
|---|---|---|---|
| baff | `tbx/+baff/+station/@Beam/Beam.m` | new `NSM (1,:)` property (scalar expands to all stations), constructor option `NSM`, `nsmVector()`; `horzcat`, `eq`, `GetIndex`, `SetIndex`, `Duplicate`, `interpolate` carry NSM; `GetEtaMass` / `GetEtaCoM` include NSM (trapezoidal) | PBEAM / PBAR NSM had no baff equivalent: A320 beam mass was lost |
| baff | `tbx/+baff/+station/@Beam/ToBaff.m`, `FromBaff.m`, `TemplateHdf5.m` (CRLF) | NSM dataset in the HDF5 IO; `FromBaff` tolerates old files without it | keep NSM through baff files |
| ADS | `tbx/+ads/+fe/BeamStation.m` (CRLF) | `NSM` property; `FromBaffStation` copies `st.NSM(1)`; `ToMatranSection` passes `NSM` to `mni.printing.cards.BeamSection` | write PBEAM NSM |
| ADS | `tbx/+ads/+fe/Beam.m` | `GetMass` adds `h*(NSM1+NSM2)/2` | mass bookkeeping |
| ADS | `tbx/+ads/+fe/@Component/Component.m` (CRLF) | `massItems` adds the NSM line mass items | mass properties |
| ADS | `tbx/+ads/+baff/element2fe.m` (CRLF) | child beam `yDir` is rotated by the parent frame once per child, for every beam of the child **subtree** (new local `rotateBeamDirs`); before: only the child's own beams, once per non-local CS of the child, never the grandchildren | bug: beams 2+ levels below a rotated ancestor got a wrong CBEAM orientation vector (example_1 `Beam_2191`: element y axis 128° off, dot −0.616 → 1.000000 after the fix) |
| ADS | `tbx/+ads/+fe/Beam.m` | `NSI (2,1)` property (PBEAM NSI(A), NSI(B)); export passes `'NSI'` to `mni.printing.cards.PBEAM` when non-zero | A320 PBEAM NSI (fuselage 295 kg·m²/m) was lost: GPWG Ixx −7.8 %, modes 5/7/9 off (MAC 0.68–0.81) → exact after the fix |
| ADS | `tbx/+ads/+baff/private/beam2fe.m` | `applyBeamSection` reads `Meta.ads.BeamSection.NSI` (per station, linear, element ends) | NSI carried like the existing K / SC / NA section data (no baff change needed) |
| baff, ADS | changed files above, `changelog.txt`, `CLAUDE.md` | in-code comments on every change of this task (why / units / Matran origin), `[Unreleased]` changelog entries (baff: NSM; ADS: NSM, NSI, element2fe fix), CLAUDE.md notes (baff station NSM; ADS yDir rotation, mni round trip) | documentation (2026-10-05) |

Not changed although seen: ADS `element2fe` makes the structure grid the *dependent* of the RBE2 to a constraint grid (SPC must be on an independent grid), so two `baff.Constraint`s whose closest attachment point coincides give USER FATAL 5289 (bwb, grids 1024/1025 in two SPC1 entries). Fixed on the converter side (one constraint per grid, components merged) instead of in ADS.

## 8. Progress log
- 2026-10-04: exploration of Matran, baff, ADS, examples and QRG done; plan and decisions recorded.
- 2026-10-04 Phase 0: `.gitignore` gains the QRG PDF, `tools/qrg/out/`, `validation/results/`.
  `TestMatran` now loads without `../Matran_test_data` (h5 tests skipped by assumption), finds the local TPL in
  batch mode instead of opening `uigetdir`, and looks for classes in `tbx/+mni` (the old `tbx/matran/+mni`
  path no longer exists; `@class` folders handled). Baseline of the legacy micro tests (`obj_*`, `bulk_*`,
  `dynamicable_*`, `collector_*`): 8 pass, 10 error — pre-existing: constructing every class without arguments
  opens `uigetfile` in `mni.result.f06`/`hdf5` (not allowed in batch) and `CoordSystem.drawElement` fails on an
  empty object. Left as is (outside the validation scope); the new test suites do not depend on them.
- 2026-10-04 Phase 1: `tools/qrg/extract_qrg.py` (+ README). 913 bulk entries (811 with a Format grid), SOL table,
  242 case control commands, 387 parameters. Format grids are column-exact (word x-coordinates vs the `1..10`
  header); multi-line cells ("THETA or / MCID") merged; remark text inside Format tables (PBEAM) skipped;
  free-field / large-field illustrations kept apart. `--md` writes markitdown dumps for review.
- 2026-10-04 Phase 2 (import side): helpers `QrgSpec`, `MatranCards`, `QrgNames` (name rules + aliases),
  `QrgKnownGaps`, `nasNum`, `printFailures`; tests `TestQrgBulkLayout` (field positions, list start, coverage)
  and `TestQrgBulkExamples` (each QRG example imported with `mni.import_matran`, every stored value checked).
  First run: 23 layout failures, 18 example failures → fixes #1-#20 in §6. Now 164 pass, 0 fail
  (56 skipped by assumption: not a list entry / no example in the QRG).
- 2026-10-04 Phase 3 (full import):
  - `mni.io.readDeck`: NASTRAN / FMS / Executive / Case Control / Bulk sections (CEND, BEGIN BULK|SUPER,
    ENDDATA), INCLUDE expanded in place (multi-line quoted names, depth ≤ 10, relative to the including file,
    fallback for moved decks: bwb `sol101.bdf` absolute path resolves inside `Examples/`).
  - `mni.io.tokenizeBulk`: small / large / free field, `+`/`*`/blank/`,` continuations, long free-field lines,
    trailing-comma joins, replication (`=`, `==`, `*x`, `=n`), Nastran reals (`1.5-6`, `7.+1`, `1.0D2`) rewritten
    only for numeric fields (labels such as `AIL1-2` untouched). Reproduces every translation example of QRG ch.9.
  - `mni.io.parseExecControl` (SOL number/name with the QRG SOL table `mni.analysis.solTable`),
    `mni.io.parseCaseControl` (global + subcases with inheritance, 4-character abbreviations using the QRG
    command list `mni.analysis.caseCommands`, SET lists with THRU/BY/EXCEPT, OUTPUT blocks, PARAM).
  - `mni.analysis.buildInfo` → second output of `import_matran`: SOL, subcases, every Case Control selection
    resolved to the bulk entries it points to (following SPCADD/MPCADD/LOAD/DLOAD), PARAM/MDLPRM, table of every
    entry type (`Cards`: Count, Category model/load/constraint/solution/parameter, Class, Typed), summary text.
  - New classes: `Load` (FORCE, MOMENT, GRAV, LOAD), `Connector` (CBUSH with G0 form, PBUSH keyword lines,
    RJOINT), `AeroControl` (AESURF, AESTAT, AEPARM, AELINK), `DirectMatrix` (DMI with THRU / complex, DMIG),
    `GenericCard` (any other entry kept as text, nothing skipped); extended `Constraint` (SPCADD, SUPORT,
    SUPORT1), `AnalysisData` (TRIM, TRIM2, GUST, TSTEP, DIVERG, FREQ, MKAERO2; EIGRL/MKAERO1 blanks = NaN),
    `BeamProp` (PROD, PBARL, PBEAML + `mni.bulk.beamSection`), `CoordSystem` (CORD2C/S, CORD1R/C/S), CBAR/CBEAM
    G0 alternate format. Validators accept NaN for blank fields and negative integers (CID = -1 etc.).
  - Old reader helpers (`readCharDataFromFile`, `splitInputFile`, `extractParameters`, `extractIncludeFiles`)
    removed; `import_matran` passes no unknown option to `importH5` any more (it errored on ExpandInclude);
    `uigetfile` call fixed (`horczcat` typo).
  - Results: all four example decks import with every entry typed (bwb 8058 entries, 2 files; A320 SOL 144 / 103;
    semispan 5 files). SOL and selections: bwb SOL 101, 6 subcases, SPC=73 → SPCADD 73 → 28 SPC1, LOAD=76..81 →
    LOAD + GRAV 74 + FORCE/MOMENT; A320 SOL 144 TRIM=251 → TRIM2; SOL 103 METHOD=117 → EIGRL.
  - Tests: `TestQrgCustomCards` (PBUSH, PBEAML, PBARL, TRIM, TRIM2, AELINK, DMI real/complex/THRU, DMIG, G0 forms)
    12/12; `TestBdfReader` (format rules, replication, case / exec control, example decks) 7/7; layout + example
    suites over all classes 239 pass.
- 2026-10-04 Phase 4 (bdf → baff converter, `tbx/+mni/+baff`):
  - `mni.baff.fromFEModel(fem, info, 'Name', 'SpcSet', 'KeepFrames' (true), 'RigidStiffness' (1e8))`, also
    via `[fem, info, baffModel] = mni.import_matran(file, 'ToBaff', true, 'BaffOptions', {...})`;
    `info.Baff` = conversion report (Components table, Satellites, Notes, Dropped, AeroSettings, Loads, Spc,
    NodeMap, AeroMesh).
  - `mni.util.Geometry`: CORD1/2 R/C/S chains, grid positions in basic, `frame`, `toBasic`, `toLocal`,
    `vecToBasic`, `axesAt`, `dispFrame` (CD axes).
  - private: `collectModel` (materials with the MAT1 two-of-three rule, beams with v in basic incl. G0 / OFFT,
    sections at both ends, shells, RBE2/RBE3, joints, masses, SPC set of the first subcase via SPCADD, loads,
    aero), `aeroData` (AERO/AEROS, CAERO1 + AEFACT, splines, AESURF, AELINK, W2GJ, WKK), `analyseStructure`
    (beam chains, shell components, RBE3/RBE2 hubs, hinges from RJOINT/CBUSH, rigid clusters, satellites,
    dropped grids), `aeroStations` (CAERO1 → `baff.station.Aero`, control surfaces, AELINK).
  - Tree: root = most SPC'd component, then most elements; children attached via shared grids / rigid links /
    hinges with child.A = Rpᵀ·Rc, child.Offset = Rpᵀ·(Oc − X_locus(eta)) (global geometry reproduced exactly).
  - Results: bwb → 1 shell Wing (CP 102), 28 constraints; example_1 → 5 beams, 23 masses, 2 points;
    A320 → 4 beams (fuselage root, wing, tail, fin), 20 masses. Mass equal to the original in all three
    (after adding NSM support to baff / ADS, §7).
- 2026-10-04 Phase 5 (round trip harness, `tbx/+mni/+validation`, all new):
  - `roundTrip.m`: import + baff → `ads.baff.baff2fe` (BaffOpts SplitBeamsAtChildren=false,
    GenerateAeroPanels when the bdf has aero) → AERO/AEROS + ACSID frame + CAERO1 NSPAN/NCHORD re-applied from
    `info.Baff.AeroMesh` (matched by leading edge) → `UpdateIDs` + `Export` → `rt_model.bdf` → re-import (+ second
    baff conversion) → `compareModels` → Nastran → `report.md` in `validation/results/<Name>/` (gitignored).
    Nastran decks: `orig_bulk.bdf` (original bulk re-written by `writeBulk`, PARAM/MDLPRM/SUPORT* removed) and
    `rt_model.bdf`, each with the same PARAMs, `MDLPRM,HDF5,1`, `PARAM,GRDPNT,0`, `EIGRL,999901,,,NumModes+6`,
    `SPCADD 999902` (original: SIDs of the converted SPC set; round trip: SIDs of the ADS SPC1); SOL 101 only
    for constrained models: subcase 1 `GRAV 999903` (9.81, −z) + original subcases with LOAD (original LOAD id
    vs. FORCE/MOMENT/GRAV mapped in basic to the round trip grid at the same position).
  - `compareModels.m`: card counts; grids matched by position (unique, tol 1e-6·model size); SPC DoFs by
    position; CONM1/CONM2 mass; aero boxes (`private/caeroBoxes.m`: count, area, centroid distance, normals,
    W2GJ per box); beams per matched element (EA, EI1, EI2, GJ relative error, element y-axis dot product).
  - `runNastran.m` (cd to the deck folder, `scr=yes old=no news=no batch=no`, FATAL lines from the f06),
    `nastranExe.m` (ADS pref `ADS_Nastran/nastran_exe`, else newest
    `C:\Program Files\MSC.Software\MSC_Nastran\*\bin\nastran.exe`), `readGpwg.m` (GPWG mass, CG, I(S), I(Q), Q, S),
    `writeBulk.m` (fixed format; small field per logical line, large field only for fields > 8 characters and
    when no half line would be blank — Nastran drops an all-blank continuation line (QRG "Continuations",
    rule 5), which shifted the PBEAML DIMs; otherwise reals are rounded to 8 characters and counted).
  - Converter fixes found by the round trip:
    - wings keep their common CP only if it follows the wing convention (x span root → tip, y forward):
      ADS `AeroSurface.get_twists` derives the W2GJ sign from the wing frame (assumes x span / z up and flips
      when the tip has x < 0). example_1 kept CP 1 (x chordwise) → round trip W2GJ was −4° instead of +4°.
      Now note "CP n axes do not follow the wing convention; a derived frame is used".
    - `aeroStations` inverts the ADS CAERO1 placement exactly: ADS writes X1 = B + c(½ − BeamLoc)·v − c/2·x_aero
      with v the *twisted* chord direction (`baff.station.Aero.GetPos`), so eta / BeamLoc come from the closest
      approach of the line (flat mid-chord + t·v) to the locus, BeamLoc = ½ + t/c (3 fixed-point iterations
      with the locus direction). Twist per panel edge computed first (`i_panelTwist`); `i_chordDir` mirrors baff.
    - Residual for non-ADS decks with twist: the panel plane moves by c(½ − BeamLoc)·sin(twist) (example_1:
      0.0375·sin 4° = 2.6 mm on a 0.15 m chord) — inherent to the baff / ADS representation, reported as a note.
    - `AeroMesh` entries now also hold p4, c1, c4 (needed to re-apply NSPAN to ADS surfaces).
  - ADS observation (not changed): `beam2fe` writes a zero `FORCE` on every beam node (placeholder) → 109 FORCE
    entries in example_1's `rt_model.bdf`; harmless.
  - example_1 results (`validation/results/example_1/report.md`):
    - grids 147 original / 320 round trip, 104 matched, 7 ambiguous (coincident hinge grids), 0 unmatched,
      36 dropped by the conversion (outline / PLOTEL points, RBE2 311-321 dependents, RBE3 parts);
    - mass 2.8186 (baff = ADS = baff of the round trip); GPWG mass, CG and full inertia tensor identical to all
      printed digits (CONM2 offsets and inertia sign convention are right);
    - aero 550/550 boxes, area equal (0.196029), centroid shift ≤ 2.62 mm (residual above), W2GJ identical;
    - 98 beam elements matched: EA / EI1 / EI2 / GJ error ≤ 1e-13, y-axis dot 1.000000 (after the ADS fix);
    - SOL 103 (free-free, 6 rigid modes in both) — elastic frequencies [Hz]:

      | mode | original | original with RBE3 501-503 → RBE2 (the converter's approximation) | round trip |
      |---|---|---|---|
      | 1 | 7.653 | 7.622 | 7.782 |
      | 2 | 11.887 | 11.727 | 11.580 |
      | 3 | 20.079 | 19.505 | 19.076 |
      | 4 | 34.969 | 32.151 | 31.548 |
      | 5 | 47.804 | 45.015 | 40.665 |
      | 6 | 65.416 | 49.419 | 57.642 |

      Most of the gap comes from the RBE3 approximation: 0.63 kg of 2.82 kg sits on the RBE3 reference grids
      400/401/402 (CONM2 99/1099/1199, 100/1100/1200, 1001), each RBE3 spreading over 8 grids; the converter
      attaches the reference grid rigidly to the closest grid (203/212/215). A residual gap remains between the
      variant and the round trip (mode 5: 45.0 vs 40.7 Hz) → resolved 2026-10-05 (QRG #24).
    - SOL 101 skipped (no SPC in `model.bdf`).
- 2026-10-05 (session 2):
  - QRG suites re-run after #23: green.
  - example_1 gap: the first two bending modes were swapped crosswise (MAC 0.94) → `mni.bulk.beamSection` had
    I1 / I2 swapped (QRG figure axes are horizontal = z_elem). Proven with Nastran (cantilever, PBEAML vs PBEAM);
    BOX walls and H / CROSS widths also wrong (#24). After the fix the round trip equals the RBE3 → RBE2 variant
    within 0.07 % for all 10 elastic modes: the rest of the gap to the original is the RBE3 approximation alone.
    Tried: split the RBE3 reference-grid masses over the independent grids by weight (each part at the original
    position, GPWG still exact) → worse (modes 1–2 up, spurious local modes at 39–40 Hz, MAC drop from mode 5);
    reverted, rigid attach to the closest grid kept (note in `analyseStructure`).
  - bwb: `pdist` (Statistics Toolbox, not installed) replaced; duplicate SPC entries on one grid (two SPC1 of the
    set) gave two constraints → ADS RBE2s with one dependent grid twice (USER FATAL 5289) → one constraint per grid
    (components merged). Empty SPC sets handled.
  - A320: fuselage CAERO1 body plates (span across the fuselage beam, all at eta 0) crashed ADS (`discretize`):
    such panels are now dropped with a note (`report.DroppedCaero`, excluded from the aero comparison). Aero station
    etas within 1e-9 of 0 / 1 snapped (baff interpolation is strict). Aileron / elevator modelled as separate CAERO1
    behind the main panel: chordwise chains are merged into one strip (chord = whole chain, gap / overlap ≤ 5 % of
    the chord for rounded decks), hinge fraction from the strip chord (pChord aileron 0.30, elevator 0.40; was 1.0
    and a station with BeamLoc −0.29). PBEAM NSI carried to ADS (§7).
  - `TestQrgPrinting` (45 fixtures) found #25–#31; PCOMP import #32. Harness test `unit_testing/TestRoundTrip`
    (synthetic cantilever + kinked child, CONM2, SPC1, FORCE: conversion, model comparison, Nastran SOL 103/101).
  - Note: baff objects saved in a .mat (`save R`) come back with default property values — do not persist
    round trip results as .mat; re-run instead.

## 9. Final report (2026-10-05)

### Results (`validation/results/<Name>/report.md`, MSC Nastran 2023.2)
| Case | Model comparison | GPWG (mass, CG, inertia) | SOL 103 (10 elastic modes) | SOL 101 |
|---|---|---|---|---|
| bwb (shell wing, 2688 CQUAD4, SPC set 73, 6 load subcases) | 2454 grids matched + 28 root grids coincident with the ADS constraint grids, 0 missing; 81/81 SPC DoFs; aero area equal | identical | identical (max 1e-10 %, MAC 1.000) | gravity + 6 subcases identical (rel. error ≤ 2e-8) |
| example_2_a320 (CBEAM + PBEAM NSM/NSI, CBUSH/RJOINT joints, CONM2, aileron / elevator) | 101 beams: EA/EI/GJ exact, y axes exact; 160 fuselage body panels not converted (note) | identical | max 0.007 %, MAC 1.000 | – (free-free) |
| example_1 (PBEAML wing, folding tip hinge, RBE3 masses) | 98 beams exact, aero 550/550 boxes, W2GJ exact | identical | −0.4 / −1.3 / −2.9 / −8.1 / −5.8 / −24 % (modes 1–6); equals the RBE3→RBE2 variant within 0.07 %: residual = RBE3 approximation | – (no SPC) |

### Tests
`unit_testing/qrg`: TestQrgBulkLayout, TestQrgBulkExamples, TestQrgCustomCards, TestBdfReader, TestQrgPrinting;
`unit_testing/TestRoundTrip`: 354 pass, 0 fail, 108 skipped by assumption (QRG entries without an example / not a
list entry). Legacy `TestMatran` micro tests unchanged (8 pass, 10 pre-existing errors, see Phase 0).

### Re-run
```matlab
addpath('tbx');   % the mpm dev collection puts ads / baff on the path
R = mni.validation.roundTrip('Examples/example_1_semispan_model/data/model.bdf', 'Name', 'example_1');
R = mni.validation.roundTrip('Examples/bwb/bwbID_tp3911f223_6fd0_4693_81b0_96ba940d62e5/Source/sol101.bdf', 'Name', 'bwb');
R = mni.validation.roundTrip('Examples/example_2_a320/data/NastranHeaderFile.dat', 'Name', 'example_2_a320');
% 'RunNastran', false for the model comparison only
```

### Known limitations (approximated and reported by the converter)
- RBE3 that is not a shell rib hub: reference grid attached rigidly to the closest independent grid (example_1).
- CAERO1 panels spanning across a component (fuselage body plates) are not converted; non-uniform LSPAN / LCHORD
  written as uniform NSPAN / NCHORD; control-surface hinge line must be a constant chord fraction (mean used).
- PBEAML / PBARL: J is an approximation (≤ 2.5 % for ROD…CHAN, 6 % BOX, 8 % CROSS, 23 % H); Nastran's own shear /
  warping terms are not kept. CBEAM offsets WA / WB are not carried (note).
- Loads, SPC set selection, AERO / AEROS and panel discretisation stay in `info` / the conversion report; the
  harness re-applies them.
- ADS: `BeamSection` needs A, I1, I2 > 0 (PROD / CROD fail); left-wing W2GJ sign in `get_twists` depends on the
  frame (converter keeps a CP only if it follows the wing convention); a constraint whose closest attachment grid
  is already dependent still fails in ADS (converter avoids the duplicate-SPC case).
- MAT8 HFAIL / HTAPE / HFABR keyword lines not imported (#21, by design).

Nothing is committed (Matran, baff and ADS working trees; baff / ADS also hold unrelated WIP).
