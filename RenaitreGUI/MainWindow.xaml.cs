using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;
using RenaitreGUI.Services;
using RenaitreGUI.Views;

namespace RenaitreGUI;

public partial class MainWindow : Window
{
    private readonly Dictionary<string, Page> _pages = new();
    private Button? _activeNavBtn;
    private readonly DispatcherTimer _clockTimer;

    public MainWindow()
    {
        InitializeComponent();

        // Admin kontrolü — rozet metni ve rengi yetkiye göre
        if (AdminService.IsAdmin())
        {
            AdminBadge.Text = " [ADMIN]";
            AdminBadge.Foreground = (Brush)FindResource("AccentCyanBrush");
        }
        else
        {
            AdminBadge.Text = " [USER - bazı araçlar çalışmayabilir]";
            AdminBadge.Foreground = (Brush)FindResource("AccentRedBrush");
        }

        // Sayfaları ön yükle
        _pages["Dashboard"] = new DashboardView();
        _pages["AppStore"]  = new AppStoreView();
        _pages["Repair"]    = new RepairView();
        _pages["Network"]   = new NetworkView();
        _pages["Security"]  = new SecurityView();
        _pages["Pentest"]   = new PentestView();
        _pages["Sabre"]     = new SabreView();
        _pages["Settings"]  = new SettingsView();

        // Başlangıç sayfası
        ContentFrame.Navigate(_pages["Dashboard"]);
        _activeNavBtn = BtnDashboard;

        // Saat
        _clockTimer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(1) };
        _clockTimer.Tick += (_, _) => ClockText.Text = DateTime.Now.ToString("HH:mm:ss\ndd/MM/yyyy");
        _clockTimer.Start();
        ClockText.Text = DateTime.Now.ToString("HH:mm:ss\ndd/MM/yyyy");
    }

    private void NavBtn_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button btn) return;
        var tag = btn.Tag?.ToString();
        if (tag == null || !_pages.ContainsKey(tag)) return;

        // Stil güncelle
        if (_activeNavBtn != null)
            _activeNavBtn.Style = (Style)FindResource("NavButtonStyle");
        btn.Style = (Style)FindResource("NavButtonActiveStyle");
        _activeNavBtn = btn;

        ContentFrame.Navigate(_pages[tag]);
    }

    private void TitleBar_MouseLeftButtonDown(object sender, System.Windows.Input.MouseButtonEventArgs e)
        => DragMove();

    private void MinimizeBtn_Click(object sender, RoutedEventArgs e)
        => WindowState = WindowState.Minimized;

    private void CloseBtn_Click(object sender, RoutedEventArgs e)
        => Close();
}
