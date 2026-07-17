using System.Diagnostics;
using System.IO;
using System.Text;

namespace RenaitreGUI.Services;

public record WingetPackage(string Name, string Id);

public class WingetService
{
    // Admin olarak çalışırken AppX stub'ları PATH'de olmayabilir — tam yolu bul
    private static readonly string WingetExe = FindWinget();

    private static string FindWinget()
    {
        var localApp = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var appxPath = Path.Combine(localApp, "Microsoft", "WindowsApps", "winget.exe");
        if (File.Exists(appxPath)) return appxPath;

        // Program Files altında da dene (bazı kurulumlar burada)
        var programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        var pfPath = Path.Combine(programFiles, "WindowsApps");
        if (Directory.Exists(pfPath))
        {
            var found = Directory.GetFiles(pfPath, "winget.exe", SearchOption.AllDirectories).FirstOrDefault();
            if (found != null) return found;
        }

        return "winget"; // fallback — PATH'deyse çalışır
    }

    // İlerleme çubuğu / ANSI gürültüsünü kapatır → satır satır yakalanan çıktı temiz olur
    private const string NoUi = "--disable-interactivity";

    /// <summary>Searches and returns structured results, also streaming raw output for the terminal.</summary>
    public async Task<List<WingetPackage>> SearchStructuredAsync(string query, Action<string> onOutput, CancellationToken ct = default)
    {
        var lines = new List<string>();
        void capture(string l) { lines.Add(l); onOutput(l); }
        await RunWinget($"search \"{query}\" --source winget --accept-source-agreements {NoUi}", capture, ct);
        return ParseSearchOutput(lines);
    }

    public async Task InstallAsync(string packageId, Action<string> onOutput, CancellationToken ct = default)
        => await RunWinget($"install --id \"{packageId}\" -e --accept-source-agreements --accept-package-agreements {NoUi}", onOutput, ct);

    public async Task UpgradeAllAsync(Action<string> onOutput, CancellationToken ct = default)
        => await RunWinget($"upgrade --all --accept-source-agreements --accept-package-agreements {NoUi}", onOutput, ct);

    private static List<WingetPackage> ParseSearchOutput(List<string> lines)
    {
        var results = new List<WingetPackage>();

        // Find the separator line (e.g. "------- ---------- ...")
        int sepIdx = lines.FindIndex(l => l.TrimStart().StartsWith("---") && l.Contains(" "));
        if (sepIdx < 1) return results;

        var sepLine = lines[sepIdx];

        // Determine column start positions from the separator
        var cols = new List<int>();
        bool inDash = false;
        for (int i = 0; i < sepLine.Length; i++)
        {
            if (sepLine[i] == '-' && !inDash) { cols.Add(i); inDash = true; }
            else if (sepLine[i] == ' ') inDash = false;
        }

        if (cols.Count < 2) return results;

        int nameStart = cols[0];
        int idStart   = cols[1];
        int idEnd     = cols.Count > 2 ? cols[2] : -1;

        for (int i = sepIdx + 1; i < lines.Count; i++)
        {
            var line = lines[i];
            if (line.Length <= idStart) continue;

            var name   = line[nameStart..Math.Min(idStart, line.Length)].Trim();
            var endIdx = idEnd > 0 && idEnd <= line.Length ? idEnd : line.Length;
            var id     = line[idStart..endIdx].Trim();

            if (!string.IsNullOrEmpty(id) && !string.IsNullOrEmpty(name))
                results.Add(new WingetPackage(name, id));
        }

        return results;
    }

    private async Task RunWinget(string args, Action<string> onOutput, CancellationToken ct)
    {
        if (WingetExe == "winget" && !IsWingetInPath())
        {
            onOutput("[ERR] winget bulunamadı. Windows Package Manager kurulu değil veya bu oturumda erişilemiyor.");
            return;
        }

        await Task.Run(() =>
        {
            using var process = new Process();
            process.StartInfo = new ProcessStartInfo
            {
                FileName = WingetExe,
                Arguments = args,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8
            };

            process.OutputDataReceived += (_, e) => { if (e.Data != null) onOutput(e.Data); };
            process.ErrorDataReceived += (_, e) => { if (e.Data != null) onOutput($"[ERR] {e.Data}"); };

            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            while (!process.HasExited)
            {
                if (ct.IsCancellationRequested) { process.Kill(entireProcessTree: true); break; }
                Thread.Sleep(100);
            }
        }, ct);
    }

    private static bool IsWingetInPath()
    {
        var path = Environment.GetEnvironmentVariable("PATH") ?? "";
        return path.Split(';').Any(dir =>
            File.Exists(Path.Combine(dir.Trim(), "winget.exe")));
    }
}
