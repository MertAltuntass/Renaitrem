using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using RenaitreGUI.Services;

namespace RenaitreGUI.Views;

public partial class SettingsView : Page
{
    public SettingsView()
    {
        InitializeComponent();
        TxtOutputPath.Text = PowerShellService.OutputDir;
        TxtAbout.Text =
            $".NET     : {Environment.Version}\n" +
            $"OS       : {Environment.OSVersion.VersionString}\n" +
            $"Makine   : {Environment.MachineName}\n" +
            $"Kullanıcı: {Environment.UserName}\n" +
            $"Yetki    : {(AdminService.IsAdmin() ? "ADMINISTRATOR" : "STANDARD USER")}";
        RefreshLogInfo();
    }

    private void RefreshLogInfo()
    {
        try
        {
            if (File.Exists(App.LogFile))
            {
                var fi = new FileInfo(App.LogFile);
                TxtLogInfo.Text = $"error.log — {fi.Length / 1024.0:F1} KB, son değişiklik {fi.LastWriteTime:dd/MM/yyyy HH:mm}";
            }
            else TxtLogInfo.Text = "error.log — henüz hata kaydı yok.";
        }
        catch { TxtLogInfo.Text = ""; }
    }

    private void OpenFolder_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            Directory.CreateDirectory(PowerShellService.OutputDir);
            Process.Start(new ProcessStartInfo("explorer.exe", $"\"{PowerShellService.OutputDir}\"") { UseShellExecute = true });
        }
        catch (Exception ex) { App.LogError(ex, "OpenFolder"); }
    }

    private void OpenLog_Click(object sender, RoutedEventArgs e)
    {
        if (!File.Exists(App.LogFile))
        {
            ConfirmDialog.Show(Window.GetWindow(this), "Bilgi", "Henüz bir hata kaydı yok.", "Tamam", danger: false);
            return;
        }
        try { Process.Start(new ProcessStartInfo(App.LogFile) { UseShellExecute = true }); }
        catch (Exception ex) { App.LogError(ex, "OpenLog"); }
    }

    private void ClearLogs_Click(object sender, RoutedEventArgs e)
    {
        if (!File.Exists(App.LogFile))
        {
            RefreshLogInfo();
            return;
        }
        if (!ConfirmDialog.Show(Window.GetWindow(this), "Logları Temizle",
                "error.log dosyası silinecek. Devam?"))
            return;
        try { File.Delete(App.LogFile); }
        catch (Exception ex) { App.LogError(ex, "ClearLogs"); }
        RefreshLogInfo();
    }
}
