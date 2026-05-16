#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
input_md="$repo_root/Proof of Human.md"
cover_image="$repo_root/proof-of-human.png"
output_pdf="$repo_root/Proof of Human.pdf"

for command in pandoc pdflatex; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

if [[ ! -f "$input_md" ]]; then
  echo "Missing manuscript: $input_md" >&2
  echo "Run scripts/build_manuscript.sh first." >&2
  exit 1
fi

if [[ ! -f "$cover_image" ]]; then
  echo "Missing cover image: $cover_image" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

body_md="$tmp_dir/body.md"
template_tex="$tmp_dir/proof-of-human-template.tex"
cp "$cover_image" "$tmp_dir/cover.png"

awk '
  NR == 1 && $0 == "# Proof of Human" { skipped_title = 1; next }
  skipped_title && NR == 2 && $0 == "" { next }
  skipped_title && NR == 3 && $0 == "Joshua Szepietowski" { next }
  skipped_title && NR == 4 && $0 == "" { next }
  { print }
' "$input_md" > "$body_md"

cat > "$template_tex" <<'EOF'
\documentclass[11pt,openany,oneside]{book}

\usepackage[paperwidth=6in,paperheight=9in,inner=0.72in,outer=0.72in,top=0.72in,bottom=0.78in]{geometry}
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage{tgpagella}
\usepackage{microtype}
\usepackage{graphicx}
\usepackage{xcolor}
\usepackage{setspace}
\usepackage{fancyhdr}
\usepackage{titlesec}
\usepackage[hidelinks]{hyperref}
\usepackage{bookmark}

\hypersetup{
  pdftitle={Proof of Human},
  pdfauthor={Joshua Szepietowski},
  pdfsubject={Proof of Human manuscript},
  pdfcreator={pandoc and pdflatex}
}

\definecolor{ProofInk}{HTML}{171717}
\definecolor{ProofMuted}{HTML}{5B5B5B}

\providecommand{\tightlist}{%
  \setlength{\itemsep}{0pt}\setlength{\parskip}{0pt}}

\setcounter{secnumdepth}{0}
\setcounter{tocdepth}{1}
\setlength{\parindent}{1.18em}
\setlength{\parskip}{0pt}
\linespread{1.055}
\raggedbottom
\emergencystretch=2em

\pagestyle{fancy}
\fancyhf{}
\fancyhead[C]{\small\scshape Proof of Human}
\fancyfoot[C]{\small\thepage}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}

\fancypagestyle{plain}{%
  \fancyhf{}
  \fancyfoot[C]{\small\thepage}
  \renewcommand{\headrulewidth}{0pt}
  \renewcommand{\footrulewidth}{0pt}
}

\titleformat{\part}[display]
  {\thispagestyle{empty}\centering\normalfont\color{ProofInk}}
  {}
  {0pt}
  {\vspace*{0.28\textheight}\Huge\scshape}
  [\vfill\clearpage]
\titlespacing*{\part}{0pt}{0pt}{0pt}

\titleformat{\chapter}[display]
  {\normalfont\centering\color{ProofInk}}
  {}
  {0pt}
  {\Huge\scshape}
  [\vspace{1.25\baselineskip}{\color{ProofMuted}\titlerule[0.4pt]}\vspace{1.5\baselineskip}]
\titlespacing*{\chapter}{0pt}{0.16\textheight}{0pt}

\begin{document}
\frontmatter

\newgeometry{margin=0in}
\thispagestyle{empty}
\noindent\includegraphics[width=\paperwidth,height=\paperheight]{cover.png}
\clearpage
\restoregeometry

\thispagestyle{empty}
\vspace*{0.32\textheight}
\begin{center}
  {\Huge\scshape Proof of Human\par}
  \vspace{1.2em}
  {\Large Joshua Szepietowski\par}
\end{center}
\clearpage

\mainmatter
$body$

\end{document}
EOF

(
  cd "$tmp_dir"
  pandoc "$body_md" \
    --from markdown \
    --template "$template_tex" \
    --pdf-engine=pdflatex \
    --shift-heading-level-by=-1 \
    --top-level-division=part \
    --output "$output_pdf"
)

printf 'Built %s\n' "$output_pdf"
