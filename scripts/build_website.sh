#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
website_dir="$repo_root/website"
chapter_file="$repo_root/chapters/Act 1 - Synthetic Fog/Chapter 01 - Insufficiently False.md"
cover_file="$repo_root/proof-of-human.png"
book_file="$repo_root/Proof of Human.pdf"
output_file="$website_dir/index.html"

for required_file in "$chapter_file" "$cover_file" "$book_file"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Missing required file: $required_file" >&2
    exit 1
  fi
done

mkdir -p "$website_dir"
cp "$cover_file" "$website_dir/proof-of-human.png"
cp "$book_file" "$website_dir/Proof of Human.pdf"

python3 - "$chapter_file" "$output_file" <<'PY'
from pathlib import Path
import html
import re
import sys

chapter_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])


def inline_markdown(text):
    escaped = html.escape(text, quote=True)
    escaped = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", escaped)
    escaped = re.sub(r"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)", r"<em>\1</em>", escaped)
    return escaped


def markdown_to_html(markdown):
    blocks = []
    paragraph = []

    def flush_paragraph():
        if paragraph:
            text = " ".join(line.strip() for line in paragraph)
            blocks.append(f"<p>{inline_markdown(text)}</p>")
            paragraph.clear()

    for raw_line in markdown.splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            flush_paragraph()
            continue

        if line.startswith("# "):
            flush_paragraph()
            blocks.append(f"<h2>{inline_markdown(line[2:].strip())}</h2>")
            continue

        if line.startswith("## "):
            flush_paragraph()
            blocks.append(f"<h3>{inline_markdown(line[3:].strip())}</h3>")
            continue

        paragraph.append(line)

    flush_paragraph()
    return "\n".join(blocks)


chapter_html = markdown_to_html(chapter_path.read_text(encoding="utf-8"))

