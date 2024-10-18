# Tuba's API Server

Server to be used for Tuba's analytics and other services.

## Notice

The analytics in question are anonymized voluntarily published (aka OPT-IN) Tuba settings and will be used to gather a general idea of what settings are popular.

<details><summary>Example analytics body</summary>

```json
{
    "accounts": [
        "0c604c54-15a9-43eb-b4e3-11d986ee33d3"
    ],
    "analytics": {
        "color-scheme": "TUBA_COLOR_SCHEME_SYSTEM",
        "timeline-page-size": "20",
        "live-updates": "TRUE",
        "public-live-updates": "FALSE",
        "show-spoilers": "FALSE",
        "show-preview-cards": "TRUE",
        "larger-font-size": "FALSE",
        "larger-line-height": "FALSE",
        "aggressive-resolving": "FALSE",
        "strip-tracking": "TRUE",
        "scale-emoji-hover": "FALSE",
        "letterbox-media": "FALSE",
        "media-viewer-expand-pictures": "TRUE",
        "enlarge-custom-emojis": "FALSE",
        "use-blurhash": "TRUE",
        "group-push-notifications": "FALSE",
        "advanced-boost-dialog": "TRUE",
        "reply-to-old-post-reminder": "TRUE",
        "spellchecker-enabled": "TRUE",
        "darken-images-on-dark-mode": "FALSE",
        "media-viewer-last-used-volume": "1.000000",
        "monitor-network": "TRUE",
        "dim-trivial-notifications": "FALSE"
    }
}
```

</details>

The API might also provide additional content or features to Tuba users. Future additions to the API will also abide by the same standards of being optional, opt-in and privacy respecting.

## Installation

- Fill the config file [`.env.json.example`](./.env.json.example)
- Rename it to `.env.json`
- Run:

```sh
$ shards install
$ shards build --release
```

## Usage

```sh
$ ./bin/server --help
    -b HOST, --bind HOST             Host to bind (defaults to 0.0.0.0)
    -p PORT, --port PORT             Port to listen for connections (defaults to 3000)
    -s, --ssl                        Enables SSL
    --ssl-key-file FILE              SSL key file
    --ssl-cert-file FILE             SSL certificate file
    -h, --help                       Shows this help
```
