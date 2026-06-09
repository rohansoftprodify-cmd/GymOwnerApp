# Client Presentation

Business-friendly overview of the Gym Management Platform for client presentations.

## Files

| File | Description |
|------|-------------|
| `GYM_PLATFORM_OVERVIEW.md` | Source document (edit this) |
| `pdf-style.css` | PDF styling |
| `generate-pdf.sh` | Build script |
| `GYM_PLATFORM_OVERVIEW.pdf` | Generated PDF (run script to create) |

## Generate PDF

```bash
cd docs/client-presentation
chmod +x generate-pdf.sh
./generate-pdf.sh
```

Requires Node.js and Google Chrome. The script uses `marked` (auto-installed locally) and Chrome headless — no Puppeteer download.

## Manual fallback

If the script fails, open `GYM_PLATFORM_OVERVIEW.md` in VS Code, Typora, or a browser Markdown preview and use **Print → Save as PDF**.

## Updating content

1. Edit `GYM_PLATFORM_OVERVIEW.md`
2. Run `./generate-pdf.sh`
3. Share `GYM_PLATFORM_OVERVIEW.pdf` with the client
