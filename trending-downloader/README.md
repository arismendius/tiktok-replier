# TikTok Trending Downloader

A simple CLI that finds and downloads the **top trending TikTok videos per
country**, using TikTok's official **Creative Center** "Top Trending Videos"
list (real country selector, no account login needed) and
[yt-dlp](https://github.com/yt-dlp/yt-dlp) for the actual downloads.

## Install

```bash
cd trending-downloader
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
playwright install chromium   # enables the browser fetch (recommended)
```

## Usage

```bash
# Top 5 trending in the US into ./downloads/US
python tiktok_trending.py

# Top 5 trending in Brazil, last 30 days, browser fetch
python tiktok_trending.py --country BR --period 30 --browser

# Just see the list, don't download
python tiktok_trending.py --country JP --list-only
```

| Flag | Default | Description |
|------|---------|-------------|
| `--country`, `-c` | `US` | ISO country code (US, GB, BR, JP, …) |
| `--count`, `-n` | `5` | Number of top videos |
| `--period` | `7` | Trending window in days: `7`, `30`, or `120` |
| `--out`, `-o` | `./downloads` | Output dir (a `<COUNTRY>` subfolder is created) |
| `--browser` | off | Force headless-browser fetch (needs Playwright) |
| `--cookies` | — | `cookies.txt` for region-locked downloads |
| `--list-only` | off | Print URLs only, skip downloading |

## How it works

1. **Fetch the list** — queries Creative Center's `popular_trend/video/list`
   for the chosen country, period and `order_by=vv` (views = "top").
   - It first tries a direct API call. TikTok usually answers **403** unless
     the request is signed by its anti-bot JS, so the tool **falls back to a
     headless browser** (Playwright) that loads the real page and captures the
     signed JSON response. Use `--browser` to skip straight to that path.
2. **Resolve URLs** — each record is turned into a `tiktok.com/@user/video/<id>`
   link.
3. **Download** — yt-dlp saves each as `<uploader>-<id>.mp4`.

## ⚠️ Important notes

- **This was not live-verified in the build environment.** TikTok blocks
  datacenter IPs — every request from the CI/cloud container returned 403,
  including `tiktok.com` itself. Run this on a normal (residential) network
  where TikTok is reachable. The `--browser` path is what makes it work there.
- **"Login"**: public trending data needs no login. Use `--cookies` (export
  with a *Get cookies.txt* browser extension) only for region-locked downloads.
- **Legal**: TikTok has no official API for downloading videos, and doing so may
  violate TikTok's Terms of Service. Use only for content you have the right to
  download, at your own risk.
