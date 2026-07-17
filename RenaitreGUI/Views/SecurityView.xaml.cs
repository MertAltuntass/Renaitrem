using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using RenaitreGUI.Services;

namespace RenaitreGUI.Views;

public partial class SecurityView : Page
{
    private readonly PowerShellService _ps = new();
    private CancellationTokenSource? _cts;
    private bool _scanning;

    public SecurityView()
    {
        InitializeComponent();
        Loaded += (_, _) => { if (ResultsList.Children.Count == 0) RunScan(); };
    }

    private void Scan_Click(object sender, RoutedEventArgs e) => RunScan();

    private async void RunScan()
    {
        if (_scanning) return;
        _scanning = true;

        _cts?.Cancel();
        _cts = new CancellationTokenSource();
        ResultsList.Children.Clear();
        TxtStatus.Text = "taranıyor...";

        int ok = 0, warn = 0, bad = 0;

        void OnLine(string line) => Dispatcher.Invoke(() =>
        {
            var parts = line.Split('|');
            if (parts.Length != 3) return;
            switch (parts[1])
            {
                case "OK": ok++; break;
                case "WARN": warn++; break;
                case "BAD": bad++; break;
            }
            ResultsList.Children.Add(BuildRow(parts[0].Trim(), parts[1].Trim(), parts[2].Trim()));
        });

        try { await _ps.RunScriptAsync(ScanScript, OnLine, _cts.Token); }
        catch (OperationCanceledException) { }
        catch (Exception ex) { App.LogError(ex, "SecurityScan"); }

        TxtStatus.Text = bad > 0
            ? $"⛔ {bad} kritik, {warn} uyarı, {ok} iyi"
            : warn > 0 ? $"⚠ {warn} uyarı, {ok} iyi" : $"✓ hepsi iyi ({ok})";
        _scanning = false;
    }

    private Border BuildRow(string label, string state, string detail)
    {
        var (brushKey, pillText) = state switch
        {
            "OK"   => ("AccentSuccessBrush", "OK"),
            "WARN" => ("AccentAmberBrush", "UYARI"),
            "BAD"  => ("AccentRedBrush", "KRİTİK"),
            _      => ("AccentCyanBrush", "BİLGİ"),
        };
        var brush = (Brush)FindResource(brushKey);
        var mono = new FontFamily("Cascadia Mono, Consolas");

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var texts = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        texts.Children.Add(new TextBlock
        {
            Text = label, Foreground = (Brush)FindResource("TextPrimaryBrush"),
            FontFamily = mono, FontSize = 13, FontWeight = FontWeights.SemiBold
        });
        texts.Children.Add(new TextBlock
        {
            Text = detail, Foreground = (Brush)FindResource("TextMutedBrush"),
            FontFamily = mono, FontSize = 11, Margin = new Thickness(0, 3, 0, 0),
            TextWrapping = TextWrapping.Wrap
        });

        var pill = new Border
        {
            BorderBrush = brush, BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(5), Padding = new Thickness(10, 3, 10, 3),
            VerticalAlignment = VerticalAlignment.Center, Margin = new Thickness(12, 0, 0, 0),
            Child = new TextBlock { Text = pillText, Foreground = brush, FontFamily = mono, FontSize = 11, FontWeight = FontWeights.Bold }
        };

        Grid.SetColumn(texts, 0);
        Grid.SetColumn(pill, 1);
        grid.Children.Add(texts);
        grid.Children.Add(pill);

        return new Border
        {
            Style = (Style)FindResource("ToolCardStyle"),
            Padding = new Thickness(14, 11, 14, 11),
            Margin = new Thickness(0, 0, 0, 8),
            Child = grid
        };
    }

    // KEY|STATE|DETAIL  (STATE: OK / WARN / BAD / INFO)
    private const string ScanScript = @"
function Emit($k,$s,$d){ Write-Output ""$k|$s|$d"" }

try {
    $mp = Get-MpComputerStatus -ErrorAction Stop
    if ($mp.RealTimeProtectionEnabled) { Emit 'Windows Defender' 'OK' 'Gerçek zamanlı koruma açık' }
    else { Emit 'Windows Defender' 'BAD' 'Gerçek zamanlı koruma KAPALI' }
    $age = (New-TimeSpan -Start $mp.AntivirusSignatureLastUpdated -End (Get-Date)).Days
    if ($age -le 7) { Emit 'Defender İmzaları' 'OK' ""$age gün önce güncellendi"" }
    else { Emit 'Defender İmzaları' 'WARN' ""$age gündür güncellenmedi"" }
} catch { Emit 'Windows Defender' 'INFO' 'Durum okunamadı' }

try {
    $fw = Get-NetFirewallProfile -ErrorAction Stop
    $off = $fw | Where-Object { -not $_.Enabled }
    if ($off) { Emit 'Güvenlik Duvarı' 'BAD' (($off.Name -join ', ') + ' profili KAPALI') }
    else { Emit 'Güvenlik Duvarı' 'OK' 'Tüm profiller açık' }
} catch { Emit 'Güvenlik Duvarı' 'INFO' 'Durum okunamadı' }

try {
    $bl = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    if ($bl.ProtectionStatus -eq 'On') { Emit ""BitLocker ($env:SystemDrive)"" 'OK' 'Şifreleme açık' }
    else { Emit ""BitLocker ($env:SystemDrive)"" 'WARN' 'Şifreleme kapalı' }
} catch { Emit 'BitLocker' 'INFO' 'Desteklenmiyor / okunamadı' }

try {
    $uac = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -ErrorAction Stop).EnableLUA
    if ($uac -eq 1) { Emit 'UAC' 'OK' 'Kullanıcı Hesabı Denetimi etkin' }
    else { Emit 'UAC' 'BAD' 'UAC devre dışı' }
} catch { Emit 'UAC' 'INFO' 'Okunamadı' }

try {
    $wu = Get-Service wuauserv -ErrorAction Stop
    if ($wu.StartType -ne 'Disabled') { Emit 'Windows Update' 'OK' ""Servis: $($wu.Status) / $($wu.StartType)"" }
    else { Emit 'Windows Update' 'WARN' 'Servis devre dışı' }
} catch { Emit 'Windows Update' 'INFO' 'Okunamadı' }

$pending = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
if ($pending) { Emit 'Yeniden Başlatma' 'WARN' 'Bekleyen yeniden başlatma var' }
else { Emit 'Yeniden Başlatma' 'OK' 'Gerekmiyor' }
";
}
