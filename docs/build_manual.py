"""Merge numbered Markdown chapters and link project resources in place."""
from pathlib import Path
import argparse
import re
import shutil
import unicodedata
import os
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
CHAPTER = re.compile(r'^(\d{2})_.+\.md$')
HEADING = re.compile(r'^(#{1,6})\s+(\d+(?:\.\d+)*)\s+(.+?)\s*#*\s*$')
LINK = re.compile(r'(!?\[[^\]\n]*\]\()(<[^>]+>|[^\s)]+)([^)\n]*\))')
REFERENCE = re.compile(r'^(\s*\[[^\]]+\]:\s*)(<[^>]+>|\S+)(.*)$')


def github_slug(text):
    text = text.replace('`', '').lower()
    return ''.join(c for c in text if c in '-_ ' or unicodedata.category(c)[0] in 'LN').replace(' ', '-')


def prose_lines(text):
    """Exclude fenced code from heading/link interpretation."""
    fence = None
    for line in text.splitlines(keepends=True):
        marker = re.match(r'^\s{0,3}(`{3,}|~{3,})', line)
        if marker:
            token = marker.group(1)
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence):
                fence = None
            yield line, False
        else:
            yield line, fence is None


def merge_manual(docs, output):
    docs, output = Path(docs).resolve(), Path(output).resolve()
    if not docs.is_dir():
        raise ValueError(f'Document folder not found: {docs}')
    files = sorted(path for path in docs.iterdir() if CHAPTER.match(path.name))
    if not files:
        raise ValueError('No numbered Markdown chapters found.')
    if output in files:
        raise ValueError('Output must not overwrite a source chapter.')
    numbers = [int(CHAPTER.match(path.name)[1]) for path in files]
    if numbers != list(range(len(numbers))):
        raise ValueError('Chapter filenames must be contiguous from 00.')
    texts, anchors, aliases = {}, {}, {}
    merged_seen = {}
    for path, chapter in zip(files, numbers):
        text = path.read_text(encoding='utf-8-sig')
        texts[path] = text
        local, slugs, seen, headings = {}, {}, {}, []
        for line, prose in prose_lines(text):
            match = HEADING.match(line.rstrip()) if prose else None
            if not match:
                continue
            level, number, title = match.groups()
            if int(number.split('.')[0]) != chapter:
                raise ValueError(f'{path.name}: inconsistent heading {number}')
            if number in local:
                raise ValueError(f'{path.name}: duplicate heading {number}')
            order = tuple(map(int, number.split('.')))
            if headings and order <= headings[-1]:
                raise ValueError(f'{path.name}: headings are not in numerical order: {number}')
            if len(level) != len(order):
                raise ValueError(f'{path.name}: heading level disagrees with number {number}')
            headings.append(order)
            heading_text = re.sub(r'^#{1,6}\s+', '', match[0]).rstrip('#').rstrip()
            slug = github_slug(heading_text)
            count = seen.get(slug, 0);seen[slug] = count+1
            source_anchor = slug + (f'-{count}' if count else '')
            merged_count = merged_seen.get(slug, 0);merged_seen[slug] = merged_count+1
            anchor = slug + (f'-{merged_count}' if merged_count else '')
            local[number] = anchor
            slugs[source_anchor] = anchor
        if str(chapter) not in local:
            raise ValueError(f'{path.name}: missing chapter heading')
        anchors[path], aliases[path] = local, slugs
    assets = {}
    def target_url(raw, source):
        url = raw.strip('<>')
        parts = urlsplit(url)
        if parts.scheme or parts.netloc:
            return raw
        dest = (source.parent / unquote(parts.path)).resolve() if parts.path else source
        chapter_match = CHAPTER.match(dest.name) if dest.parent == docs else None
        if chapter_match and int(chapter_match[1]) in numbers:
            dest = files[numbers.index(int(chapter_match[1]))]
        if dest in anchors:
            fragment = unquote(parts.fragment)
            if fragment:
                anchor = aliases[dest].get(fragment) or anchors[dest].get(fragment)
                if anchor is None:
                    # Numbered headings remain identifiable after their title changes.
                    matches = [target for number, target in anchors[dest].items()
                               if fragment.startswith(number.replace('.', '')+'-')]
                    anchor = matches[0] if len(matches) == 1 else None
                if anchor is None:
                    raise ValueError(f'{source.name}: unknown heading link {url}')
            else:
                anchor = anchors[dest][str(int(CHAPTER.match(dest.name)[1]))]
            return '#'+anchor
        if not parts.path:
            raise ValueError(f'{source.name}: unresolved link {url}')
        if not dest.is_file():
            raise ValueError(f'{source.name}: missing linked file {url}')
        # Project resources stay linked to their actual files rather than copied.
        try:
            relative = dest.relative_to(docs)
        except ValueError:
            project = ROOT if docs.is_relative_to(ROOT) else docs.parent
            if not dest.is_relative_to(project):
                raise ValueError(f'{source.name}: asset outside project: {url}') from None
            try:
                link = Path(os.path.relpath(dest,output.parent)).as_posix()
            except ValueError:  # Separate Windows drives cannot form a relative path.
                link = dest.as_uri()
            if parts.query: link += '?'+parts.query
            if parts.fragment: link += '#'+parts.fragment
            return '<'+link+'>' if ' ' in link else link
        asset = output.parent/(output.stem+'_assets')/relative
        assets[dest] = asset
        link = asset.relative_to(output.parent).as_posix()
        if parts.fragment: link += '#'+parts.fragment
        if parts.query: link += '?'+parts.query
        return '<'+link+'>' if ' ' in link else link
    chunks = []
    for path in files:
        lines = []
        for line, prose in prose_lines(texts[path]):
            if prose:
                # Inline code is literal too; do not rewrite apparent links within it.
                code_spans = [m.span() for m in re.finditer(r'(`+)[^`]*?\1', line)]
                def rewrite_link(match):
                    if any(start <= match.start() < end for start, end in code_spans):
                        return match[0]
                    return match[1]+target_url(match[2], path)+match[3]
                line = LINK.sub(rewrite_link, line)
                match = REFERENCE.match(line.rstrip('\n'))
                if match:
                    line = match[1]+target_url(match[2], path)+match[3]+'\n'
            lines.append(line)
        chunks.append(''.join(lines).rstrip())
    result = '\n\n---\n\n'.join(chunks)+'\n'
    # Validate everything before writing output or copying assets.
    output.parent.mkdir(parents=True, exist_ok=True)
    for source, dest in assets.items():
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, dest)
    output.write_text(result, encoding='utf-8')
    return len(files), len(assets)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--docs', type=Path, help='Folder containing numbered Markdown chapters; prompts when omitted.')
    parser.add_argument('--output', type=Path, help='Destination Markdown file; prompts when omitted, with a suggested default.')
    args = parser.parse_args()
    try:
        docs = args.docs
        if docs is None:
            answer = input('Source document folder: ').strip().strip('"')
            if not answer:
                raise ValueError('Specify a document folder.')
            docs = Path(answer).expanduser()
        if not docs.is_dir():
            raise ValueError(f'Document folder not found: {docs}')
        output = args.output
        if output is None:
            default = docs/'AnnotationReviewer_User_Manual.md'
            answer = input(f'Output Markdown file [{default}]: ').strip().strip('"')
            output = Path(answer).expanduser() if answer else default
        count, assets = merge_manual(docs, output)
    except (EOFError, KeyboardInterrupt):
        parser.exit(1, 'Cancelled: document folder or output was not provided.\n')
    except (ValueError, OSError) as exc:
        parser.exit(1, f'Error: {exc}\n')
    print(f'Merged {count} chapters and {assets} assets: {output.resolve()}')


if __name__ == '__main__':
    main()
