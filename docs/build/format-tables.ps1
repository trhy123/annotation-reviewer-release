# Preserve booktabs rules and add full-width alternating row shading.
$texPath = Join-Path $PSScriptRoot 'content.tex'
$tex = [IO.File]::ReadAllText($texPath)
$tex = [regex]::Replace($tex, '(?s)\\begin\{longtable\}.*?\\end\{longtable\}', {
    param($match)
    $table = $match.Value
    $ruleIndex = $table.IndexOf('\toprule')
    if ($ruleIndex -lt 0) { throw 'Unexpected longtable format.' }
    $spec = $table.Substring(0, $ruleIndex).Replace('@{}', '')
    $spec = $spec.Replace('}p{', '}m{')
    $columns = [regex]::Matches($spec, '\\real\{').Count
    if ($columns -eq 0) { throw 'Expected explicit longtable column widths.' }
    $spec = [regex]::Replace($spec, '\\columnwidth - \d+\\tabcolsep', {
        '\columnwidth - ' + (2 * $columns) + '\tabcolsep'
    })
    $rest = $table.Substring($ruleIndex)
    $parts = $rest -split '\\endhead', 2
    if ($parts.Count -ne 2) { throw 'Expected longtable header boundary.' }
    $header = $parts[0].Replace('\toprule', "\toprule`n\rowcolor{white}")
    $continued = '\rowcolor{white}\multicolumn{' + $columns + '}{r}{\normalfont\ContinuedTableText} \\[1pt]' + [Environment]::NewLine
    $body = New-Object Text.StringBuilder
    $row = 0
    $startRow = $true
    $depth = 0
    foreach ($line in ($parts[1].Replace('\bottomrule', '') -split '\r?\n')) {
        if ($startRow -and $line.Trim() -and $line -notmatch '^\\(?:bottomrule|end\{longtable\})') {
            $shade = if ($row % 2 -eq 0) { 'rowshade' } else { 'white' }
            [void]$body.AppendLine('\rowcolor{' + $shade + '}')
            $row++
            $startRow = $false
        }
        [void]$body.AppendLine($line)
        $depth += [regex]::Matches($line, '\\begin\{').Count - [regex]::Matches($line, '\\end\{(?!longtable\})').Count
        if ($depth -eq 0 -and $line -match '\\\\\s*$') { $startRow = $true }
    }
    $spec + $header + "\endfirsthead`n" + $continued + $header + "\endhead`n\bottomrule`n\endfoot" + $body.ToString()
})
# Title labels resolve after LaTeX's page break; Pandoc's preceding hypertarget may be on the prior page.
$labels = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($label in [regex]::Matches($tex, '\\label\{([^}]+)\}')) { [void]$labels.Add($label.Groups[1].Value) }
$tex = [regex]::Replace($tex, '\\hyperlink\{([^}]+)\}', {
    param($match)
    if ($labels.Contains($match.Groups[1].Value)) { '\hyperref[' + $match.Groups[1].Value + ']' } else { $match.Value }
})
[IO.File]::WriteAllText($texPath, ('% !TEX root = main.tex' + [Environment]::NewLine + $tex), (New-Object Text.UTF8Encoding($false)))
