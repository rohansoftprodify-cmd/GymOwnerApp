#!/usr/bin/env node
/**
 * Converts GYM_PLATFORM_OVERVIEW.md to PDF using marked + Chrome headless.
 * No Puppeteer/Chromium download required.
 */

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

const INPUT = path.join(__dirname, 'GYM_PLATFORM_OVERVIEW.md');
const STYLESHEET = path.join(__dirname, 'pdf-style.css');
const OUTPUT = path.join(__dirname, 'GYM_PLATFORM_OVERVIEW.pdf');
const HTML_TMP = path.join(__dirname, '.GYM_PLATFORM_OVERVIEW.tmp.html');

const CHROME_CANDIDATES = [
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium-browser',
];

function findChrome() {
  for (const candidate of CHROME_CANDIDATES) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

function ensureMarked() {
  try {
    return require('marked');
  } catch {
    execFileSync('npm', ['install', '--no-save', 'marked@12'], {
      cwd: __dirname,
      stdio: 'inherit',
    });
    return require('marked');
  }
}

function buildHtml(markdown, css) {
  const { marked } = ensureMarked();
  const body = marked.parse(markdown, { mangle: false, headerIds: false });
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Gym Management Platform</title>
  <style>${css}</style>
</head>
<body>
${body}
</body>
</html>`;
}

function main() {
  if (!fs.existsSync(INPUT)) {
    console.error(`Error: ${INPUT} not found`);
    process.exit(1);
  }

  const chrome = findChrome();
  if (!chrome) {
    console.error('Error: Google Chrome not found. Install Chrome to generate PDF.');
    process.exit(1);
  }

  const markdown = fs.readFileSync(INPUT, 'utf8');
  const css = fs.readFileSync(STYLESHEET, 'utf8');
  const html = buildHtml(markdown, css);

  fs.writeFileSync(HTML_TMP, html, 'utf8');

  console.log('Rendering PDF with Chrome headless...');

  try {
    execFileSync(
      chrome,
      [
        '--headless=new',
        '--disable-gpu',
        '--no-sandbox',
        '--run-all-compositor-stages-before-draw',
        '--virtual-time-budget=10000',
        `--print-to-pdf=${OUTPUT}`,
        HTML_TMP,
      ],
      { stdio: 'inherit' },
    );
  } finally {
    if (fs.existsSync(HTML_TMP)) fs.unlinkSync(HTML_TMP);
  }

  if (!fs.existsSync(OUTPUT)) {
    console.error('Error: PDF was not created.');
    process.exit(1);
  }

  const stats = fs.statSync(OUTPUT);
  console.log(`Done: ${OUTPUT} (${Math.round(stats.size / 1024)} KB)`);
}

main();
