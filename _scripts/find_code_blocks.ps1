$posts = Get-ChildItem -Path "../_posts" -Recurse -File

$filesToUpdate = @{}

$regex = '<!--\s*wp:syntaxhighlighter/code\s*{"language":"(.*?)"}\s*-->'

foreach ($post in $posts) {
    $content = Get-Content -Path $post.FullName -Raw -Encoding UTF8
    $matches = $content | Select-String -Pattern $regex -AllMatches

    if ($matches) {
        $languages = New-Object System.Collections.Generic.List[string]
        foreach ($match in $matches.Matches) {
            $lang = $match.Groups[1].Value
            if (-not $languages.Contains($lang)) {
                $languages.Add($lang)
            }
        }
        
        if ($languages.Count -gt 0) {
            $filesToUpdate[$post.Name] = $languages
        }
    }
}

if ($filesToUpdate.Count -eq 0) {
    Write-Host "No files with old WordPress code blocks found." -ForegroundColor Green
} else {
    Write-Host "Files with old WordPress code blocks:" -ForegroundColor Yellow
    foreach ($file in $filesToUpdate.Keys) {
        $langs = $filesToUpdate[$file] -join ", "
        Write-Host " - " -NoNewline
        Write-Host $file -ForegroundColor White -NoNewline
        Write-Host " (Languages: " -NoNewline
        Write-Host $langs -ForegroundColor Cyan -NoNewline
        Write-Host ")"
    }
}
