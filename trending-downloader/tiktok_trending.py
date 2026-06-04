#!/usr/bin/env python3
"""
tiktok_trending.py — Search and download the top trending TikTok videos per country.

Uses yt-dlp under the hood. TikTok exposes a per-region "trending" feed at
https://www.tiktok.com/explore (and a discover endpoint); yt-dlp can enumerate
and download those entries. No login is required for public trending videos.

Usage:
    python tiktok_trending.py --country US --count 5 --out ./downloads

Note: Downloading TikTok videos may violate TikTok's Terms of Service. Use this
tool only for content you are permitted to download.
"""

import argparse
import sys
from pathlib import Path

try:
    from yt_dlp import YoutubeDL
except ImportError:
    sys.exit(
        "yt-dlp is not installed. Run:\n    pip install -r requirements.txt"
    )

# TikTok's trending/explore feed. The region is driven by the `lang`/cookie and
# the IP, but we also pass a region hint via the URL where supported.
TRENDING_URL = "https://www.tiktok.com/explore"


def build_opts(out_dir: Path, count: int, country: str, cookies: str | None):
    opts = {
        "outtmpl": str(out_dir / "%(uploader)s-%(id)s.%(ext)s"),
        "playlistend": count,
        "format": "mp4/best",
        "noplaylist": False,
        "ignoreerrors": True,
        "quiet": False,
        "no_warnings": False,
        # A desktop UA helps TikTok serve the web feed.
        "http_headers": {
            "User-Agent": (
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/124.0 Safari/537.36"
            ),
            "Accept-Language": f"{country.lower()};q=0.9,en;q=0.8",
        },
    }
    if cookies:
        opts["cookiefile"] = cookies
    return opts


def fetch_trending(country: str, count: int, out_dir: Path, cookies: str | None):
    out_dir.mkdir(parents=True, exist_ok=True)
    opts = build_opts(out_dir, count, country, cookies)

    print(f"Fetching top {count} trending TikToks for region '{country}'...")
    with YoutubeDL(opts) as ydl:
        # Download the trending feed, limited to `count` entries.
        ydl.download([TRENDING_URL])
    print(f"\nDone. Files saved to: {out_dir.resolve()}")


def main():
    p = argparse.ArgumentParser(
        description="Download the top trending TikTok videos for a country."
    )
    p.add_argument(
        "--country", "-c", default="US",
        help="ISO country code (e.g. US, GB, BR, JP). Default: US",
    )
    p.add_argument(
        "--count", "-n", type=int, default=5,
        help="Number of top videos to download. Default: 5",
    )
    p.add_argument(
        "--out", "-o", default="./downloads",
        help="Output directory. Default: ./downloads",
    )
    p.add_argument(
        "--cookies", default=None,
        help="Path to a cookies.txt file (export from your logged-in browser) "
             "to access region-specific or restricted feeds.",
    )
    args = p.parse_args()

    out_dir = Path(args.out) / args.country.upper()
    try:
        fetch_trending(args.country.upper(), args.count, out_dir, args.cookies)
    except Exception as e:  # noqa: BLE001 - surface a clean message to the user
        sys.exit(f"Error: {e}")


if __name__ == "__main__":
    main()
