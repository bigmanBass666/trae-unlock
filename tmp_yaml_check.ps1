try {
    $y = Get-Content 'rules\workflow.yaml' -Raw | ConvertFrom-Yaml
    Write-Host "OK, rules count: $($y.Count)"
    foreach ($r in $y) {
        if ($r.id) { Write-Host "  - $($r.id): $($r.name)" }
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}
