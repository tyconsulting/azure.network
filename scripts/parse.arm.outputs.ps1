param (
    [Parameter(Mandatory=$true)][string]$Output,
    [Parameter(Mandatory=$false)][string]$variableNameSuffix
)

$json = $Output | convertfrom-json
foreach ($member in $json.psobject.properties.name) {
    $value = $json.$member.value
    Write-verbose "$member : $value"
    if ($PSBoundParameters.ContainsKey('variableNameSuffix'))
    {
        $variableName = "$member"+"$variableNameSuffix"
    } else {
        $variableName = $member
    }
    Write-Host "##vso[task.setvariable variable=$variableName;]$value"
}
#endregion