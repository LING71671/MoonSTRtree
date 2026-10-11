"""Fetch pinned public CSV snapshots using only the Python standard library."""
from concurrent.futures import ThreadPoolExecutor
import csv
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import struct
from urllib.request import Request, urlopen

PLAYGROUND = Path(__file__).resolve().parents[2]
CATALOG = json.loads(Path(__file__).with_name("sources.json").read_text(encoding="utf-8"))
CACHE = PLAYGROUND / ".bench" / "datasets"


def coordinate(row, longitude, latitude):
    try:
        x, y = float(row[longitude]), float(row[latitude])
    except (ValueError, KeyError):
        return None
    return (x, y) if math.isfinite(x) and math.isfinite(y) and -180 <= x <= 180 and -90 <= y <= 90 else None


def fetch(source):
    CACHE.mkdir(parents=True, exist_ok=True)
    raw = CACHE / f"{source['id']}.csv"
    metadata_path = CACHE / f"{source['id']}.json"
    retrieved = datetime.now(timezone.utc).isoformat()
    if raw.exists() and metadata_path.exists():
        retrieved = json.loads(metadata_path.read_text(encoding="utf-8"))["retrievedAt"]
    if not raw.exists():
        with urlopen(Request(source["url"], headers={"User-Agent": "MoonSTRtree-reproducible-benchmark"}), timeout=90) as response:
            raw.write_bytes(response.read())
    raw_sha256 = hashlib.sha256(raw.read_bytes()).hexdigest()
    if raw_sha256 != source["sha256"]:
        raise ValueError(f"{raw}: SHA-256 differs from the pinned public snapshot")
    output = CACHE / f"{source['id']}.f64"
    records = skipped = total = 0
    ids = []
    with raw.open(encoding="utf-8-sig", newline="") as text, output.open("wb") as binary:
        for row in csv.DictReader(text):
            total += 1
            if source["kind"] == "points":
                start = coordinate(row, "longitude_deg", "latitude_deg")
                end = start
            else:
                start = coordinate(row, "le_longitude_deg", "le_latitude_deg")
                end = coordinate(row, "he_longitude_deg", "he_latitude_deg")
            if start is None or end is None:
                skipped += 1
                continue
            x1, y1 = start
            x2, y2 = end
            binary.write(struct.pack("<dddd", min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2)))
            ids.append(row["id"])
            records += 1
    source_ids = CACHE / f"{source['id']}.ids.json"
    source_ids.write_text(json.dumps(ids), encoding="utf-8")
    metadata = {
        **source, "retrievedAt": retrieved, "preparedAt": datetime.now(timezone.utc).isoformat(),
        "totalRows": total, "records": records, "excludedRows": skipped,
        "rawSha256": raw_sha256,
        "coordinatesSha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        "format": "little-endian Float64 [minX, minY, maxX, maxY] per record",
        "sourceIdsFile": source_ids.name,
    }
    metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"dataset": source["id"], "records": records, "excludedRows": skipped, "rawSha256": metadata["rawSha256"]}), flush=True)


if __name__ == "__main__":
    with ThreadPoolExecutor(max_workers=2) as pool:
        list(pool.map(fetch, CATALOG["sources"]))
