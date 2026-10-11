---
name: MoonSTRtree playground
description: A black-and-white bench for inspecting spatial queries and measured comparisons.
colors:
  query-white: "#ffffff"
  action-hover: "#f0f0f0"
  reading-white: "#f5f5f5"
  page-black: "#080808"
  instrument-panel: "#141414"
  field-dark: "#101010"
  control-surface: "#1b1b1b"
  muted-gray: "#b8b8b8"
  divider: "#3d3d3d"
  retained: "#f0f0f0"
  rejected: "#a8a8a8"
  packed-node: "#b2b2b2"
  hit: "#dddddd"
typography:
  display:
    fontFamily: '"Barlow Condensed", sans-serif'
    fontSize: "64px"
    fontWeight: 600
    lineHeight: 1.02
    letterSpacing: "-0.02em"
  headline:
    fontFamily: '"Barlow Condensed", sans-serif'
    fontSize: "58px"
    fontWeight: 600
    lineHeight: 0.97
    letterSpacing: "-0.02em"
  display-zh:
    fontFamily: '"Noto Sans SC Variable", sans-serif'
    fontSize: "48px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.02em"
  headline-zh:
    fontFamily: '"Noto Sans SC Variable", sans-serif'
    fontSize: "40px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.02em"
  title:
    fontFamily: '"Manrope Variable", sans-serif'
    fontSize: "16px"
    fontWeight: 650
  body:
    fontFamily: '"Manrope Variable", sans-serif'
    fontSize: "13px"
    fontWeight: 450
    lineHeight: 1.65
  body-zh:
    fontFamily: '"Noto Sans SC Variable", sans-serif'
    fontSize: "13px"
    fontWeight: 450
    lineHeight: 1.65
  label:
    fontFamily: '"Manrope Variable", sans-serif'
    fontSize: "11px"
    fontWeight: 450
  measurement:
    fontFamily: "ui-monospace, monospace"
    fontSize: "16px"
rounded:
  field: "2px"
spacing:
  compact: "12px"
  control: "18px"
  inset: "20px"
  section-inset: "24px"
components:
  button-primary:
    backgroundColor: "{colors.query-white}"
    textColor: "#111111"
    padding: "12px 18px"
  button-primary-hover:
    backgroundColor: "{colors.action-hover}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.reading-white}"
    padding: "9px 16px"
  button-text:
    backgroundColor: "transparent"
    textColor: "#e2e2e2"
    padding: "0"
  input-number:
    backgroundColor: "{colors.control-surface}"
    textColor: "{colors.reading-white}"
    rounded: "{rounded.field}"
    padding: "9px 12px"
  navigation:
    textColor: "{colors.reading-white}"
  language-button:
    backgroundColor: "transparent"
    textColor: "{colors.muted-gray}"
    padding: "4px 9px"
  language-button-selected:
    textColor: "#ededed"
  query-tab:
    backgroundColor: "transparent"
    textColor: "{colors.muted-gray}"
    padding: "13px 0 12px"
  query-tab-selected:
    textColor: "#eeeeee"
  experiment-panel:
    backgroundColor: "{colors.instrument-panel}"
    textColor: "{colors.reading-white}"
---

[English](DESIGN.md) | [Chinese edition](docs/zh/DESIGN.md)

# Design System: MoonSTRtree playground

## Overview

**Creative North Star: "Spatial experiment bench"**

The implemented world is a black-and-white instrument bench with white query geometry and clear grayscale type. A plotted field, square controls and a ruled measurement ledger carry the interface. Dense technical detail remains subordinate to the query and its results.

English condensed display type establishes strong section hierarchy; Manrope supplies English controls and reading text. Chinese uses Noto Sans SC with its own heading scale and line height. Both editions use complete, natural explanations of the query, comparison and limitations. Flat surfaces and fine divisions keep the visual character practical. The artifact uses live canvas geometry and self-hosted fonts; no raster illustration is shipped by this surface.

