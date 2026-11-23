# Build the PDF manuals / 构建 PDF 手册

Run from the repository root / 在仓库根目录运行

```sh
python docs/build/build_manual.py --pdf-dir release
```

Requires Python 3.10+, Pandoc, PowerShell, and XeLaTeX or Tectonic. Use
`--engine` to select a compiler by path. On Linux, install the TeX Live
Chinese, LaTeX extra, and recommended font packages, plus the Noto CJK, TeX Gyre, and DejaVu fonts.

依赖 Python 3.10+、Pandoc、PowerShell、XeLaTeX 或 Tectonic。
可用 `--engine` 指定编译器路径。Linux 还需安装 TeX Live 中文与
LaTeX extra 宏包、推荐字体包，以及 Noto CJK、TeX Gyre 和 DejaVu 字体。

The numbered Markdown chapters in `docs/en` and `docs/zh` are the editing
sources. The release workflow builds both PDFs from the same checkout as the
application. To generate only merged Markdown, use `--docs` and `--output`.

手册正文在 `docs/en` 和 `docs/zh` 的编号章节中。发布流程从同一提交构建
应用和两份 PDF。只需合并 Markdown 时，使用 `--docs` 和 `--output`。
