# TikTok Trending Downloader

A simple CLI that fetches and downloads the top trending TikTok videos for a
given country. Built on [yt-dlp](https://github.com/yt-dlp/yt-dlp).

## Install

```bash
cd trending-downloader
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

## Usage

```bash
# Top 5 trending in the US (default) into ./downloads/US
python tiktok_trending.py

# Top 5 trending in Brazil into a custom folder
python tiktok_trending.py --country BR --count 5 --out ./videos

# Use logged-in cookies for region-locked / restricted feeds
python tiktok_trending.py --country JP --cookies cookies.txt
```

| Flag | Default | Description |
|------|---------|-------------|
| `--country`, `-c` | `US` | ISO country code (US, GB, BR, JP, …) |
| `--count`, `-n` | `5` | Number of top videos to download |
| `--out`, `-o` | `./downloads` | Output directory (a `<COUNTRY>` subfolder is created) |
| `--cookies` | — | Path to a `cookies.txt` exported from a logged-in browser |

## How it works

1. yt-dlp queries TikTok's public **explore/trending** feed.
2. The feed is limited to the first `--count` entries (the "top" videos).
3. Each video is downloaded as an MP4 named `<uploader>-<id>.mp4`.

### About "login"

Public trending videos do **not** require login. For region-specific feeds or
restricted content, export your browser cookies (e.g. with the
*Get cookies.txt* extension) and pass them via `--cookies`. The region served
also depends on your network IP — a VPN/proxy for the target country yields the
most accurate per-country trending list.

## ⚠️ Legal note

TikTok has no official public API for downloading trending videos, and
downloading content may violate TikTok's Terms of Service. Use this tool only
for content you have the right to download, and at your own risk.
