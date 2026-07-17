using System.Windows;
using System.Windows.Input;
using System.Windows.Media;

namespace RenaitreGUI.Views;

public partial class ConfirmDialog : Window
{
    private ConfirmDialog() => InitializeComponent();

    /// <summary>Cyberpunk temalı onay penceresi. true = kullanıcı onayladı.</summary>
    public static bool Show(Window? owner, string title, string message,
                            string confirmText = "Devam", bool danger = true)
    {
        var dlg = new ConfirmDialog
        {
            Owner = owner ?? Application.Current?.MainWindow
        };
        dlg.TitleText.Text = title;
        dlg.MessageText.Text = message;
        dlg.ConfirmBtn.Content = confirmText;

        if (!danger)
        {
            // Tehlikeli değilse magenta yerine cyan vurgusu
            dlg.GlowFx.Color = Color.FromRgb(0x1E, 0xE9, 0xE0);
            dlg.IconText.Text = "◆";
            dlg.IconText.Foreground = (Brush)dlg.FindResource("AccentCyanBrush");
            dlg.ConfirmBtn.Style = (Style)dlg.FindResource("ActionButtonStyle");
        }

        return dlg.ShowDialog() == true;
    }

    private void Confirm_Click(object sender, RoutedEventArgs e) { DialogResult = true; Close(); }
    private void Cancel_Click(object sender, RoutedEventArgs e) { DialogResult = false; Close(); }

    private void Window_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState == MouseButtonState.Pressed) DragMove();
    }
}
