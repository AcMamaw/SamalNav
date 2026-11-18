[CmdletBinding()]
param(
    [string] $ProjectName,
    [string] $ProjectRef,
    [string] $Region
)

$expectedProjectName = 'SamalNav-NonProduction'
$expectedProjectRef = 'iwzyasdanesaaxxjujxr'
$expectedRegion = 'ap-southeast-2'
$prohibitedProductionRef = 'kmypkzusxxlyojkzrrtn'

if ([string]::IsNullOrWhiteSpace($ProjectName) -or
    [string]::IsNullOrWhiteSpace($ProjectRef) -or
    [string]::IsNullOrWhiteSpace($Region)) {
    [Console]::Error.WriteLine('ABORT: Supply ProjectName, ProjectRef, and Region from the independently verified Supabase dashboard.')
    exit 1
}

if ($ProjectRef -eq $prohibitedProductionRef) {
    [Console]::Error.WriteLine('ABORT: The supplied project reference is the prohibited production project.')
    exit 1
}

if ($ProjectName -cne $expectedProjectName -or
    $ProjectRef -cne $expectedProjectRef -or
    $Region -cne $expectedRegion) {
    [Console]::Error.WriteLine('ABORT: Project identity does not exactly match the authorized non-production allowlist.')
    exit 1
}

Write-Output "Validated operator-supplied identity: $expectedProjectName ($expectedProjectRef, $expectedRegion)."
Write-Output 'This check does not connect to Supabase and does not execute SQL. Recheck the dashboard project immediately before any separately authorized manual action.'
