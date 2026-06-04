#!/usr/bin/env python3
"""
tiktok_trending.py — Download the top trending TikTok videos per country.

Source: TikTok **Creative Center** (ads.tiktok.com), which publishes an official
"Top Trending Videos" list with a real per-country selector and requires no
login. We query its public creative_radar API, take the top N entries for the
chosen country, then download each video as MP4 with yt-dlp.

Usage:
    python tiktok_trending.py --country US --count 5 --out ./downloads
    python tiktok_trending.py --country BR --period 30 --list-only

Note: Downloading TikTok videos may violate TikTok's Terms of Service. Use this
tool only for content you are permitted to download.
"""

import argparse
import sys
from pathlib import Path

try:
    import requests
except ImportError:
    sys.exit("requests is not installed. Run:\n    pip install -r requirements.txt")

try:
    from yt_dlp import YoutubeDL
except ImportError:
    sys.exit("yt-dlp is not installed. Run:\n    pip install -r requirements.txt")

# Creative Center public endpoint for trending creator videos.
CC_API = "https://ads.tiktok.com/creative_radar_api/v1/popular_trend/video/list"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    ),
    "Accept": "application/json, text/plain, */*",
    "Referer": "https://ads.tiktok.com/business/creativecenter/inspiration/popular/pc/en",
    # Creative Center reads the locale from this header.
    "web-id": "0",
}


def _params(country: str, count: int, period: int) -> dict:
    return {
        "period": period,          # 7, 30, or 120 days
        "page": 1,
        "limit": max(count, 10),   # over-fetch a little; we trim later
        "order_by": "vv",          # by views = "top"
        "country_code": country.upper(),
    }


def _extract_videos(payload: dict) -> list[dict]:
    return (payload.get("data") or {}).get("videos") or []


def fetch_via_requests(country: str, count: int, period: int) -> list[dict]:
    """Direct API call. Fast, but TikTok often answers 403 without a signed
    request — in that case the caller falls back to the browser path."""
    resp = requests.get(CC_API, headers=HEADERS,
                        params=_params(country, count, period), timeout=30)
    resp.raise_for_status()
    return _extract_videos(resp.json())[:count]


def fetch_via_browser(country: str, count: int, period: int) -> list[dict]:
    """Drive Creative Center in a headless browser so TikTok's own JS signs the
    XHR; we capture the trending JSON straight off the network response."""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        raise RuntimeError(
            "Browser fetch needs Playwright:\n"
            "    pip install playwright && playwright install chromium"
        )

    page_url = ("https://ads.tiktok.com/business/creativecenter/inspiration/"
                f"popular/pc/en?countryCode={country.upper()}&period={period}")
    captured: list[dict] = []

    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=True)
        ctx = browser.new_context(user_agent=HEADERS["User-Agent"])
        page = ctx.new_page()

        def on_response(resp):
            if "popular_trend/video/list" in resp.url and resp.ok:
                try:
                    captured.extend(_extract_videos(resp.json()))
                except Exception:
                    pass

        page.on("response", on_response)
        page.goto(page_url, wait_until="networkidle", timeout=60_000)
        # Give late XHRs a moment to land.
        page.wait_for_timeout(3_000)
        browser.close()

    if not captured:
        raise RuntimeError("Browser loaded but no trending data was captured.")
    return captured[:count]


def fetch_trending_list(country: str, count: int, period: int,
                        use_browser: bool) -> list[dict]:
    """Return up to `count` trending video records for `country`."""
    videos: list[dict] = []
    if not use_browser:
        try:
            videos = fetch_via_requests(country, count, period)
        except Exception as e:  # noqa: BLE001
            print(f"  direct API failed ({e}); falling back to browser...")
    if not videos:
        videos = fetch_via_browser(country, count, period)

    if not videos:
        raise RuntimeError(
            f"No trending videos returned for '{country}'. "
            "The country code may be unsupported or the API response changed."
        )
    return videos[:count]


def to_url(video: dict) -> str | None:
    """Build a canonical tiktok.com video URL from a Creative Center record."""
    # Creative Center records carry the numeric video id under a few keys.
    vid = video.get("id") or video.get("item_id") or video.get("tiktok_id")
    author = video.get("username") or video.get("author") or "_"
    if not vid:
        return None
    return f"https://www.tiktok.com/@{author}/video/{vid}"


def download(urls: list[str], out_dir: Path, cookies: str | None):
    out_dir.mkdir(parents=True, exist_ok=True)
    opts = {
        "outtmpl": str(out_dir / "%(uploader)s-%(id)s.%(ext)s"),
        "format": "mp4/best",
        "ignoreerrors": True,
        "quiet": False,
        "http_headers": {"User-Agent": HEADERS["User-Agent"]},
    }
    if cookies:
        opts["cookiefile"] = cookies
    with YoutubeDL(opts) as ydl:
        ydl.download(urls)


def main():
    p = argparse.ArgumentParser(
        description="Download the top trending TikTok videos for a country "
                    "(via TikTok Creative Center)."
    )
    p.add_argument("--country", "-c", default="US",
                   help="ISO country code (US, GB, BR, JP, …). Default: US")
    p.add_argument("--count", "-n", type=int, default=5,
                   help="Number of top videos. Default: 5")
    p.add_argument("--period", type=int, choices=[7, 30, 120], default=7,
                   help="Trending window in days: 7, 30, or 120. Default: 7")
    p.add_argument("--out", "-o", default="./downloads",
                   help="Output directory. Default: ./downloads")
    p.add_argument("--cookies", default=None,
                   help="Path to cookies.txt for region-locked downloads.")
    p.add_argument("--list-only", action="store_true",
                   help="Only print the trending URLs; do not download.")
    p.add_argument("--browser", action="store_true",
                   help="Force the headless-browser fetch (needed when the "
                        "direct API returns 403). Requires Playwright.")
    args = p.parse_args()

    country = args.country.upper()
    try:
        videos = fetch_trending_list(country, args.count, args.period,
                                     use_browser=args.browser)
    except Exception as e:  # noqa: BLE001
        sys.exit(f"Error fetching trending list: {e}")

    urls = [u for u in (to_url(v) for v in videos) if u]
    if not urls:
        sys.exit("Could not derive any video URLs from the trending data.")

    print(f"Top {len(urls)} trending TikToks for {country} (last {args.period}d):")
    for i, u in enumerate(urls, 1):
        print(f"  {i}. {u}")

    if args.list_only:
        return

    out_dir = Path(args.out) / country
    print(f"\nDownloading to {out_dir.resolve()} ...")
    try:
        download(urls, out_dir, args.cookies)
    except Exception as e:  # noqa: BLE001
        sys.exit(f"Error during download: {e}")
    print("\nDone.")


if __name__ == "__main__":
    main()
