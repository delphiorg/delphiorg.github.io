# Script to analyze tags and categories

$tags = @{}
$categories = @{}

$posts = Get-ChildItem -Path "../_posts" -Recurse -File

foreach ($post in $posts) {
    $content = Get-Content -Path $post.FullName
    $inFrontMatter = $false
    $currentSection = "" # "tags" or "categories"

    foreach ($line in $content) {
        if ($line -eq '---') {
            if ($inFrontMatter) { # End of front matter
                break
            } else { # Start of front matter
                $inFrontMatter = $true
                continue
            }
        }

        if ($inFrontMatter) {
            if ($line -match '^\s*tags:\s*(.*)') {
                $currentSection = "tags"
                $inlineValues = $matches[1]
                if ($inlineValues -and $inlineValues.Trim() -ne '') {
                    $inlineValues -split '[\[\],]' | ForEach-Object {
                        $val = $_.Trim().Trim("'").Trim('"')
                        if ($val) {
                            if ($tags.ContainsKey($val)) { $tags[$val]++ } else { $tags[$val] = 1 }
                        }
                    }
                }
                continue
            }
            if ($line -match '^\s*categories:\s*(.*)') {
                $currentSection = "categories"
                $inlineValues = $matches[1]
                if ($inlineValues -and $inlineValues.Trim() -ne '') {
                     $inlineValues -split '[\[\],]' | ForEach-Object {
                        $val = $_.Trim().Trim("'").Trim('"')
                        if ($val) {
                            if ($categories.ContainsKey($val)) { $categories[$val]++ } else { $categories[$val] = 1 }
                        }
                    }
                }
                continue
            }
            
            if ($line -match '^\s*-\s*(.*)') {
                $value = $matches[1].Trim().Trim("'").Trim('"')
                if ($currentSection -eq "tags") {
                    if ($tags.ContainsKey($value)) { $tags[$value]++ } else { $tags[$value] = 1 }
                } elseif ($currentSection -eq "categories") {
                    if ($categories.ContainsKey($value)) { $categories[$value]++ } else { $categories[$value] = 1 }
                }
            } elseif ($line -notlike ' *') {
                $currentSection = ""
            }
        }
    }
}

# Display report
Write-Host "Category Usage:" -ForegroundColor Yellow
$categories.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
    Write-Host (" - {0,-25} ({1} posts)" -f $_.Name, $_.Value)
}

Write-Host ""
Write-Host "Tag Usage:" -ForegroundColor Yellow
$tags.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
    Write-Host (" - {0,-25} ({1} posts)" -f $_.Name, $_.Value)
}
