using System.IO;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Effects;
using System.Windows.Threading;
using RenaitreGUI.Services;

namespace RenaitreGUI.Views;

public partial class DashboardView : Page
{
    private readonly PowerShellService _ps = new();
    private readonly WingetService _winget = new();
    private CancellationTokenSource? _cts;

    private readonly DispatcherTimer _healthTimer;
    private ulong _prevIdle, _prevKernel, _prevUser;

    // Dinamik disk ölçerleri
    private sealed record DiskMeter(DriveInfo Drive, ColumnDefinition Fill, ColumnDefinition Rest, TextBlock Label, TextBlock Sub);
    private readonly List<DiskMeter> _disks = new();

    public DashboardView()
    {
        InitializeComponent();
        LoadSystemInfo();

        _healthTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(1.5) };
        _healthTimer.Tick += (_, _) => UpdateHealth();
        Loaded += (_, _) =>
        {
            BuildDiskMeters();
            PrimeCpu();
            _healthTimer.Start();
            UpdateHealth();
        };
        Unloaded += (_, _) => _healthTimer.Stop();
    }

    private void LoadSystemInfo()
    {
        TxtUser.Text = $"{Environment.UserDomainName}\\{Environment.UserName}";
        TxtMachine.Text = Environment.MachineName;

        if (AdminService.IsAdmin())
        {
            TxtPrivilege.Text = "ADMINISTRATOR";
            TxtPrivilege.Foreground = (Brush)FindResource("AccentSuccessBrush");
        }
        else
        {
            TxtPrivilege.Text = "STANDARD USER";
            TxtPrivilege.Foreground = (Brush)FindResource("AccentRedBrush");
        }

        TxtCpuSub.Text = $"{Environment.ProcessorCount} mantıksal çekirdek";
    }

    // ---------- Dinamik disk ölçerleri ----------
    private void BuildDiskMeters()
    {
        if (_disks.Count > 0) return; // sadece bir kez

        DriveInfo[] drives;
        try { drives = DriveInfo.GetDrives(); }
        catch { return; }

        foreach (var d in drives)
        {
            bool ready;
            try { ready = d.DriveType == DriveType.Fixed && d.IsReady; }
            catch { ready = false; }
            if (!ready) continue;

            var label = $"DISK {d.Name.TrimEnd('\\')}";
            var card = BuildMeterCard(label, "MeterDiskFill", "GlowSuccess",
                                      out var fill, out var rest, out var pct, out var sub);
            HealthGrid.Children.Add(card);
            _disks.Add(new DiskMeter(d, fill, rest, pct, sub));
        }

        // CPU + RAM (XAML'de 2 sabit) + disk sayısı kadar sütun
        HealthGrid.Columns = 2 + _disks.Count;
    }

    private Border BuildMeterCard(string label, string fillBrushKey, string glowKey,
                                  out ColumnDefinition fill, out ColumnDefinition rest, out TextBlock pct, out TextBlock sub)
    {
        var mono = new FontFamily("Cascadia Mono, Consolas");

        var top = new Grid { Margin = new Thickness(0, 0, 0, 10) };
        top.Children.Add(new TextBlock
        {
            Text = label,
            Foreground = (Brush)FindResource("TextMutedBrush"),
            FontFamily = mono, FontSize = 11,
            HorizontalAlignment = HorizontalAlignment.Left,
            TextTrimming = TextTrimming.CharacterEllipsis
        });
        pct = new TextBlock
        {
            Text = "--%", Foreground = Brushes.White,
            FontFamily = mono, FontSize = 18, FontWeight = FontWeights.Bold,
            HorizontalAlignment = HorizontalAlignment.Right
        };
        top.Children.Add(pct);

        fill = new ColumnDefinition { Width = new GridLength(0, GridUnitType.Star) };
        rest = new ColumnDefinition { Width = new GridLength(100, GridUnitType.Star) };
        var innerGrid = new Grid();
        innerGrid.ColumnDefinitions.Add(fill);
        innerGrid.ColumnDefinitions.Add(rest);
        var fillBorder = new Border
        {
            Background = (Brush)FindResource(fillBrushKey),
            CornerRadius = new CornerRadius(6),
            Effect = (Effect)FindResource(glowKey)
        };
        Grid.SetColumn(fillBorder, 0);
        innerGrid.Children.Add(fillBorder);

        var track = new Border { Style = (Style)FindResource("MeterTrackStyle"), Child = innerGrid };

        sub = new TextBlock
        {
            Text = "", Foreground = (Brush)FindResource("TextDimBrush"),
            FontFamily = mono, FontSize = 10, Margin = new Thickness(0, 8, 0, 0)
        };

        var sp = new StackPanel();
        sp.Children.Add(top);
        sp.Children.Add(track);
        sp.Children.Add(sub);

        return new Border
        {
            Style = (Style)FindResource("ToolCardStyle"),
            Margin = new Thickness(0, 0, 10, 0),
            Child = sp
        };
    }

    // ---------- Canlı metrikler ----------
    private void UpdateHealth()
    {
        SetMeter(CpuFill, CpuRest, GetCpuUsage(), TxtCpu);

        var (ramPct, usedGb, totalGb) = GetRam();
        SetMeter(RamFill, RamRest, ramPct, TxtRam);
        TxtRamSub.Text = $"{usedGb:F1} / {totalGb:F1} GB";

        foreach (var disk in _disks)
        {
            SetMeter(disk.Fill, disk.Rest, GetDiskUsage(disk.Drive), disk.Label);
            try { disk.Sub.Text = $"{disk.Drive.TotalFreeSpace / 1e9:F0} / {disk.Drive.TotalSize / 1e9:F0} GB boş"; }
            catch { disk.Sub.Text = ""; }
        }
    }

    private static void SetMeter(ColumnDefinition fill, ColumnDefinition rest, double pct, TextBlock pctLabel)
    {
        pct = Math.Clamp(pct, 0, 100);
        fill.Width = new GridLength(pct, GridUnitType.Star);
        rest.Width = new GridLength(100 - pct, GridUnitType.Star);
        pctLabel.Text = $"{Math.Round(pct)}%"; // CPU/RAM/DISK hepsinde yüzde kutusu
    }

    private void PrimeCpu()
    {
        if (GetSystemTimes(out var idle, out var kernel, out var user))
        {
            _prevIdle = ToUlong(idle);
            _prevKernel = ToUlong(kernel);
            _prevUser = ToUlong(user);
        }
    }

    private double GetCpuUsage()
    {
        if (!GetSystemTimes(out var idle, out var kernel, out var user)) return 0;
        ulong i = ToUlong(idle), k = ToUlong(kernel), u = ToUlong(user);

        ulong idleDiff = i - _prevIdle;
        ulong kernelDiff = k - _prevKernel;
        ulong userDiff = u - _prevUser;
        _prevIdle = i; _prevKernel = k; _prevUser = u;

        ulong total = kernelDiff + userDiff; // kernel idle'ı da içerir
        if (total == 0) return 0;
        return (total - idleDiff) * 100.0 / total;
    }

    private static (double pct, double usedGb, double totalGb) GetRam()
    {
        var mem = new MEMORYSTATUSEX { dwLength = (uint)Marshal.SizeOf<MEMORYSTATUSEX>() };
        if (!GlobalMemoryStatusEx(ref mem) || mem.ullTotalPhys == 0) return (0, 0, 0);
        double total = mem.ullTotalPhys, used = mem.ullTotalPhys - mem.ullAvailPhys;
        return (used * 100.0 / total, used / 1e9, total / 1e9);
    }

    private static double GetDiskUsage(DriveInfo d)
    {
        try
        {
            if (!d.IsReady || d.TotalSize == 0) return 0;
            double used = d.TotalSize - d.TotalFreeSpace;
            return used * 100.0 / d.TotalSize;
        }
        catch { return 0; }
    }

    // ---------- Quick actions ----------
    private async void QuickAction_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button btn) return;
        var cmd = btn.Tag?.ToString();
        if (string.IsNullOrEmpty(cmd)) return;

        _cts?.Cancel();
        _cts = new CancellationTokenSource();
        btn.IsEnabled = false;
        TerminalOutput.Text = $"> {cmd}\n";

        void append(string line) => Dispatcher.Invoke(() =>
        {
            TerminalOutput.Text += line + "\n";
            TerminalOutput.ScrollToEnd();
        });

        try
        {
            // winget admin oturumunda PATH'te olmayabilir → dayanıklı servise yönlendir
            if (cmd.StartsWith("winget", StringComparison.OrdinalIgnoreCase))
                await _winget.UpgradeAllAsync(append, _cts.Token);
            else
                await _ps.RunCommandAsync(cmd, [], append, _cts.Token);
        }
        catch (OperationCanceledException) { append("\n[Stopped]"); }
        finally { btn.IsEnabled = true; }
    }

    // ---------- Native interop ----------
    private static ulong ToUlong(System.Runtime.InteropServices.ComTypes.FILETIME ft)
        => ((ulong)(uint)ft.dwHighDateTime << 32) | (uint)ft.dwLowDateTime;

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetSystemTimes(
        out System.Runtime.InteropServices.ComTypes.FILETIME lpIdleTime,
        out System.Runtime.InteropServices.ComTypes.FILETIME lpKernelTime,
        out System.Runtime.InteropServices.ComTypes.FILETIME lpUserTime);

    [StructLayout(LayoutKind.Sequential)]
    private struct MEMORYSTATUSEX
    {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);
}
