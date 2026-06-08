# Convert JPG/PNG images to WebP at quality 80 using ImageMagick.
# Usage from repository root:
#   powershell -ExecutionPolicy Bypass -File scripts\convert-to-webp.ps1

$sourceDirs = @("assets/img", "assets/img/masonry-portfolio")
$backupDir = "assets/img/originals_backup"

if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

$images = Get-ChildItem -Path $sourceDirs -Recurse -Include *.jpg, *.jpeg, *.png -File

if ($images.Count -eq 0) {
    Write-Host "No JPG/PNG images found in $($sourceDirs -join ', ')"
    return
}

foreach ($img in $images) {
    $relative = $img.FullName.Substring((Get-Location).Path.Length + 1)
    $backupPath = Join-Path $backupDir $img.Name
    if (-not (Test-Path $backupPath)) {
        Copy-Item -Path $img.FullName -Destination $backupPath
    }

    $outputFile = Join-Path $img.DirectoryName ($img.BaseName + ".webp")
    $resizeArg = "1600x1600>"

    Write-Host "Converting: $relative -> $outputFile"
    magick convert "$($img.FullName)" -strip -quality 80 -resize $resizeArg "$outputFile"
}

Write-Host "Conversion complete. Backups saved to $backupDir."