This is a source-recorded GitHub checkpoint, not the final reviewed showcase. The user's confirmed monochrome direction in [the surface contract](.impeccable/surfaces/playground-src-app-tsx.md) controls this record. Source evidence includes [the stylesheet](playground/src/style.css), [the application](playground/src/App.tsx), [the canvas](playground/src/components/SpatialCanvas.tsx), [the ledger](playground/src/components/BenchmarkLedger.tsx), [the volume experiment](playground/src/components/VolumeExperiment.tsx), [its side view](playground/src/components/VolumeSideView.tsx), and [the locale provider](playground/src/i18n/LocaleProvider.tsx). No new screenshots have been captured for the monochrome or volume changes. Earlier bilingual captures do not cover this checkpoint. Final visual review, benchmark charts and GitHub Pages remain unfinished; no whole-surface pass is recorded.

**Key Characteristics:**

- Matte tonal surfaces and fine ruled boundaries.
- White query and action emphasis with line styles and grayscale structural states.
- Locale-aware headlines, readable controls and aligned numerical evidence.
- A responsive field and ledger that stack on mobile.

## Colors

The implemented palette uses only black, white and neutral grays. Frontmatter values come from source; the sidecar's grayscale preview ramps are not additional shipped tokens.

### Primary

- **Query White:** query outlines, handles, measurement action, focus rings, selection and native control accents. **Action Hover:** the enabled primary action's off-white hover state.

### Neutral

- **Page Black:** page background. **Instrument Panel:** experiment and ledger. **Field Dark:** both query canvases. **Control Surface:** native select and number fields.
- **Reading White:** reading text. **Muted Gray:** metadata and labels. **Divider:** panel boundaries and row rules.
- **Retained White:** solid rectangle audit bounds. **Rejected Gray:** dashed rejected bounds. **Packed Node Gray:** static topology. **Hit Gray:** matching 2D objects; the volume side view fills hits white.

**The Geometry Meaning Rule.** White identifies query geometry; line style, weight and labels distinguish retained and rejected rectangle audit states. Preserve the legend and the solid/dashed distinction.

## Typography

**Display Font:** Barlow Condensed, sans-serif fallback; self-hosted weight 600.

**Body Font:** Manrope Variable, sans-serif fallback; self-hosted variable font, default weight 450.

**Chinese Font:** Noto Sans SC Variable, sans-serif fallback; self-hosted for Chinese headings, controls and reading text. Chinese headings use weight 600 and line height 1.25.

**Label/Mono Font:** Manrope in English and Noto Sans SC in Chinese for controls; ui-monospace, monospace for timing values and canvas axis annotation in both languages.

**Character:** Narrow English headlines and balanced Chinese headings provide distinct but compatible hierarchy. Reading type and tabular numerals keep evidence legible; complete explanatory copy can wrap naturally.

### Hierarchy

- **Display:** English uses the frontmatter display role and (44px) on mobile, with line height (1.02) and maximum measure (23ch), then (20ch). Chinese uses the display-zh role and (34px) on mobile, with maximum measure (18em).
- **Headline:** English evidence headings use the headline role and (44px) on mobile; Chinese uses headline-zh and (30px). Method headings are English (46px / 38px) and Chinese (34px / 28px), desktop/mobile respectively.
- **Title:** reading titles use (16px / 650) in each locale's reading font. Ledger headings are English (36px / 34px) and Chinese (27px / 25px); ledger row names are (14px / 15px), desktop/mobile respectively.
- **Body:** methodology paragraphs use the body or body-zh role and a maximum (65ch) measure. Introductory copy is (15px), then (13px) on mobile, with maximum (65ch); evidence copy is (14px), then (13px).
- **Label and measurement:** controls use the frontmatter label role. Supporting ledger text is (10px), then (11px) on mobile. Timings use the measurement role with tabular numerals and four decimals.

