using System.Windows;
using System.Windows.Controls;
using RenaitreGUI.Services;

namespace RenaitreGUI.Views;

public partial class RepairView : Page
{
    private readonly PowerShellService _ps = new();
    private CancellationTokenSource? _cts;

    public RepairView() => InitializeComponent();

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
        await Run(tag);
    }

    private async void DangerTool_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button btn) return;
        var tag = btn.Tag?.ToString();
        if (string.IsNullOrEmpty(tag)) return;

        if (!ConfirmDialog.Show(Window.GetWindow(this), "Onay",
                $"Bu işlem geri alınamayabilir. Devam?\n\n({btn.Content})"))
            return;

        await Run(tag);
    }

    private async Task Run(string tag)
    {
        var (label, cmd) = Resolve(tag);

        _cts?.Cancel();
        _cts = new CancellationTokenSource();
        StopBtn.IsEnabled = true;
        TerminalOutput.Text = $"> {label}\n";

        try
        {
            if (cmd.Contains('\n'))
                await _ps.RunScriptAsync(cmd, AppendLine, _cts.Token);
            else
                await _ps.RunCommandAsync(cmd, [], AppendLine, _cts.Token);
            AppendLine("\n[bitti]");
        }
        catch (OperationCanceledException) { AppendLine("\n[durduruldu]"); }
        catch (Exception ex) { AppendLine($"[ERR] {ex.Message}"); }
        finally { StopBtn.IsEnabled = false; }
    }

    private static (string label, string cmd) Resolve(string tag) => tag switch
    {
        "SFC"               => ("SFC Tarama (birkaç dakika sürebilir)", "sfc /scannow"),
        "DISM"              => ("DISM Onarım (uzun sürebilir)", "DISM /Online /Cleanup-Image /RestoreHealth"),
        "CHKDSK"            => ("Disk Kontrol (çevrimiçi tarama)", "chkdsk C: /scan"),
        "DNS_FLUSH"         => ("DNS önbelleği temizleniyor", "ipconfig /flushdns"),
        "WSRESET"           => ("Microsoft Store önbelleği sıfırlanıyor", "wsreset.exe"),
        "RESTORE_POINT"     => ("Geri yükleme noktası oluşturuluyor", RestorePointScript()),
        "CLEAR_TEMP"        => ("Temp klasörleri temizleniyor", ClearTempScript()),
        "EMPTY_RECYCLE"     => ("Geri dönüşüm kutusu boşaltılıyor", EmptyRecycleScript()),
        "RESTART_EXPLORER"  => ("Explorer yeniden başlatılıyor", RestartExplorerScript()),
        _                   => (tag, tag)
    };

    private void StopBtn_Click(object sender, RoutedEventArgs e) => _cts?.Cancel();
    private void ClearBtn_Click(object sender, RoutedEventArgs e) => TerminalOutput.Text = "> Ready.\n";

    // --- Script builders ---
    private static string ClearTempScript() => @"
$paths = @(""$env:TEMP"", ""$env:SystemRoot\Temp"")
foreach ($p in $paths) {
    Write-Host ""Cleaning: $p""
    Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}
Write-Host 'Temp klasörleri temizlendi.'
";

    private static string EmptyRecycleScript() => @"
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    Write-Host 'Geri dönüşüm kutusu boşaltıldı.'
} catch {
    Write-Host ""Boşaltılamadı ya da zaten boş: $($_.Exception.Message)""
}
";

    private static string RestartExplorerScript() => @"
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer }
Write-Host 'Explorer yeniden başlatıldı.'
";

    private static string RestorePointScript() => @"
try {
    Enable-ComputerRestore -Drive ""$env:SystemDrive\"" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description 'RenaitreSabre Manual' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
    Write-Host 'Geri yükleme noktası oluşturuldu.'
} catch {
    Write-Host ""Oluşturulamadi: $($_.Exception.Message)""
    Write-Host 'Not: Sistem Koruması açık olmalı; ayrıca 24 saatte bir sınır olabilir.'
}
";
}
