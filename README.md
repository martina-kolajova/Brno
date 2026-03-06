<img src="WastedBrno/Assets.xcassets/AppIcon.appiconset/4.png" width="60" align="left" style="margin-right: 12px" />

# Wasted Brno

> *Aplikace pro hledání kontejnerů na tříděný odpad v Brně.*

An iOS app for locating waste separation containers across Brno, Czech Republic. Built with SwiftUI and MapKit — find the nearest recycling station for paper, plastic, glass, textiles, or bio-waste and navigate there on foot.

---

## Features

- **Interactive map** — live Apple Maps view of all 1 000+ container stations in Brno
- **Filter by waste type** — show only stations relevant to you (paper, plastic, glass, textiles, bio-waste)
- **Find nearest** — one-tap quick navigation to the closest matching station from your current location
- **Walking directions** — animated dashed route line with distance and estimated travel time
- **Address search** — type any Brno street and search from that point instead of your GPS
- **Waste statistics** — orloj-inspired chart showing container counts by category

---

## Requirements

| | Minimum |
|---|---|
| iOS | 17.0 |
| Xcode | 15.0 |
| Swift | 5.9 |

No third-party dependencies — only Apple frameworks (SwiftUI, MapKit, CoreLocation).

---

---

## Getting Started
```bash
git clone https://github.com/martina-kolajova/Brno.git
cd Brno
open "Wasted Brno.xcodeproj"
```

No API keys or config files needed. Data is fetched from the public Brno open-data endpoint.

> **Note:** Location features work best on a physical device or with a simulated location set to Brno (49.1951° N, 16.6068° E). A `Brno.gpx` file is included in the repo for simulator testing.

---

## Architecture

MVVM with a clear separation between data, logic, and UI.


**Notable implementation details:**
- Stations are filtered off the main thread via `Task.detached`, debounced at 100 ms, capped at 200 visible pins
- All API pages are fetched concurrently with `withThrowingTaskGroup` and merged in a single pass
- Route dash animation is driven by a `Timer` since MapKit polylines don't support SwiftUI animations

---

## Data Source

Container locations come from the City of Brno ArcGIS open-data service. The API is queried with paginated GeoJSON requests (1 000 features per page). Stations are grouped by `stanoviste_ogc_fid` so multiple container types at the same physical location appear as a single map pin.

---

## Waste Categories

| Category | Raw value | Container colour |
|----------|-----------|-----------------|
| Paper | `papir` | Blue |
| Plastic, metals & cartons | `plast` | Yellow |
| Glass | `sklo` | Green |
| Textiles | `textil` | Grey |
| Bio-waste | `bioodpad` | Brown |

Recycling hints and educational facts for each category are bundled in `WasteKindData.json`.

---

## Author

Martina Kolajová — 2026

---

## License

MIT
