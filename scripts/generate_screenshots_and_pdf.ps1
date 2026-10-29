$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}

$outputDir = "D:\DBMS DA - RESTAURANT MANGEMENT\docs\screenshots"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$tempUserData = Join-Path ([System.IO.Path]::GetTempPath()) ("edge_shot_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $tempUserData | Out-Null

function Take-Screen($url, $file) {
    Write-Host "Capturing $url -> $file..."
    $p = Start-Process -FilePath $edgePath -ArgumentList `
        "--headless=new", `
        "--user-data-dir=`"$tempUserData`"", `
        "--disable-gpu", `
        "--window-size=1280,950", `
        "--screenshot=`"$file`"", `
        "$url" `
        -PassThru -Wait
    Start-Sleep -Seconds 1
    Write-Host "$file exists: $(Test-Path $file)"
}

Take-Screen "http://127.0.0.1:5000/surreal?tab=console" "$outputDir\surreal_console.png"
Take-Screen "http://127.0.0.1:5000/surreal?tab=kitchen" "$outputDir\surreal_kitchen.png"
Take-Screen "http://127.0.0.1:5000/surreal?tab=graph" "$outputDir\surreal_graph.png"
Take-Screen "http://127.0.0.1:5000/surreal?tab=benchmarks" "$outputDir\surreal_benchmarks.png"

# Now generate PDF
$htmlReport = "D:\DBMS DA - RESTAURANT MANGEMENT\DA3_PROJECT_REPORT.html"
$pdfReport = "D:\DBMS DA - RESTAURANT MANGEMENT\DA3_PROJECT_REPORT.pdf"
Write-Host "Printing PDF to $pdfReport..."
$fileUrl = "file:///" + $htmlReport.Replace("\", "/")
$p = Start-Process -FilePath $edgePath -ArgumentList `
    "--headless=new", `
    "--user-data-dir=`"$tempUserData`"", `
    "--disable-gpu", `
    "--no-pdf-header-footer", `
    "--print-to-pdf=`"$pdfReport`"", `
    "$fileUrl" `
    -PassThru -Wait
Start-Sleep -Seconds 2
Write-Host "$pdfReport exists: $(Test-Path $pdfReport)"
if (Test-Path $pdfReport) {
    Write-Host "PDF size: $((Get-Item $pdfReport).Length) bytes"
}

Remove-Item -Path $tempUserData -Recurse -Force -ErrorAction SilentlyContinue
