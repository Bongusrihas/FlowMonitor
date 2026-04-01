function Get-Interfaces {
    $tsharkList = & tshark -D 2>$null
    $interfaces = @()

    foreach ($line in $tsharkList) {
        if ($line -match '^(\d+)\.\s+(.*)$') {
            $idx = [int]$matches[1]
            $desc = $matches[2].ToLower()

            if ($desc -match 'wi-?fi|wlan|ethernet') {
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

    # Auto-detect tshark
    $Tshark = (Get-Command tshark -ErrorAction SilentlyContinue).Source

    if (-not $Tshark) {
        Write-Host "tshark not found in PATH."
        return
    }

    # Ensure log directory exists
    $dir = Split-Path $OutputFile
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }

    $processes = @{}
    $lastSeen = Get-Date
    $prev = ""

    function Start-Capture($iface) {

        Write-Host "Starting capture on interface $iface"

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Tshark
        $psi.Arguments = "-i $iface -l -n -q -Y `"dns || tls.handshake.extensions_server_name`" -T fields -e dns.qry.name -e tls.handshake.extensions_server_name"
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
                try {
                    $p.Kill()
                    $p.WaitForExit()
                } catch {}
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

        foreach ($iface in @($processes.Keys)) {

            $proc = $processes[$iface]

            if ($proc -and -not $proc.HasExited) {

                while (!$proc.StandardOutput.EndOfStream) {

                    $line = $proc.StandardOutput.ReadLine()
                    if (-not $line) { continue }

                    $parts = $line -split "\s+"

                    foreach ($domain in $parts) {

                        if ($domain -and $domain -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") {

                            $domain = $domain.Trim()

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

        # Check for interface changes every 5 min
        if ((Get-Date) - $lastCheck -gt (New-TimeSpan -Minutes 5)) {

            $newIfaces = Get-Interfaces

            if (@($newIfaces) -join ',' -ne @($currentIfaces) -join ',') {

                Write-Host "Interface change detected. Restarting..."

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

        # Restart if no traffic
        if ((Get-Date) - $lastSeen -gt (New-TimeSpan -Minutes 5)) {

            Write-Host "No traffic detected. Restarting..."

            Stop-All
            $processes = @{}

            foreach ($iface in $currentIfaces) {
                $processes[$iface] = Start-Capture $iface
            }

            $lastSeen = Get-Date
        }

        Start-Sleep 2
    }
}

Export-ModuleMember -Function Get-DomainNames