#!/usr/bin/env bash
# Generate GYM_PLATFORM_OVERVIEW.pdf from the Markdown source.
# Uses Node.js + marked + system Chrome (no Puppeteer download).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Generating GYM_PLATFORM_OVERVIEW.pdf ..."
node "$SCRIPT_DIR/generate-pdf.mjs"
