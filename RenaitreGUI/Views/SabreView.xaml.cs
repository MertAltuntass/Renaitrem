using System.Windows;
using System.Windows.Controls;
using RenaitreGUI.Services;

namespace RenaitreGUI.Views;

public partial class SabreView : Page
{
    private readonly PowerShellService _ps = new();

    public SabreView()
    {
        InitializeComponent();
        ConfirmCheck.Checked   += (_, _) => RunSabreBtn.IsEnabled = true;
        ConfirmCheck.Unchecked += (_, _) => RunSabreBtn.IsEnabled = false;
    }

    private async void RunSabre_Click(object sender, RoutedEventArgs e)
    {
        if (!ConfirmDialog.Show(Window.GetWindow(this), "Son Onay — Sabre",
                "Bu işlem system32, temp, prefetch ve Windows klasörlerindeki geçici dosyaları silecek.\n\nEmin misin?"))
            return;

        RunSabreBtn.IsEnabled = false;
        ConfirmCheck.IsChecked = false;
        TerminalOutput.Text = "> Sabre running...\n";

        var script = BuildSabreScript();
        var cts = new CancellationTokenSource();

        try
        {
            await _ps.RunScriptAsync(script, line =>
                Dispatcher.Invoke(() =>
                {
                    TerminalOutput.Text += line + "\n";
                    TerminalOutput.ScrollToEnd();
                }), cts.Token);
        }
        catch (Exception ex) { TerminalOutput.Text += $"\n[ERR] {ex.Message}\n"; }
    }

    private static string BuildSabreScript() => @"
$logFolder = ""$env:USERPROFILE\Desktop\loglar""
if (!(Test-Path $logFolder)) { New-Item $logFolder -ItemType Directory | Out-Null }
$logFile = Join-Path $logFolder 'sabre_log.txt'

$targets = @(
    ""$env:windir\Temp"",
    ""$env:USERPROFILE\AppData\Local\Temp"",
    ""$env:windir\Prefetch"",
    ""$env:windir\SoftwareDistribution\Download""
)

foreach ($t in $targets) {
    Write-Host ""Cleaning: $t""
    Get-ChildItem $t -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    ""Cleaned: $t"" | Out-File $logFile -Append
}

# Windows Update servis reset
sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU) | Out-Null
sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU) | Out-Null

netsh winsock reset | Out-Null

sc config wuauserv start= auto | Out-Null
sc config bits start= auto | Out-Null
net start bits 2>$null
net start wuauserv 2>$null

Write-Host ""Sabre complete. Log: $logFile""
";
}
