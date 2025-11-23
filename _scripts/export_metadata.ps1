# This script performs a two-pass analysis to enrich the metadata export.
# Pass 1: Gathers all data and calculates global tag counts.
# Pass 2: Uses the global counts to create the final enriched data for the CSV.

Write-Host "Analyzing posts..." -ForegroundColor Cyan

$allPostsData = [System.Collections.Generic.List[object]]::new()
$globalTagCounts = @{}

$posts = Get-ChildItem -Path "_posts" -Recurse -File

# --- PASS 1: Extract all data and count tags ---
Write-Host "Pass 1: Reading all posts and calculating tag counts..."
foreach ($post in $posts) {
    $content = Get-Content -Path $post.FullName -Raw

    # Extract front matter block
    $frontMatterMatch = [regex]::Match($content, '(?sm)^---\s*$(.*?)^---\s*$')
    if (-not $frontMatterMatch.Success) { continue }
    
    $frontMatter = $frontMatterMatch.Groups[1].Value
    $frontMatterLines = $frontMatter.Split([System.Environment]::NewLine)

    # Extract simple key-value pairs
    $title = ($frontMatterLines | Where-Object { $_ -match '^\s*title:' } | Select-Object -First 1) -replace '^\s*title:\s*', '' | ForEach-Object { $_.Trim().Trim("'").Trim('"') }
    $date = ($frontMatterLines | Where-Object { $_ -match '^\s*date:' } | Select-Object -First 1) -replace '^\s*date:\s*', '' | ForEach-Object { $_.Trim().Trim("'").Trim('"') }
    $author = ($frontMatterLines | Where-Object { $_ -match '^\s*author:' } | Select-Object -First 1) -replace '^\s*author:\s*', '' | ForEach-Object { $_.Trim().Trim("'").Trim('"') }

    # Extract tags and categories
    $inTags, $inCategories = $false, $false
    $tagList = New-Object System.Collections.Generic.List[string]
    $categoryList = New-Object System.Collections.Generic.List[string]

    foreach ($line in $frontMatterLines) {
        if ($line -match '^\s*tags:') { $inTags = $true; $inCategories = $false; continue }
        if ($line -match '^\s*categories:') { $inCategories = $true; $inTags = $false; continue }
        if ($line -notmatch '^\s*-' -and $line -match ':') { $inTags = $false; $inCategories = $false; continue }

        if ($line -match '^\s*-\s*(.*)') {
            $value = $matches[1].Trim().Trim("'").Trim('"')
            if ($inTags) { $tagList.Add($value) }
            if ($inCategories) { $categoryList.Add($value) }
        }
    }

    # Add to global counts
    foreach ($tag in $tagList) {
        if ($globalTagCounts.ContainsKey($tag)) { $globalTagCounts[$tag]++ } else { $globalTagCounts[$tag] = 1 }
    }

    # Store post data for the second pass
    $postData = [PSCustomObject]@{
        filename   = $post.Name
        title      = $title
        date       = $date
        author     = $author
        categories = $categoryList
        tags       = $tagList
    }
    $allPostsData.Add($postData)
}

Write-Host "Found $($globalTagCounts.Count) unique tags across $($allPostsData.Count) posts." -ForegroundColor Green


# --- PASS 2: Build final data for CSV ---
Write-Host "Pass 2: Generating enriched data for CSV..."
$dataForCsv = @()
foreach ($postData in $allPostsData) {

    $enrichedTags = New-Object System.Collections.Generic.List[string]
    foreach ($tag in $postData.tags) {
        $count = $globalTagCounts[$tag]
        $enrichedTags.Add("$tag ($count)")
    }

    $csvRecord = [ordered]@{
        filename   = $postData.filename
        title      = $postData.title
        date       = $postData.date
        author     = $postData.author
        categories = $postData.categories -join ", "
        tags       = $enrichedTags -join ", "
        tag_count  = $postData.tags.Count
    }
    $dataForCsv += [PSCustomObject]$csvRecord
}


# --- Export to CSV ---
$outputPath = "metadata.csv"
Write-Host "Exporting enriched metadata to $outputPath..." -ForegroundColor Cyan
$dataForCsv | Export-Csv -Path $outputPath -NoTypeInformation -Force

Write-Host "Successfully created $outputPath with tag counts." -ForegroundColor Green
