param (
    [switch]$update,
    [switch]$dev,
    [switch]$force
)

# --- Check for latest version ---
Write-Host "Checking for the latest Prism.js version..." -ForegroundColor Cyan
try {
    $latestVersion = (Invoke-RestMethod -Uri "https://registry.npmjs.org/prismjs/latest").version
    Write-Host "Latest Prism.js version on npm is: " -ForegroundColor Green -NoNewline
    Write-Host $latestVersion -ForegroundColor Yellow
} catch {
    Write-Error "Failed to fetch the latest Prism.js version. Please check your internet connection."
    exit 1
}

# --- Get current local version ---
$currentVersion = ""
$versionFile = "prism_version.txt"
if (Test-Path $versionFile) {
    $currentVersion = Get-Content $versionFile
}

if ($currentVersion) {
    Write-Host "Current local version is:           " -ForegroundColor Green -NoNewline
    Write-Host $currentVersion -ForegroundColor Yellow
} else {
    Write-Host "No local version of Prism.js found." -ForegroundColor Yellow
}

# --- Main Logic ---
if ($update -or $force) {

    if ($latestVersion -eq $currentVersion -and -not $force) {
        Write-Host "Prism.js is already up to date." -ForegroundColor Green
        exit
    }

    # --- Perform Update ---
    Write-Host "----------------------------------"
    $suffix = if ($dev) { "" } else { ".min" }
    if ($dev) {
        Write-Host "Installing/Updating Prism.js (DEVELOPMENT non-minified version) to version $latestVersion..." -ForegroundColor Yellow
    } else {
        Write-Host "Installing/Updating Prism.js (minified version) to version $latestVersion..." -ForegroundColor Cyan
    }

    $files = @(
        @{
            url = "https://cdn.jsdelivr.net/npm/prismjs@$latestVersion/themes/prism-tomorrow.css"
            path = "../assets/css/prism-tomorrow.css"
        },
        @{
            url = "https://cdn.jsdelivr.net/npm/prismjs@$latestVersion/prism$suffix.js"
            path = "../assets/js/prism.js"
        },
        @{
            url = "https://cdn.jsdelivr.net/npm/prismjs@$latestVersion/components/prism-pascal$suffix.js"
            path = "../assets/js/prism-pascal.js"
            customize = $true # Flag for customization
        },
        @{
            url = "https://cdn.jsdelivr.net/npm/prismjs@$latestVersion/plugins/line-numbers/prism-line-numbers$suffix.css"
            path = "../assets/css/prism-line-numbers.css"
        },
        @{
            url = "https://cdn.jsdelivr.net/npm/prismjs@$latestVersion/plugins/toolbar/prism-toolbar$suffix.css"
            path = "../assets/css/prism-toolbar.css"
        },
        @{
            url = "https://cdn.jsdelivr.net/npm/prismjs@$latestVersion/plugins/line-numbers/prism-line-numbers$suffix.js"
            path = "../assets/js/prism-line-numbers.js"
        },
        @{
            url = "https://cdn.jsdelivr.net/npm/prismjs@$latestVersion/plugins/autolinker/prism-autolinker$suffix.js"
            path = "../assets/js/prism-autolinker.js"
        },
        @{
            url = "https://cdn.jsdelivr.net/npm/prismjs@$latestVersion/plugins/toolbar/prism-toolbar$suffix.js"
            path = "../assets/js/prism-toolbar.js"
        },
        @{
            url = "https://cdn.jsdelivr.net/npm/prismjs@$latestVersion/plugins/copy-to-clipboard/prism-copy-to-clipboard$suffix.js"
            path = "../assets/js/prism-copy-to-clipboard.js"
        }
    )

    foreach ($file in $files) {
        Write-Host "Downloading $($file.url)..."
        try {
            Invoke-WebRequest -Uri $file.url -OutFile $file.path
        } catch {
            Write-Error "Failed to download $($file.url). Update aborted."
            exit 1
        }

        if ($file.PSObject.Properties.Match('customize') -and $file.customize) {
            Write-Host "Customizing $($file.path)..."
            Add-Content -Path $file.path -Value "`nPrism.languages.delphi = Prism.languages.pascal;"
        }
    }

    $latestVersion | Out-File $versionFile
    Write-Host "Prism.js has been successfully updated to version $latestVersion." -ForegroundColor Green

} else {
    # --- Display Status and Help ---
    if ($latestVersion -ne $currentVersion) {
        if ($currentVersion) {
            Write-Host "A new version ($latestVersion) is available." -ForegroundColor Yellow
        } else {
            Write-Host "Prism.js is not installed locally." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Prism.js is up to date." -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "----------------------" -ForegroundColor White
    Write-Host "  .\update_prism.ps1 -update      (Installs the latest version if an update is available)"
    Write-Host "  .\update_prism.ps1 -update -dev (Installs the non-minified DEV version)"
    Write-Host "  .\update_prism.ps1 -update -force (Forces a re-installation of the latest version)"
}
