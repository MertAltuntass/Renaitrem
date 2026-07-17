using System.Diagnostics;
using System.Security.Principal;

namespace RenaitreGUI.Services;

public static class AdminService
{
    public static bool IsAdmin()
    {
        using var identity = WindowsIdentity.GetCurrent();
        var principal = new WindowsPrincipal(identity);
        return principal.IsInRole(WindowsBuiltInRole.Administrator);
    }

    // Admin değilse uygulamayı admin olarak yeniden başlatır
    public static void RestartAsAdmin()
    {
        var exePath = Environment.ProcessPath ?? Process.GetCurrentProcess().MainModule?.FileName;
        if (exePath == null) return;

        Process.Start(new ProcessStartInfo
        {
            FileName = exePath,
            UseShellExecute = true,
            Verb = "runas"
        });

        Environment.Exit(0);
    }
}
