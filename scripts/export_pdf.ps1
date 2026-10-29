$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}

$htmlFile = "D:\DBMS DA - RESTAURANT MANGEMENT\DA3_PROJECT_REPORT.html"
$pdfFile = "D:\DBMS DA - RESTAURANT MANGEMENT\DA3_PROJECT_REPORT.pdf"

$tempUserData = Join-Path ([System.IO.Path]::GetTempPath()) ("edge_pdf_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $tempUserData | Out-Null

Write-Host "Converting $htmlFile to $pdfFile..."
$argList = @(
    "--headless=new",
    "--user-data-dir=`"$tempUserData`"",
    "--disable-gpu",
    "--no-pdf-header-footer",
    "--print-to-pdf=`"$pdfFile`"",
    "`"$htmlFile`""
)

$p = Start-Process -FilePath $edgePath -ArgumentList $argList -PassThru -Wait
Start-Sleep -Seconds 3

Write-Host "PDF Exists: $(Test-Path $pdfFile)"
if (Test-Path $pdfFile) {
    $len = (Get-Item $pdfFile).Length
    Write-Host "PDF Size: $len bytes"
}

Remove-Item -Path $tempUserData -Recurse -Force -ErrorAction SilentlyContinue
