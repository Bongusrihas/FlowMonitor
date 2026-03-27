function Get-Connection {
    @(
        netsh interface ipv4 show interfaces | Select-Object -Skip 3 |
        Where-Object { $_ -match 'connected' } |
        ForEach-Object {
        if ($_ -match '^\s*(\d+)\s+\d+\s+\d+\s+connected\s+(.+)$') {
            @{
                Idx  = [int]$matches[1]
                Name = $matches[2].Trim()
                }
            }
        } | Where-Object { $_.Name -ne 'Loopback Pseudo-Interface 1' })[0]
}

function Get-DomainNames {
    param(
        [string]$OutputFile = "$PSScriptRoot\..\logs\domains_log.csv"
    )

    $Tshark = "C:\Program Files\Wireshark\tshark.exe"
    $prev = ""
    $currentInterface = -1

    while ($true) {
        $conn = Get-Connection
        if (-not $conn) {
            Write-Host "No active interface. Retrying in 10s..."
            Start-Sleep 10
            continue
        }

        if ($conn.Idx -ne $currentInterface) {
            $currentInterface = $conn.Idx
            Write-Host "Using Interface: $($conn.Name) (Index: $currentInterface)"
            # Start tshark as a streaming process
            $process = & $Tshark -i $currentInterface -q `
                -Y "dns.qry.name || tls.handshake.extensions_server_name" `
                -T fields `
                -e dns.qry.name `
                -e tls.handshake.extensions_server_name |
            ForEach-Object {
                $parts = $_ -split "\s+"
                foreach ($domain in $parts) {
                    if ($domain -and $domain -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") {
                        if ($domain -ne $prev) {
                            $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            "$time,$domain" | Add-Content -Path $OutputFile -Encoding utf8
                            Write-Host "$time  $domain"
                            $prev = $domain
                        }
                    }
                }
            }
        }

        # Wait 60 seconds and recheck interface
        Start-Sleep 60
    }
}

Export-ModuleMember -Function Get-DomainNames
