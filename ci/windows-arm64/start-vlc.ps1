<#
Checks that vlc.exe from an unpacked package uses its plugins.dat, then
starts it with the Qt interface, a portable profile and a video, and saves
a screenshot of its window. Fails when VLC skips entries of plugins.dat,
opens no window, exits early or does not close.
#>
param(
    [Parameter(Mandatory)] [string]$VlcDir,
    [Parameter(Mandatory)] [string]$Video,
    [Parameter(Mandatory)] [string]$Screenshot,
    [Parameter(Mandatory)] [string]$Log,
    [int]$PlaySeconds = 12
)
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class Desktop {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
        public int dmFields, dmPositionX, dmPositionY, dmDisplayOrientation, dmDisplayFixedOutput;
        public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
        public int dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2;
        public int dmPanningWidth, dmPanningHeight;
    }

    delegate bool EnumProc(IntPtr hwnd, IntPtr param);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr param);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern bool EnumDisplaySettings(string device, int mode, ref DEVMODE dm);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern int ChangeDisplaySettings(ref DEVMODE dm, int flags);

    public static List<IntPtr> VisibleWindows(uint pid) {
        var found = new List<IntPtr>();
        EnumWindows((h, p) => {
            uint owner;
            GetWindowThreadProcessId(h, out owner);
            if (owner == pid && IsWindowVisible(h))
                found.Add(h);
            return true;
        }, IntPtr.Zero);
        return found;
    }

    // Returns the result of ChangeDisplaySettings, 0 on success.
    public static int SetResolution(int width, int height) {
        var dm = new DEVMODE();
        dm.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
        EnumDisplaySettings(null, -1, ref dm);
        dm.dmPelsWidth = width;
        dm.dmPelsHeight = height;
        dm.dmFields = 0x80000 | 0x100000; // DM_PELSWIDTH | DM_PELSHEIGHT
        return ChangeDisplaySettings(ref dm, 0);
    }
}
'@

function Get-Rect([IntPtr]$hwnd) {
    $rect = New-Object Desktop+RECT
    [void][Desktop]::GetWindowRect($hwnd, [ref]$rect)
    $rect
}

# The runner's desktop starts at 1024x768, which is below the player's
# minimum layout. The display driver may refuse; the test still runs then.
$rc = [Desktop]::SetResolution(1920, 1080)
"display: ChangeDisplaySettings returned $rc"

# A fresh runner shows the first sign-in screen (wwahost.exe) above every
# other window, and the Start menu opens once it is gone.
Get-Process -Name WWAHost -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3
Get-Process -Name StartMenuExperienceHost -ErrorAction SilentlyContinue | Stop-Process -Force

New-Item -ItemType Directory -Force (Join-Path $VlcDir 'portable') | Out-Null
$exe = (Resolve-Path (Join-Path $VlcDir 'vlc.exe')).Path
# Service discovery opens sockets, and the firewall would otherwise ask
# whether to allow that in a dialog on top of the player.
New-NetFirewallRule -DisplayName 'VLC test' -Program $exe -Action Allow | Out-Null

# The plugin bank is loaded before any log module, so only the console log
# shows whether plugins.dat was used. A short run without interface is
# enough; writing a verbose console log through a redirect is slow enough
# to stall playback.
$check = Start-Process -FilePath $exe -ArgumentList @('-I', 'dummy', '--verbose=2', 'vlc://quit') `
    -RedirectStandardError $Log -PassThru
if (-not $check.WaitForExit(120000)) {
    Stop-Process -Id $check.Id -Force
    throw 'vlc.exe -I dummy vlc://quit did not exit within two minutes'
}
if (-not (Select-String -Path $Log -Pattern 'loading plugins cache file' -Quiet)) {
    throw 'VLC did not load plugins.dat'
}
$stale = @(Select-String -Path $Log -Pattern 'stale plugins cache')
if ($stale) {
    $stale | Select-Object -First 5 | ForEach-Object { $_.Line }
    throw "plugins.dat is stale for $($stale.Count) plugins"
}
'plugins.dat: used, no stale entries'

$vlcArgs = @(
    '--no-qt-privacy-ask'   # the first-run dialog would cover the player
    '--loop'
    '--no-qt-video-autoresize'   # keeps the window large enough for the controls
    '--file-logging'
    "--logfile=`"$((Resolve-Path $Log).Path)`""
    '--log-verbose=2'
    "`"$((Resolve-Path $Video).Path)`""
)
$vlc = Start-Process -FilePath $exe -ArgumentList $vlcArgs -PassThru
"vlc: PID $($vlc.Id)"

try {
    $window = $null
    for ($i = 0; $i -lt 60 -and -not $window; $i++) {
        Start-Sleep -Seconds 1
        if ($vlc.HasExited) { throw "vlc.exe exited with code $($vlc.ExitCode)" }
        $window = [Desktop]::VisibleWindows([uint32]$vlc.Id) |
            Sort-Object { $r = Get-Rect $_; ($r.Right - $r.Left) * ($r.Bottom - $r.Top) } |
            Select-Object -Last 1
    }
    if (-not $window) { throw 'vlc.exe opened no window within a minute' }

    Start-Sleep -Seconds $PlaySeconds
    if ($vlc.HasExited) { throw "vlc.exe exited with code $($vlc.ExitCode)" }
    [void][Desktop]::SetForegroundWindow($window)
    $r = Get-Rect $window
    $width = $r.Right - $r.Left
    $height = $r.Bottom - $r.Top
    "window: ${width}x$height at $($r.Left),$($r.Top)"
    # The player hides its controls while the mouse rests, and shows them
    # again for a moment when it moves.
    foreach ($dx in 0, 40, 80) {
        [void][Desktop]::SetCursorPos($r.Left + 300 + $dx, $r.Top + 300)
        Start-Sleep -Milliseconds 100
    }

    $bitmap = New-Object System.Drawing.Bitmap $width, $height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($r.Left, $r.Top, 0, 0, $bitmap.Size)
    $graphics.Dispose()
    $bitmap.Save($Screenshot, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    "screenshot: $Screenshot"
}
finally {
    # Closed like a user would, so VLC flushes its log and shuts down cleanly.
    if (-not $vlc.HasExited) {
        [void]$vlc.CloseMainWindow()
        if (-not $vlc.WaitForExit(20000)) {
            Stop-Process -Id $vlc.Id -Force
            $vlc.WaitForExit()
            throw 'vlc.exe did not exit within 20 s of closing its window'
        }
    }
}
