function Get-Interfaces {
    $tsharkList = tshark -D

    $interfaces = @()

    foreach ($line in $tsharkList) {
        if ($line -match '^(\d+)\.\s+.+\((.+)\)') {
            $idx = [int]$matches[1]
            $name = $matches[2].ToLower()

            if ($name -match 'wi-?fi' -or $name -match 'ethernet') {
                $interfaces += $idx
            }
        }
    }

    return $interfaces
}

function Get-DomainNames {

    param(
        [string]$OutputFile = "$PSScriptRoot\..\logs\domains_log.csv"
    )

    $Tshark = "C:\Program Files\Wireshark\tshark.exe"

    if (!(Test-Path $Tshark)) {
        Write-Host "tshark not found."
        return
    }

    $processes = @{}
    $lastSeen = Get-Date
    $prev = ""

    function Start-Capture($iface) {

        Write-Host "Starting capture on interface $iface"

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Tshark
        $psi.Arguments = "-i $iface -l -q -Y `"dns || tls`" -T fields -e dns.qry.name -e tls.handshake.extensions_server_name"
        $psi.RedirectStandardOutput = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $proc.Start() | Out-Null

        return $proc
    }

    function Stop-All {
        foreach ($p in $processes.Values) {
            if ($p -and -not $p.HasExited) {
                $p.Kill()
                $p.WaitForExit()
            }
        }
        $processes.Clear()
    }

    $currentIfaces = Get-Interfaces

    foreach ($iface in $currentIfaces) {
        $processes[$iface] = Start-Capture $iface
    }

    $lastCheck = Get-Date

    while ($true) {

        # READ FROM ALL PROCESSES
        foreach ($iface in $processes.Keys) {

            $proc = $processes[$iface]

            if ($proc -and -not $proc.HasExited) {

                while ($proc.StandardOutput.Peek() -ge 0) {

                    $line = $proc.StandardOutput.ReadLine()
                    if (-not $line) { continue }

                    $parts = $line -split "\s+"

                    foreach ($domain in $parts) {

                        if ($domain -and $domain -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") {

                            if ($domain -ne $prev) {

                                $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                                "$time,$domain" | Add-Content -Path $OutputFile
                                Write-Host "$time  $domain"

                                $prev = $domain
                                $lastSeen = Get-Date
                            }
                        }
                    }
                }
            }
        }

        # RECHECK INTERFACES EVERY 5 MINUTES
        if ((Get-Date) - $lastCheck -gt (New-TimeSpan -Minutes 5)) {

            $newIfaces = Get-Interfaces

            if (-not (@($newIfaces) -join ',' -eq @($currentIfaces) -join ',')) {

                Write-Host "Interface change detected. Restarting all captures..."

                Stop-All

                $processes = @{}

                foreach ($iface in $newIfaces) {
                    $processes[$iface] = Start-Capture $iface
                }

                $currentIfaces = $newIfaces
                $lastSeen = Get-Date
            }

            $lastCheck = Get-Date
        }

        # OPTIONAL: restart if completely silent
        if ((Get-Date) - $lastSeen -gt (New-TimeSpan -Minutes 5)) {
            Write-Host "No traffic detected. Restarting captures..."

            Stop-All

            foreach ($iface in $currentIfaces) {
                $processes[$iface] = Start-Capture $iface
            }

            $lastSeen = Get-Date
        }

        Start-Sleep 2
    }
}

Export-ModuleMember -Function Get-DomainNames