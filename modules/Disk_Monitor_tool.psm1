function Add-Data{
    param($name)
    $name | ForEach-Object {
    $_ | ConvertTo-Json -compress | Add-Content "logs\partition_log.jsonl"
    }

}

function Get-CurrenLog {
   @{
    Data= Get-partition | where-object DriveLetter | 
    ForEach-Object {
        @{
            DriveLetter=$_.DriveLetter
            size_GB=[math]::Round($_.size / 1GB , 2)
        }
    }
    date=(Get-Date).DateTime
}
}
function Get-driveDetails{
$last_log=Get-Content "logs\partition_log.jsonl" | Select-Object -Last 1 | ConvertFrom-Json

$current_log=Get-CurrenLog

if(-not $last_log){
    Add-Data $current_log 
    return
}
$changed = $false

if ($current_log.Data.Count -ne $last_log.Data.Count) {
    $changed = $true
}
else {
    foreach ($curr in $current_log.Data) {
        $prev = $last_log.Data | Where-Object DriveLetter -eq $curr.DriveLetter

        if (-not $prev -or $prev.Size_GB -ne $curr.Size_GB) {
            $changed = $true
            break
        }
    }
}

if($changed){
    Add-Data $current_log 
    }
}

Export-ModuleMember -Function Get-driveDetails
