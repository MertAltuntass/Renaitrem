using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using RenaitreGUI.Services;

namespace RenaitreGUI.Views;

public partial class AppStoreView : Page
{
    private readonly WingetService _winget = new();
    private CancellationTokenSource? _cts;

    public AppStoreView() => InitializeComponent();

    private void AppendLine(string line)
        => Dispatcher.Invoke(() =>
        {
            TerminalOutput.Text += line + "\n";
            TerminalOutput.ScrollToEnd();
        });

    private async void SearchBtn_Click(object sender, RoutedEventArgs e)
    {
        var q = SearchBox.Text.Trim();
        if (string.IsNullOrEmpty(q)) return;

        ClearResults();

        List<WingetPackage> results = [];
        await RunWithOutput($"Searching: {q}", async () =>
        {
            results = await _winget.SearchStructuredAsync(q, AppendLine, _cts!.Token);
        });

        if (results.Count > 0)
            Dispatcher.Invoke(() => ShowResults(results));
    }

    private void SearchBox_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter) SearchBtn_Click(sender, e);
    }

    private async void QuickInstall_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button btn) return;
        var id = btn.Tag?.ToString();
        if (string.IsNullOrEmpty(id)) return;
        ClearResults();
        await RunWithOutput($"Installing: {id}", () => _winget.InstallAsync(id, AppendLine, _cts!.Token));
    }

    private async void UpgradeAllBtn_Click(object sender, RoutedEventArgs e)
    {
        ClearResults();
        await RunWithOutput("Upgrading all packages...", () => _winget.UpgradeAllAsync(AppendLine, _cts!.Token));
    }

    private async void InstallById_Click(object sender, RoutedEventArgs e)
    {
        var id = CustomIdBox.Text.Trim();
        if (string.IsNullOrEmpty(id) || id == (string)CustomIdBox.Tag) return;
        ClearResults();
        await RunWithOutput($"Installing: {id}", () => _winget.InstallAsync(id, AppendLine, _cts!.Token));
    }

    private async void SearchResult_Install_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button btn) return;
        var id = btn.Tag?.ToString();
        if (string.IsNullOrEmpty(id)) return;
        ClearResults();
        await RunWithOutput($"Installing: {id}", () => _winget.InstallAsync(id, AppendLine, _cts!.Token));
    }

    private async Task RunWithOutput(string header, Func<Task> action)
    {
        _cts?.Cancel();
        _cts = new CancellationTokenSource();
        StopBtn.IsEnabled = true;
        TerminalOutput.Text = $"> {header}\n";

        try { await action(); }
        catch (OperationCanceledException) { AppendLine("\n[Stopped]"); }
        finally { StopBtn.IsEnabled = false; }
    }

    private void ClearResults()
    {
        ResultsList.Children.Clear();
        ResultsBorder.Visibility = Visibility.Collapsed;
    }

    private void ShowResults(List<WingetPackage> results)
    {
        ResultsList.Children.Clear();
        ResultsCountText.Text = $"RESULTS  ({results.Count} found)";

        var textPrimary  = (Brush)FindResource("TextPrimaryBrush");
        var textMuted    = (Brush)FindResource("TextMutedBrush");
        var bgPrimary    = (Brush)FindResource("BgPrimaryBrush");
        var borderBrush  = (Brush)FindResource("BorderBrush2");
        var installStyle = (Style)FindResource("ActionButtonStyle");
        var font         = new FontFamily("Cascadia Mono, Consolas");

        foreach (var pkg in results)
        {
            var border = new Border
            {
                Padding         = new Thickness(8, 5, 8, 5),
                Margin          = new Thickness(0, 0, 0, 3),
                Background      = bgPrimary,
                BorderBrush     = borderBrush,
                BorderThickness = new Thickness(1),
                CornerRadius    = new CornerRadius(3)
            };

            var grid = new Grid();
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            var textPanel = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
            textPanel.Children.Add(new TextBlock
            {
                Text       = pkg.Name,
                Foreground = textPrimary,
                FontFamily = font,
                FontSize   = 12,
                FontWeight = FontWeights.SemiBold
            });
            textPanel.Children.Add(new TextBlock
            {
                Text       = pkg.Id,
                Foreground = textMuted,
                FontFamily = font,
                FontSize   = 10
            });

            var installBtn = new Button
            {
                Content             = "Install",
                Tag                 = pkg.Id,
                Style               = installStyle,
                Padding             = new Thickness(12, 4, 12, 4),
                FontSize            = 11,
                VerticalAlignment   = VerticalAlignment.Center,
                Margin              = new Thickness(12, 0, 0, 0)
            };
            installBtn.Click += SearchResult_Install_Click;

            Grid.SetColumn(textPanel, 0);
            Grid.SetColumn(installBtn, 1);
            grid.Children.Add(textPanel);
            grid.Children.Add(installBtn);

            border.Child = grid;
            ResultsList.Children.Add(border);
        }

        ResultsBorder.Visibility = Visibility.Visible;
    }

    private void StopBtn_Click(object sender, RoutedEventArgs e) => _cts?.Cancel();
    private void ClearBtn_Click(object sender, RoutedEventArgs e) => TerminalOutput.Text = "> Ready.\n";

    private void CustomIdBox_GotFocus(object sender, RoutedEventArgs e)
    {
        if (CustomIdBox.Text == (string)CustomIdBox.Tag)
        {
            CustomIdBox.Text = "";
            CustomIdBox.Foreground = (Brush)FindResource("TextPrimaryBrush");
        }
    }

    private void CustomIdBox_LostFocus(object sender, RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(CustomIdBox.Text))
        {
            CustomIdBox.Text = (string)CustomIdBox.Tag;
            CustomIdBox.Foreground = (Brush)FindResource("TextMutedBrush");
        }
    }
}