**The Numerical Alignment Rule.** Keep measured values monospaced and tabular; retain units and the distinction between ingest/build observations and query timings.

## Layout

The centered shell has a maximum width (1640px), desktop side padding (44px) and a ruled header. The experiment is one contiguous panel: dataset controls, query field and ledger, then an evidence footer. The default workbench grid is a flexible field plus a fixed ledger (326px). At widths of at least (1500px), the ledger becomes (350px) and the canvas height becomes (510px), rather than the default (470px).

At widths up to (1100px), shell padding becomes (24px), the ledger becomes (300px), canvas height becomes (450px), and field summaries stack. At widths up to (760px), shell padding becomes (18px), dataset controls form two columns, and field and ledger stack in reading order. Canvas height is (370px); tabs distribute across the available width. The introductory and methodology layouts become single columns.

The capability comparison retains its minimum table width (660px) inside a horizontally scrolling region. Mobile does not remove the competitor columns: they remain reachable by scrolling. Mobile header navigation wraps within (155px), its in-page evidence link is hidden, and language controls occupy a separate right-aligned row. Desktop section gaps are generous (72–76px); mobile gaps reduce to (48–52px), while data controls and ledger rows stay compact. The runtime note wraps within (280px) on desktop and releases that maximum on mobile; longer bilingual text determines page height.

## Elevation & Depth

No box shadows are implemented. Depth comes from a darker canvas, a slightly lighter panel and fields, thin borders, and translucent canvas annotations/loading coverage. Hover changes color rather than lifting components.

**The Flat Instrument Rule.** Preserve tonal layering and ruled separation; the recorded components do not use shadows or hover translation.

## Shapes

Panels, actions and geometry have square forms. Native select and number fields use the frontmatter's small field radius. Panel and row separators are (1px); the active query underline and focus outline are (2px). Query corners and segment endpoints use small square handles (6px). There is no pill, chip or rounded card vocabulary in this implementation.

## Components

### Buttons

Actions are firm and compact. The primary action uses white with dark text, weight (750), size (13px), and the frontmatter padding. Its enabled hover uses Action Hover. The secondary action is transparent with a gray structural border and dark gray hover. The text action is light gray and underlined. Buttons have a minimum height (42px); disabled buttons reduce opacity to (0.45) and use the default cursor.

Keyboard focus uses a white outline (2px) with offset (5px) on buttons, links, inputs, selects and canvas. Button color transitions take (160ms ease-out). Reduced-motion preferences remove these transitions and smooth page scrolling.

### Cards / Containers

The experiment is a single bordered container with internal divisions; the ledger shares its surface. No independent card grid is present. Controls use an inset (20px 24px) on desktop and (16px) on mobile; ledger padding is (23px 22px), then (22px 18px) on mobile.

### Inputs / Fields

Selects and number fields have a dark tonal fill, warm text and muted border. Hover brightens the border; focus uses the shared outline. Native checkbox/range accents and text carets are white. Local field controls are denser, with height (36px), padding (6px 8px) and size (11px). Dataset fields retain height (42px). Labels remain attached above or beside controls.

Draft configuration differs visibly from the applied field through the pending-changes status and “Apply & build” action. Measurement is disabled until the dataset exists, supported answers agree, no measurement is running, and no draft changes remain. Initial packing has an overlay; engine errors have an alert and retry action. During measurement the top button displays progress. Export enables only after a completed comparison.

### Navigation

Project navigation is plain text (13px) with no enclosing pills. Hover uses white and focus uses the shared outline. The Chinese and EN language buttons have minimum height (32px), padding (4px 9px), size (11px), and a light gray text/border selected state. Hover adds a dark gray fill. Query modes are buttons with pressed state, muted default text, a light gray active label and white underline. They remain visible on mobile.

