# Optimize images by creating resized/compressed JPEG versions with -opt suffix
# Usage: Run from repository root in PowerShell: .\scripts\optimize-images.ps1

$imgDir = "assets/img"
$backupDir = Join-Path $imgDir "originals_backup"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

# Threshold in bytes (200 KB)
$threshold = 200KB
$maxWidth = 1600
$quality = 80

Add-Type -AssemblyName System.Drawing

Get-ChildItem -Path $imgDir -Recurse -File | Where-Object { $_.Extension -match '\.(jpg|jpeg|png)$' -and $_.Length -gt $threshold } | ForEach-Object {
    $file = $_.FullName
    $rel = $_.FullName.Substring((Get-Location).Path.Length+1)
    try {
        $img = [System.Drawing.Image]::FromFile($file)
        $origWidth = $img.Width
        $origHeight = $img.Height
        $ratio = [double]$origHeight / $origWidth

        if ($origWidth -gt $maxWidth) {
            $newWidth = $maxWidth
            $newHeight = [int]([math]::Round($newWidth * $ratio))
        } else {
            $newWidth = $origWidth
            $newHeight = $origHeight
        }

        # backup original
        $destBackup = Join-Path $backupDir $_.Name
        if (-not (Test-Path $destBackup)) { Copy-Item -Path $file -Destination $destBackup }

        # create resized bitmap
        $bmp = New-Object System.Drawing.Bitmap $newWidth, $newHeight
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.DrawImage($img, 0,0, $newWidth, $newHeight)

        $optPath = [System.IO.Path]::Combine( (Get-Item $file).DirectoryName, ([System.IO.Path]::GetFileNameWithoutExtension($file) + "-opt.jpg"))

        # get JPEG encoder
        $encoders = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()
        $jpeg = $encoders | Where-Object { $_.MimeType -eq 'image/jpeg' }
        $eps = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $eps.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $quality)
        $bmp.Save($optPath, $jpeg, $eps)

        $g.Dispose()
        $bmp.Dispose()
        $img.Dispose()

        Write-Host "Optimized:`t$($_.Name) -> $([System.IO.Path]::GetFileName($optPath)) (w:$newWidth)"
    } catch {
        Write-Warning "Failed to optimize $file : $_"
    }
}

Write-Host "Optimization complete. Optimized images stored alongside originals with '-opt.jpg' suffix. Originals backed up to $backupDir."