template = r"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Proof of Human | Joshua Szepietowski</title>
  <meta name="description" content="Launch site for Proof of Human, a novel of synthetic fog, liveness attestation, and the cost of turning truth into evidence.">
  <style>
    :root {
      color-scheme: dark;
      --paper: #f4efe5;
      --ink: #f8f4ea;
      --muted: rgba(248, 244, 234, 0.68);
      --dim: rgba(248, 244, 234, 0.42);
      --line: rgba(248, 244, 234, 0.46);
      --glass: rgba(14, 13, 12, 0.62);
      --glass-strong: rgba(12, 12, 12, 0.82);
      --rust: #b77b57;
      --amber: #e4c174;
      --cyan: #9ed7d6;
      --red: #b55f5c;
      --green: #b4e2bd;
      --max: 1180px;
      --mono: "SFMono-Regular", "Consolas", "Liberation Mono", monospace;
      --serif: Georgia, "Times New Roman", serif;
      --sans: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }

    * {
      box-sizing: border-box;
    }

    html {
      background: #050505;
      scroll-behavior: smooth;
    }

    body {
      margin: 0;
      min-width: 320px;
      overflow-x: hidden;
      background:
        radial-gradient(circle at 18% 8%, rgba(158, 215, 214, 0.13), transparent 26rem),
        radial-gradient(circle at 78% 28%, rgba(183, 123, 87, 0.15), transparent 28rem),
        linear-gradient(180deg, #050505 0%, #0e0d0c 36%, #17130f 100%);
      color: var(--ink);
      font-family: var(--sans);
      line-height: 1.55;
    }

    body::before {
      position: fixed;
      inset: 0;
      z-index: -3;
      content: "";
      background-image:
        linear-gradient(rgba(255,255,255,0.035) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255,255,255,0.025) 1px, transparent 1px);
      background-size: 56px 56px;
      mask-image: linear-gradient(180deg, black, transparent 88%);
    }

    body::after {
      position: fixed;
      inset: 0;
      z-index: -2;
      pointer-events: none;
      content: "";
      background:
        linear-gradient(rgba(255,255,255,0.035) 50%, rgba(0,0,0,0.03) 50%),
        radial-gradient(circle at center, transparent 0, rgba(0,0,0,0.5) 72%);
      background-size: 100% 4px, 100% 100%;
      mix-blend-mode: screen;
      opacity: 0.23;
    }

    a {
      color: inherit;
      text-decoration-color: rgba(248, 244, 234, 0.38);
      text-underline-offset: 0.18em;
    }

    a:hover {
      text-decoration-color: var(--cyan);
    }

    button,
    .button {
      display: inline-flex;
      min-height: 44px;
      align-items: center;
      justify-content: center;
      border: 1px solid rgba(248, 244, 234, 0.46);
      border-radius: 2px;
      padding: 0.82rem 1rem;
      background: rgba(248, 244, 234, 0.08);
      color: var(--ink);
      font: 700 0.76rem/1 var(--mono);
      letter-spacing: 0;
      text-decoration: none;
      text-transform: uppercase;
      cursor: pointer;
      transition: border-color 160ms ease, background 160ms ease, transform 160ms ease;
    }

    button:hover,
    .button:hover {
      border-color: var(--cyan);
      background: rgba(158, 215, 214, 0.14);
      transform: translateY(-1px);
    }

    .button.primary {
      border-color: rgba(244, 239, 229, 0.78);
      background: var(--paper);
      color: #11100e;
    }

    .site-shell {
      position: relative;
      min-height: 100vh;
    }

    #sensor-field {
      position: fixed;
      inset: 0;
      z-index: -1;
      pointer-events: none;
      opacity: 0.8;
    }

    .topbar {
      position: fixed;
      top: 0;
      right: 0;
      left: 0;
      z-index: 30;
      border-bottom: 1px solid rgba(248, 244, 234, 0.14);
      background: rgba(5, 5, 5, 0.58);
      backdrop-filter: blur(18px);
    }

    .topbar-inner {
      display: flex;
      width: min(var(--max), calc(100% - 32px));
      min-height: 58px;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
      margin: 0 auto;
    }

    .brand {
      font-family: var(--mono);
      font-size: 0.78rem;
      color: rgba(248, 244, 234, 0.86);
      text-transform: uppercase;
    }

    .nav {
      display: flex;
      flex-wrap: wrap;
      justify-content: flex-end;
      gap: 0.85rem;
      font: 700 0.68rem/1 var(--mono);
      color: var(--muted);
      text-transform: uppercase;
    }

    .hero {
      position: relative;
      display: grid;
      min-height: 100svh;
      align-items: center;
      padding: 94px 0 48px;
    }

    .hero-inner {
      display: grid;
      width: min(var(--max), calc(100% - 32px));
      grid-template-columns: minmax(260px, 0.92fr) minmax(320px, 1.08fr);
      align-items: center;
      gap: clamp(1.7rem, 4vw, 4.5rem);
      margin: 0 auto;
    }

    .cover-rig {
      position: relative;
      width: min(100%, 430px);
      justify-self: center;
    }

    .cover-rig::before,
    .cover-rig::after {
      position: absolute;
      inset: -16px;
      content: "";
      border: 1px solid rgba(248, 244, 234, 0.38);
      clip-path: polygon(0 9%, 9% 0, 91% 0, 100% 9%, 100% 91%, 91% 100%, 9% 100%, 0 91%);
      pointer-events: none;
    }

    .cover-rig::after {
      inset: 9%;
      border-color: rgba(158, 215, 214, 0.33);
      animation: scanPulse 3.8s ease-in-out infinite;
    }

    .cover {
      display: block;
      width: 100%;
      height: auto;
      box-shadow: 0 30px 90px rgba(0, 0, 0, 0.72);
      filter: contrast(1.05) saturate(0.9);
    }

    .scan-sweep {
      position: absolute;
      inset: 0;
      overflow: hidden;
      pointer-events: none;
    }

    .scan-sweep::before {
      position: absolute;
      top: -18%;
      right: 0;
      left: 0;
      height: 18%;
      content: "";
      background: linear-gradient(180deg, transparent, rgba(158, 215, 214, 0.34), transparent);
      animation: sweep 4.5s linear infinite;
    }

    .cover-node {
      position: absolute;
      width: 7px;
      height: 7px;
      border: 1px solid var(--paper);
      background: rgba(244, 239, 229, 0.4);
      transform: translate(-50%, -50%);
    }

    .node-a { top: 25%; left: 21%; }
    .node-b { top: 37%; left: 46%; }
    .node-c { top: 56%; left: 28%; }
    .node-d { top: 68%; left: 58%; }

    .hero-copy {
      position: relative;
      padding: clamp(1rem, 3vw, 2rem) 0;
    }

    .eyebrow {
      display: inline-flex;
      gap: 0.5rem;
      align-items: center;
      margin: 0 0 1rem;
      font: 700 0.75rem/1.4 var(--mono);
      color: var(--cyan);
      text-transform: uppercase;
    }

    .status-dot {
      width: 0.58rem;
      height: 0.58rem;
      border-radius: 999px;
      background: var(--green);
      box-shadow: 0 0 18px rgba(180, 226, 189, 0.72);
    }

    h1 {
      max-width: 760px;
      margin: 0;
      font-family: var(--serif);
      font-size: clamp(4rem, 11vw, 8.7rem);
      font-weight: 500;
      line-height: 0.82;
      letter-spacing: 0;
    }

    .subtitle {
      max-width: 680px;
      margin: 1.4rem 0 0;
      color: rgba(248, 244, 234, 0.86);
      font-size: clamp(1.05rem, 1.9vw, 1.35rem);
    }

    .thesis-line {
      max-width: 660px;
      margin: 1.4rem 0 0;
      color: var(--paper);
      font-family: var(--mono);
      font-size: 0.92rem;
    }

    .cta-row {
      display: flex;
      flex-wrap: wrap;
      gap: 0.75rem;
      margin-top: 1.8rem;
    }

    .protocol-panel {
      position: relative;
      max-width: 650px;
      margin-top: 2rem;
      border: 1px solid rgba(248, 244, 234, 0.3);
      background: linear-gradient(135deg, rgba(248, 244, 234, 0.1), rgba(248, 244, 234, 0.03));
      clip-path: polygon(0 0, calc(100% - 14px) 0, 100% 14px, 100% 100%, 14px 100%, 0 calc(100% - 14px));
    }

    .protocol-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 1px;
      background: rgba(248, 244, 234, 0.16);
    }

    .readout {
      min-height: 88px;
      padding: 0.9rem;
      background: rgba(5, 5, 5, 0.64);
    }

    .readout .label {
      display: block;
      margin-bottom: 0.35rem;
      color: var(--dim);
      font: 700 0.66rem/1.3 var(--mono);
      text-transform: uppercase;
    }

    .readout .value {
      display: block;
      color: var(--paper);
      font: 700 0.88rem/1.35 var(--mono);
      text-transform: uppercase;
    }

    .ticker {
      overflow: hidden;
      border-top: 1px solid rgba(248, 244, 234, 0.16);
      color: rgba(248, 244, 234, 0.64);
      font: 700 0.68rem/1 var(--mono);
      text-transform: uppercase;
      white-space: nowrap;
    }

    .ticker span {
      display: inline-block;
      padding: 0.78rem 0;
      animation: ticker 24s linear infinite;
    }

    .band {
      position: relative;
      padding: clamp(4rem, 9vw, 7.5rem) 0;
    }

    .band.alt {
      border-block: 1px solid rgba(248, 244, 234, 0.11);
      background: rgba(244, 239, 229, 0.035);
    }

    .inner {
      width: min(var(--max), calc(100% - 32px));
      margin: 0 auto;
    }

    .split {
      display: grid;
      grid-template-columns: minmax(260px, 0.72fr) minmax(320px, 1.28fr);
      gap: clamp(2rem, 5vw, 5rem);
      align-items: start;
    }

    .section-kicker {
      margin: 0 0 0.7rem;
      color: var(--cyan);
      font: 700 0.72rem/1.3 var(--mono);
      text-transform: uppercase;
    }

    h2 {
      margin: 0;
      font-family: var(--serif);
      font-size: clamp(2.3rem, 5vw, 4.6rem);
      font-weight: 500;
      line-height: 0.95;
      letter-spacing: 0;
    }

    .section-copy {
      max-width: 740px;
      margin: 0;
      color: rgba(248, 244, 234, 0.8);
      font-size: 1.05rem;
    }

    .evidence-list {
      display: grid;
      gap: 1px;
      margin-top: 1.5rem;
      background: rgba(248, 244, 234, 0.14);
    }

    .evidence-row {
      display: grid;
      grid-template-columns: 1fr auto;
      gap: 1rem;
      align-items: center;
      padding: 0.92rem 1rem;
      background: rgba(5, 5, 5, 0.72);
      font-family: var(--mono);
      font-size: 0.82rem;
    }

    .evidence-row strong {
      color: var(--paper);
      font-weight: 700;
      text-transform: uppercase;
    }

    .evidence-row span {
      color: var(--muted);
    }

    .world-fragments {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 1px;
      margin-top: 2.2rem;
      background: rgba(248, 244, 234, 0.15);
    }

    .fragment {
      min-height: 200px;
      padding: 1.15rem;
      background: rgba(10, 10, 9, 0.76);
      color: var(--muted);
    }

    .fragment b {
      display: block;
      margin-bottom: 0.8rem;
      color: var(--paper);
      font: 700 0.74rem/1.35 var(--mono);
      text-transform: uppercase;
    }

    .verifier {
      display: grid;
      grid-template-columns: minmax(280px, 0.95fr) minmax(300px, 1.05fr);
      gap: clamp(1.5rem, 4vw, 3rem);
      align-items: center;
    }

    .camera-stage {
      position: relative;
      overflow: hidden;
      min-height: 360px;
      border: 1px solid rgba(248, 244, 234, 0.34);
      background: #070707;
      clip-path: polygon(0 0, calc(100% - 16px) 0, 100% 16px, 100% 100%, 16px 100%, 0 calc(100% - 16px));
    }

    video {
      width: 100%;
      height: 100%;
      min-height: 360px;
      object-fit: cover;
      filter: grayscale(0.55) contrast(1.18);
      transform: scaleX(-1);
    }

    .camera-empty {
      position: absolute;
      inset: 0;
      display: grid;
      place-items: center;
      padding: 2rem;
      color: var(--dim);
      font: 700 0.72rem/1.7 var(--mono);
      text-align: center;
      text-transform: uppercase;
    }

    .camera-overlay {
      position: absolute;
      inset: 0;
      pointer-events: none;
      background:
        linear-gradient(90deg, transparent 49.8%, rgba(248,244,234,0.36) 50%, transparent 50.2%),
        linear-gradient(transparent 49.8%, rgba(248,244,234,0.23) 50%, transparent 50.2%);
      opacity: 0.5;
    }

    .camera-overlay::before {
      position: absolute;
      inset: 10%;
      content: "";
      border: 1px solid rgba(248, 244, 234, 0.62);
      clip-path: polygon(0 8%, 8% 0, 92% 0, 100% 8%, 100% 92%, 92% 100%, 8% 100%, 0 92%);
    }

    .camera-overlay::after {
      position: absolute;
      right: 7%;
      bottom: 8%;
      left: 7%;
      height: 2px;
      content: "";
      background: linear-gradient(90deg, transparent, var(--cyan), transparent);
      animation: sweep 2.2s linear infinite;
    }

    .verify-panel {
      border: 1px solid rgba(248, 244, 234, 0.22);
      background: var(--glass);
      padding: clamp(1rem, 2vw, 1.35rem);
    }

    .meter {
      height: 8px;
      margin: 0.7rem 0 1.2rem;
      border: 1px solid rgba(248, 244, 234, 0.3);
      background: rgba(255, 255, 255, 0.04);
    }

    .meter-fill {
      width: 7%;
      height: 100%;
      background: linear-gradient(90deg, var(--red), var(--amber), var(--green));
      transition: width 260ms ease;
    }

    .chapter {
      max-width: 820px;
      margin: 0 auto;
      color: rgba(248, 244, 234, 0.86);
    }

    .chapter h2 {
      margin-bottom: 1.6rem;
      font-size: clamp(2.1rem, 4vw, 4rem);
    }

    .chapter p {
      margin: 0 0 1.25rem;
      font-family: var(--serif);
      font-size: clamp(1.13rem, 1.6vw, 1.34rem);
      line-height: 1.72;
    }

    .chapter strong {
      color: var(--paper);
      font-family: var(--mono);
      font-size: 0.84em;
      font-weight: 700;
      text-transform: uppercase;
    }

    footer {
      padding: 3rem 0;
      border-top: 1px solid rgba(248, 244, 234, 0.14);
      color: var(--muted);
      font: 700 0.72rem/1.6 var(--mono);
      text-transform: uppercase;
    }

    .footer-inner {
      display: flex;
      width: min(var(--max), calc(100% - 32px));
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
      margin: 0 auto;
    }

    .footer-links {
      display: flex;
      flex-wrap: wrap;
      gap: 0.9rem;
      justify-content: flex-end;
    }

    .hidden-canvas {
      display: none;
    }

    @keyframes scanPulse {
      0%, 100% { opacity: 0.26; transform: scale(1); }
      50% { opacity: 0.9; transform: scale(1.025); }
    }

    @keyframes sweep {
      from { transform: translateY(-20%); }
      to { transform: translateY(650%); }
    }

    @keyframes ticker {
      from { transform: translateX(0); }
      to { transform: translateX(-50%); }
    }

    @media (max-width: 900px) {
      .topbar {
        position: absolute;
      }

      .hero-inner,
      .split,
      .verifier {
        grid-template-columns: 1fr;
      }

      .hero {
        min-height: auto;
      }

      .cover-rig {
        width: min(76vw, 390px);
      }

      .protocol-grid,
      .world-fragments {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 560px) {
      .topbar-inner,
      .footer-inner {
        align-items: flex-start;
        flex-direction: column;
        justify-content: center;
        padding: 0.8rem 0;
      }

      .nav,
      .footer-links {
        justify-content: flex-start;
      }

      h1 {
        font-size: clamp(3.5rem, 20vw, 5.4rem);
      }

      .evidence-row {
        grid-template-columns: 1fr;
      }
    }

    @media (prefers-reduced-motion: reduce) {
      *,
      *::before,
      *::after {
        animation-duration: 1ms !important;
        animation-iteration-count: 1 !important;
        scroll-behavior: auto !important;
      }
    }
  </style>
</head>
<body>
  <canvas id="sensor-field" aria-hidden="true"></canvas>
  <div class="site-shell">
    <header class="topbar">
      <div class="topbar-inner">
        <a class="brand" href="#top">Proof of Human</a>
        <nav class="nav" aria-label="Primary">
          <a href="#verification">Verification</a>
          <a href="#chapter">Chapter 01</a>
          <a href="Proof%20of%20Human.pdf" download="Proof of Human.pdf">Full Book</a>
          <a href="https://github.com/joshSzep/proof-of-human">Source</a>
          <a href="https://joshszep.com">Joshua Szepietowski</a>
        </nav>
      </div>
    </header>

    <main id="top">
      <section class="hero" aria-labelledby="hero-title">
        <div class="hero-inner">
          <div class="cover-rig" aria-label="Proof of Human book cover">
            <img class="cover" src="proof-of-human.png" alt="Proof of Human book cover showing a human face under digital verification overlays.">
            <div class="scan-sweep"></div>
            <span class="cover-node node-a"></span>
            <span class="cover-node node-b"></span>
            <span class="cover-node node-c"></span>
            <span class="cover-node node-d"></span>
          </div>

          <div class="hero-copy">
            <p class="eyebrow"><span class="status-dot"></span> Human-origin confidence: pending reader consent</p>
            <h1 id="hero-title">Proof of Human</h1>
            <p class="subtitle">A near-future novel about synthetic fog, liveness attestation, grief archives, and the moment a society confuses verified activity for human agency.</p>
            <p class="thesis-line">The record proves activity. It does not prove agency.</p>
            <div class="cta-row">
              <a class="button primary" href="Proof%20of%20Human.pdf" download="Proof of Human.pdf">Download Full Book</a>
              <a class="button" href="#chapter">Read Chapter 01</a>
              <a class="button" href="https://github.com/joshSzep/proof-of-human">Source Repo</a>
              <a class="button" href="https://joshszep.com">All Books</a>
            </div>

            <div class="protocol-panel" aria-label="In-world protocol readouts">
              <div class="protocol-grid">
                <div class="readout"><span class="label">Data Source</span><span class="value">Central Registry</span></div>
                <div class="readout"><span class="label">Scan Mode</span><span class="value">Facial Verification</span></div>
                <div class="readout"><span class="label">Consent State</span><span class="value">Contested</span></div>
                <div class="readout"><span class="label">Synthetic Fog</span><span class="value">Ambient</span></div>
                <div class="readout"><span class="label">Origin Status</span><span class="value">Human Confirmed</span></div>
                <div class="readout"><span class="label">Condition</span><span class="value">Not Established</span></div>
              </div>
              <div class="ticker" aria-hidden="true">
                <span>INSUFFICIENTLY FALSE / LIVENESS ACTIVE / LOCATION DISCLOSURE SHIELDED / CONSENT RECONCILIATION PENDING / CONFIDENCE DEGRADATION SUPPRESSED / </span>
                <span>INSUFFICIENTLY FALSE / LIVENESS ACTIVE / LOCATION DISCLOSURE SHIELDED / CONSENT RECONCILIATION PENDING / CONFIDENCE DEGRADATION SUPPRESSED / </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section class="band alt" aria-labelledby="artifact-title">
        <div class="inner split">
          <div>
            <p class="section-kicker">Recovered Launch Artifact</p>
            <h2 id="artifact-title">Trust without total capture.</h2>
          </div>
          <div>
            <p class="section-copy">In this world, verification does not arrive as spectacle. It arrives as forms, labels, court thresholds, capture policies, insurance tools, grief archive permissions, and calm dashboards that turn unbearable ambiguity into accepted states.</p>
            <div class="evidence-list" aria-label="Proof system failure modes">
              <div class="evidence-row"><strong>Synthetic Denial</strong><span>Real events surrounded by plausible alternatives.</span></div>
              <div class="evidence-row"><strong>Credential Laundering</strong><span>Clean labels wrapped around claims no one has proven.</span></div>
              <div class="evidence-row"><strong>Coerced Liveness</strong><span>A human can be active and still not be free.</span></div>
              <div class="evidence-row"><strong>Proof Displacement</strong><span>The label becomes more persuasive than the person.</span></div>
            </div>
          </div>
        </div>

        <div class="inner">
          <div class="world-fragments" aria-label="Story world fragments">
            <div class="fragment"><b>CommonProof Protected Source Systems</b> Certifying presence while preserving safety. Origin confidence accepted. Condition field unavailable for public display.</div>
            <div class="fragment"><b>Carver Institute for Civic Evidence</b> A Cambridge room where disclaimers have become incense burned before professional speech.</div>
            <div class="fragment"><b>Geneva Authenticity Convention</b> Dignity weighed by procedure. A live-certified channel can still be a cage.</div>
          </div>
        </div>
      </section>

      <section id="verification" class="band" aria-labelledby="verify-title">
        <div class="inner verifier">
          <div class="camera-stage">
            <video id="camera" playsinline muted></video>
            <div id="camera-empty" class="camera-empty">Optional local camera challenge inactive. No image leaves this page.</div>
            <div class="camera-overlay" aria-hidden="true"></div>
          </div>

          <div class="verify-panel">
            <p class="section-kicker">Protected-Source Liveness Workflow</p>
            <h2 id="verify-title">Optional human verification.</h2>
            <p class="section-copy">Start the local webcam challenge to turn your browser into a tiny, fictional CommonProof terminal. It estimates motion and light changes in your camera stream inside this page only; it does not identify you, record you, or upload anything.</p>
            <div class="evidence-list">
              <div class="evidence-row"><strong>Status</strong><span id="verify-status">Awaiting explicit consent</span></div>
              <div class="evidence-row"><strong>Human-Origin Confidence</strong><span id="confidence">0.00%</span></div>
              <div class="evidence-row"><strong>Condition</strong><span id="condition">Not established</span></div>
            </div>
            <div class="meter" aria-label="Human-origin confidence meter"><div id="meter-fill" class="meter-fill"></div></div>
            <button id="verify-button" type="button">Begin Camera Challenge</button>
          </div>
        </div>
        <canvas id="sample-canvas" class="hidden-canvas" width="80" height="60"></canvas>
      </section>

      <section id="chapter" class="band alt" aria-labelledby="chapter-title">
        <article class="chapter">
          <p class="section-kicker">Act 1 - Synthetic Fog</p>
          %%CHAPTER_HTML%%
        </article>
      </section>
    </main>

    <footer>
      <div class="footer-inner">
        <div>Proof of Human / Joshua Szepietowski</div>
        <div class="footer-links">
          <a href="Proof%20of%20Human.pdf" download="Proof of Human.pdf">Download Book</a>
          <a href="https://github.com/joshSzep/proof-of-human">Source Repo</a>
          <a href="https://joshszep.com">All Books</a>
        </div>
      </div>
    </footer>
  </div>

  <script>
    (() => {
      const canvas = document.getElementById('sensor-field');
      const ctx = canvas.getContext('2d');
      const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      let width = 0;
      let height = 0;
      let nodes = [];
      let last = 0;

      function resize() {
        const ratio = Math.min(window.devicePixelRatio || 1, 2);
        width = window.innerWidth;
        height = window.innerHeight;
        canvas.width = Math.floor(width * ratio);
        canvas.height = Math.floor(height * ratio);
        canvas.style.width = width + 'px';
        canvas.style.height = height + 'px';
        ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
        nodes = Array.from({ length: Math.max(26, Math.floor(width / 34)) }, (_, index) => ({
          x: Math.random() * width,
          y: Math.random() * height,
          vx: (Math.random() - 0.5) * 0.14,
          vy: (Math.random() - 0.5) * 0.14,
          label: ['HO', 'LIVE', 'CID', 'AGENCY?', '99.97', 'FOG'][index % 6]
        }));
      }

      function draw(time) {
        if (prefersReduced && last) return;
        last = time;
        ctx.clearRect(0, 0, width, height);
        ctx.lineWidth = 1;

        for (const node of nodes) {
          node.x += node.vx;
          node.y += node.vy;
          if (node.x < -30) node.x = width + 30;
          if (node.x > width + 30) node.x = -30;
          if (node.y < -30) node.y = height + 30;
          if (node.y > height + 30) node.y = -30;
        }

        for (let i = 0; i < nodes.length; i += 1) {
          for (let j = i + 1; j < nodes.length; j += 1) {
            const a = nodes[i];
            const b = nodes[j];
            const distance = Math.hypot(a.x - b.x, a.y - b.y);
            if (distance < 150) {
              const alpha = (1 - distance / 150) * 0.2;
              ctx.strokeStyle = `rgba(244,239,229,${alpha})`;
              ctx.beginPath();
              ctx.moveTo(a.x, a.y);
              ctx.lineTo(b.x, b.y);
              ctx.stroke();
            }
          }
        }

        ctx.font = '10px SFMono-Regular, Consolas, monospace';
        for (const node of nodes) {
          ctx.fillStyle = 'rgba(244,239,229,0.46)';
          ctx.fillRect(node.x - 2, node.y - 2, 4, 4);
          if (Math.random() > 0.985) {
            ctx.fillStyle = 'rgba(158,215,214,0.7)';
            ctx.fillText(node.label, node.x + 8, node.y - 8);
          }
        }

        requestAnimationFrame(draw);
      }

      resize();
      window.addEventListener('resize', resize, { passive: true });
      requestAnimationFrame(draw);
    })();

    (() => {
      const button = document.getElementById('verify-button');
      const video = document.getElementById('camera');
      const empty = document.getElementById('camera-empty');
      const status = document.getElementById('verify-status');
      const confidence = document.getElementById('confidence');
      const condition = document.getElementById('condition');
      const meter = document.getElementById('meter-fill');
      const sample = document.getElementById('sample-canvas');
      const ctx = sample.getContext('2d', { willReadFrequently: true });
      let previous = null;
      let stream = null;
      let active = false;

      function setReadout(nextStatus, score, nextCondition) {
        status.textContent = nextStatus;
        confidence.textContent = `${score.toFixed(2)}%`;
        condition.textContent = nextCondition;
        meter.style.width = `${Math.max(6, Math.min(score, 99.97))}%`;
      }

      function analyze() {
        if (!active || video.readyState < 2) {
          requestAnimationFrame(analyze);
          return;
        }

        ctx.drawImage(video, 0, 0, sample.width, sample.height);
        const frame = ctx.getImageData(0, 0, sample.width, sample.height).data;
        let diff = 0;
        let light = 0;

        if (previous) {
          for (let i = 0; i < frame.length; i += 16) {
            const current = (frame[i] + frame[i + 1] + frame[i + 2]) / 3;
            const before = (previous[i] + previous[i + 1] + previous[i + 2]) / 3;
            diff += Math.abs(current - before);
            light += current;
          }
          diff /= frame.length / 16;
          light /= frame.length / 16;
        }

        previous = new Uint8ClampedArray(frame);
        const movementScore = Math.min(22, diff * 2.35);
        const lightScore = Math.max(0, Math.min(10, (light - 28) / 9));
        const pulse = Math.sin(Date.now() / 720) * 1.2;
        const score = Math.max(12, Math.min(99.97, 63 + movementScore + lightScore + pulse));

        if (score > 82 && diff > 3.6) {
          setReadout('Liveness challenge accepted', score, 'Origin indicated; agency not established');
        } else if (score > 70) {
          setReadout('Seeking micro-motion confirmation', score, 'Origin unresolved; agency not established');
        } else {
          setReadout('Capture quality insufficient', score, 'Not established');
        }

        setTimeout(() => requestAnimationFrame(analyze), 120);
      }

      async function start() {
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          setReadout('Camera API unavailable in this browser', 0, 'Not established');
          return;
        }

        try {
          button.disabled = true;
          button.textContent = 'Requesting Consent';
          stream = await navigator.mediaDevices.getUserMedia({
            video: { facingMode: 'user', width: { ideal: 960 }, height: { ideal: 720 } },
            audio: false
          });
          video.srcObject = stream;
          await video.play();
          empty.style.display = 'none';
          active = true;
          button.textContent = 'Challenge Running';
          setReadout('Protected-source channel active', 71.4, 'Not established');
          analyze();
        } catch (error) {
          button.disabled = false;
          button.textContent = 'Begin Camera Challenge';
          setReadout('Camera consent denied or unavailable', 0, 'Not established');
        }
      }

      button.addEventListener('click', start);
      window.addEventListener('pagehide', () => {
        if (stream) {
          for (const track of stream.getTracks()) track.stop();
        }
      });
    })();
  </script>
</body>
</html>
"""

output_path.write_text(template.replace("%%CHAPTER_HTML%%", chapter_html), encoding="utf-8")
PY

printf 'Built %s\n' "$output_file"