Chinese is the initial language unless an English choice was saved under localStorage key `moon-strtree:locale`. Switching changes visible copy, number formatting, page language/title/description and locale-specific documentation links. The choice persists when storage is available; switching still works if storage is blocked. Locale state lives above the experiment, so changing language preserves the dataset, query, draft configuration, tree display and existing measurement. The EN/Chinese dictionaries provide complete explanatory copy rather than compressed slogans.

### Spatial field and bounds audit

The canvas plots a (0–1000) field. Pointer input creates or places query geometry; arrow keys move it by (10 units), or (40 units) with Shift. The geometry is clamped inside the field. A tree-depth control and object toggle govern visible structure.

For rectangle queries, a separate compiled MoonBit bounds audit supplies solid white retained and dashed gray rejected nodes at the selected depth. The footer states the counts and explicitly identifies this as an untimed bounds audit. It does not show timed traversal telemetry. Point, nearest, radius and segment modes show static node topology; the footer states this limit. Radius and neighbor controls appear only for their corresponding modes.

### Benchmark ledger

Four ruled rows show MoonSTRtree, Flatbush, RBush and a linear scan. A Worker executes real indexes on the same synthetic bounds; complete answers are checked against the independent scan outside timing. Nearest-neighbor validation compares the full distance sequence, allowing tied IDs to differ; RBush's nearest path is not included because the add-on is absent.

Untimed rows show a dash rather than fabricated timing. Rows distinguish checking, matching, mismatch and unsupported states; mismatch text has a warm warning color. A measurement uses five warmups followed by nine rotating batches of 32 queries and reports the median. The fastest valid row may be a competitor; the statement stays visible when MoonSTRtree loses. Build values are single ingest/build observations. Exports contain samples, query, versions and environment information. The comparison ledger measures browser JS 2D queries; it establishes no general speed, memory, native, 3D or 4D performance promise.

### Volume experiment and side view

The new section provides real 3D range queries using a selectable height interval, and 4D time-slice queries using that interval plus a time position. A separate Worker calls the compiled MoonBit 3D/4D APIs and compares complete sorted hit-ID arrays with an independent exhaustive scan. Both planes show the same hits: the interactive top view projects X/Y; the non-interactive side view projects X/height with height increasing upward. White query outlines and filled hits stand against gray objects. The displayed planes do not supply multidimensional traversal telemetry.

Controls offer 3D/4D, 1,000/10,000 synthetic objects, lower/upper height and, in 4D, a time slider. The current generator fixes seed 42 and capacity 16; coordinates use synthetic dimensionless units. Building, checking, validated/mismatch and retry states remain explicit. A result table previews the first ten hit IDs with height bounds and, in 4D, time bounds. Export is enabled only for a validated result and includes every matching ID and its complete 3D/4D bounds, query, validation state and package metadata. This is query/correctness evidence, not a multidimensional performance ranking.

The volume section uses ruled separation, padding (64px), two equal view columns with gap (24px), and canvas aspect ratio (1.3). At widths up to (680px), padding becomes (40px), views stack, control gaps become (16px) and the result strip stacks. Its English heading is (48px / 36px) and Chinese heading (36px / 28px), desktop/mobile respectively; Chinese line height is (1.3). Locale changes preserve the volume Worker, selected dimension, query and result.

## Do's and Don'ts

### Do:

- **Do** preserve white query/action meaning and solid/dashed audit distinctions.
- **Do** keep synthetic-data labels, checking states, unsupported paths and measured losses visible.
- **Do** retain the stacked mobile reading order and horizontal capability-table access.
- **Do** respect the shared keyboard focus and reduced-motion behavior.
- **Do** preserve both complete language editions and experiment state when switching language.

### Don't:

- **Don't** describe the rectangle bounds audit as timed traversal telemetry or imply pruning traces in other modes.
- **Don't** turn one browser query's timings into a universal ranking.
- **Don't** replace the observed flat, square instrument vocabulary with floating cards or pill navigation.
