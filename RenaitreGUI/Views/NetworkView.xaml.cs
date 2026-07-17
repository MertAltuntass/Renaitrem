using System.IO;
using System.Windows;
using System.Windows.Controls;
using RenaitreGUI.Services;

namespace RenaitreGUI.Views;

public partial class NetworkView : Page
{
    private readonly PowerShellService _ps = new();
    private CancellationTokenSource? _cts;

    public NetworkView() => InitializeComponent();

    private void AppendLine(string line)
        => Dispatcher.Invoke(() =>
        {
            TerminalOutput.Text += line + "\n";
            TerminalOutput.ScrollToEnd();
        });

    private async void RunTool_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button btn) return;
        var tag = btn.Tag?.ToString();
        if (string.IsNullOrEmpty(tag)) return;

        string cmd = tag switch
        {
            "PRINT_QUEUE"       => BuildPrintQueueScript(),
            "TELEMETRY_DISABLE" => BuildTelemetryScript(false),
            "TELEMETRY_ENABLE"  => BuildTelemetryScript(true),
            "GET_PUBLIC_IP"     => BuildGetPublicIpScript(),
            "WIFI_PROFILES"     => BuildWifiProfilesScript(),
            _                   => tag
        };

        await RunCommand(cmd);
    }

    private async void DangerTool_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button btn) return;
        var tag = btn.Tag?.ToString();
        if (string.IsNullOrEmpty(tag)) return;

        if (!ConfirmDialog.Show(Window.GetWindow(this), "Tehlikeli İşlem",
                $"Bu işlem geri alınamayabilir. Devam etmek istiyor musun?\n\n({tag})"))
            return;

        string cmd = tag switch
        {
            "NETWORK_RESET"    => BuildNetworkResetScript(),
            "WIN_UPDATE_CLEAN" => BuildWinUpdateCleanScript(),
            "CHROME_CLEAR"     => BuildChromeClearScript(),
            _                  => tag
        };

        await RunCommand(cmd);
    }

    private async void KillApp_Click(object sender, RoutedEventArgs e)
    {
        var app = KillAppBox.Text.Trim();
        if (string.IsNullOrEmpty(app)) return;
        await RunCommand($"taskkill /im \"{app}\" /f");
    }

    private async Task RunCommand(string cmdOrScript)
    {
        _cts?.Cancel();
        _cts = new CancellationTokenSource();
        StopBtn.IsEnabled = true;
        TerminalOutput.Text = $"> Running...\n";

        try
        {
            if (cmdOrScript.Contains('\n'))
                await _ps.RunScriptAsync(cmdOrScript, AppendLine, _cts.Token);
            else
                await _ps.RunCommandAsync(cmdOrScript, [], AppendLine, _cts.Token);
        }
        catch (OperationCanceledException) { AppendLine("\n[Stopped]"); }
        finally { StopBtn.IsEnabled = false; }
    }

    private void StopBtn_Click(object sender, RoutedEventArgs e) => _cts?.Cancel();
    private void ClearBtn_Click(object sender, RoutedEventArgs e) => TerminalOutput.Text = "> Ready.\n";

    // --- Script builders ---
    // Bu makinede kayıtlı Wi-Fi profilleri + şifreleri (yerel kimlik kurtarma)
    private static string BuildWifiProfilesScript() => @"
$profiles = (netsh wlan show profiles) |
    Select-String 'All User Profile|Tüm Kullanıcı Profili' |
    ForEach-Object { ($_ -split ':')[1].Trim() }
if (-not $profiles) { Write-Host 'Kayıtlı Wi-Fi profili bulunamadı.'; return }
Write-Host ('{0,-32} {1}' -f 'AĞ ADI', 'ŞİFRE')
Write-Host ('-' * 50)
foreach ($p in $profiles) {
    $info = netsh wlan show profile name=""$p"" key=clear
    $keyLine = $info | Select-String 'Key Content|Anahtar İçeriği'
    $key = if ($keyLine) { ($keyLine -split ':')[1].Trim() } else { '(açık ağ / şifre yok)' }
    Write-Host ('{0,-32} {1}' -f $p, $key)
}
";

    private static string BuildNetworkResetScript() => @"
netsh int ip reset reset.txt
netsh winsock reset
netsh advfirewall reset
netsh winhttp reset proxy
ipconfig /release
ipconfig /renew
ipconfig /flushdns
ipconfig /registerdns
Write-Host 'Network reset complete. Restart recommended.'
";

    private static string BuildWinUpdateCleanScript() => @"
Stop-Service wuauserv -Force
Remove-Item -Path $env:SystemRoot\SoftwareDistribution -Recurse -Force -ErrorAction SilentlyContinue
regsvr32 /s wuaueng.dll
regsvr32 /s wucltui.dll
regsvr32 /s wups.dll
Start-Service wuauserv
Write-Host 'Windows Update cache cleared.'
";

    private static string BuildChromeClearScript()
    {
        var path = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Google", "Chrome", "User Data", "Default");
        return $@"
$chromePath = '{path}'
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
@('Cache','Media Cache','GPUCache','Local Storage') | ForEach-Object {{
    $p = Join-Path $chromePath $_
    if (Test-Path $p) {{ Remove-Item $p -Recurse -Force; New-Item $p -ItemType Directory | Out-Null }}
}}
@('History','Cookies','Favicons','Web Data') | ForEach-Object {{
    $p = Join-Path $chromePath $_
    if (Test-Path $p) {{ Remove-Item $p -Force -ErrorAction SilentlyContinue }}
}}
Write-Host 'Chrome data cleared.'
";
    }

    private static string BuildPrintQueueScript() => @"
Stop-Service spooler -Force
Remove-Item ""$env:SystemRoot\System32\spool\printers\*"" -Force -ErrorAction SilentlyContinue
Start-Service spooler
Write-Host 'Print queue cleared.'
";

    private static string BuildTelemetryScript(bool enable) => enable
        ? @"
sc.exe config dmwappushservice start= auto
sc.exe start dmwappushservice
sc.exe config diagtrack start= auto
sc.exe start DiagTrack
reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection /v AllowTelemetry /t REG_DWORD /d 1 /f
Write-Host 'Telemetry enabled.'
"
        : @"
sc.exe config dmwappushservice start= disabled
sc.exe stop dmwappushservice
sc.exe config diagtrack start= disabled
sc.exe stop DiagTrack
reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection /v AllowTelemetry /t REG_DWORD /d 0 /f
Write-Host 'Telemetry disabled.'
";

    private static string BuildGetPublicIpScript() => @"
$services = @('https://api.ipify.org', 'https://icanhazip.com', 'https://wtfismyip.com/text')
foreach ($s in $services) {
    try {
        $ip = (Invoke-WebRequest -Uri $s -UseBasicParsing -TimeoutSec 5).Content.Trim()
        if ($ip -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            Write-Host ""Public IP: $ip  (via $s)""
            return
        }
    } catch {
        Write-Host ""[skip] $s — $_""
    }
}
Write-Host 'Could not retrieve public IP.'
";
}
