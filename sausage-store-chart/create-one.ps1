Get-ChildItem -Recurse -Include *.yaml, *.tpl -Exclude sausage-store-all.yaml | Sort-Object FullName | ForEach-Object {
    "# $($_.FullName)"
    Get-Content $_.FullName
    ""
} | Out-File -Encoding UTF8 sausage-store-all.yaml