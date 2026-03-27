$wallpaperPath = "$PSScriptRoot\logs\image.jpg"

Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@


if (Test-Path $wallpaperPath) {
    [Wallpaper]::SystemParametersInfo(20, 0, $wallpaperPath, 3)
    RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
} else {
    Write-Host "Image not found: $wallpaperPath"
}
