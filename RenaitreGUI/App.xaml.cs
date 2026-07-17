using System.IO;
using System.Windows;
using RenaitreGUI.Services;

namespace RenaitreGUI;

public partial class App : Application
{
    public static readonly string LogFile = Path.Combine(PowerShellService.OutputDir, "error.log");

    public App()
    {
        // UI thread'deki yakalanmamış hatalar
        DispatcherUnhandledException += (_, e) =>
        {
            LogError(e.Exception, "DispatcherUnhandledException");
            MessageBox.Show(
                $"Beklenmeyen hata oluştu:\n\n{e.Exception.Message}\n\nDetaylar log dosyasına yazıldı:\n{LogFile}",
                "RenaitreSabre — Hata",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
            e.Handled = true;
        };

        // UI dışı thread hataları (yalnızca logla — çökme kaçınılmaz olabilir)
        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
        {
            if (e.ExceptionObject is Exception ex) LogError(ex, "AppDomain.UnhandledException");
        };

        // Gözlemlenmeyen Task hataları
        TaskScheduler.UnobservedTaskException += (_, e) =>
        {
            LogError(e.Exception, "UnobservedTaskException");
            e.SetObserved();
        };
    }

    public static void LogError(Exception ex, string source)
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(LogFile)!);
            File.AppendAllText(LogFile, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] ({source})\n{ex}\n\n");
        }
        catch { /* loglama hatasını yut */ }
    }
}
