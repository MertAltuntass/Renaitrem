using System.Diagnostics;
using System.IO;
using System.Text;

namespace RenaitreGUI.Services;

public class PowerShellService
{
    // Scriptlerin ürettiği dosyalar (transcript, reset.txt, loglar) buraya düşer —
    // bin/Debug'ı kirletmesin diye. Documents\RenaitreSabre.
    public static string OutputDir { get; } = EnsureOutputDir();

    private static string EnsureOutputDir()
    {
        var dir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
            "RenaitreSabre");
        try { Directory.CreateDirectory(dir); } catch { }
        return dir;
    }

    public async Task RunScriptAsync(
        string script,
        Action<string> onOutput,
        CancellationToken ct = default)
    {
        var tempFile = Path.Combine(Path.GetTempPath(), $"renaitre_{Guid.NewGuid():N}.ps1");
        try
        {
            await File.WriteAllTextAsync(tempFile, script, new UTF8Encoding(false), ct);
            await RunPowershellProcess($"-ExecutionPolicy Bypass -File \"{tempFile}\"", onOutput, ct);
        }
        finally
        {
            try { if (File.Exists(tempFile)) File.Delete(tempFile); } catch { }
        }
    }

    public async Task RunCommandAsync(
        string command,
        string[] args,
        Action<string> onOutput,
        CancellationToken ct = default)
    {
        await Task.Run(() =>
        {
            using var process = new Process();
            process.StartInfo = new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = $"/c {command} {string.Join(" ", args)}",
                WorkingDirectory = OutputDir,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8
            };

            process.OutputDataReceived += (_, e) =>
            {
                try { if (e.Data != null) onOutput(e.Data); } catch { }
            };
            process.ErrorDataReceived += (_, e) =>
            {
                try { if (e.Data != null) onOutput($"[ERR] {e.Data}"); } catch { }
            };

            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            while (!process.HasExited)
            {
                if (ct.IsCancellationRequested)
                {
                    try { process.Kill(entireProcessTree: true); } catch { }
                    break;
                }
                Thread.Sleep(100);
            }

            try { process.WaitForExit(500); } catch { }
        }, ct);
    }

    public async Task RunScriptWithParamsAsync(
        string script,
        Dictionary<string, object?> parameters,
        Action<string> onOutput,
        CancellationToken ct = default)
    {
        var tempFile = Path.Combine(Path.GetTempPath(), $"renaitre_{Guid.NewGuid():N}.ps1");
        try
        {
            await File.WriteAllTextAsync(tempFile, script, new UTF8Encoding(false), ct);

            // Switch params (bool true) → -ParamName  |  Others → -ParamName "value"
            var paramArgs = string.Join(" ", parameters
                .Where(kv => kv.Value != null)
                .Select(kv => kv.Value is bool b && b
                    ? $"-{kv.Key}"
                    : $"-{kv.Key} \"{kv.Value}\""));

            await RunPowershellProcess(
                $"-ExecutionPolicy Bypass -File \"{tempFile}\" {paramArgs}",
                onOutput, ct);
        }
        finally
        {
            try { if (File.Exists(tempFile)) File.Delete(tempFile); } catch { }
        }
    }

    private static async Task RunPowershellProcess(string args, Action<string> onOutput, CancellationToken ct)
    {
        await Task.Run(() =>
        {
            using var process = new Process();
            process.StartInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = args,
                WorkingDirectory = OutputDir,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true,
                StandardOutputEncoding = new UTF8Encoding(false),
                StandardErrorEncoding  = new UTF8Encoding(false)
            };

            process.OutputDataReceived += (_, e) =>
            {
                try { if (e.Data != null) onOutput(e.Data); } catch { }
            };
            process.ErrorDataReceived += (_, e) =>
            {
                try { if (e.Data != null) onOutput($"[ERR] {e.Data}"); } catch { }
            };

            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            while (!process.HasExited)
            {
                if (ct.IsCancellationRequested)
                {
                    try { process.Kill(entireProcessTree: true); } catch { }
                    break;
                }
                Thread.Sleep(100);
            }

            try { process.WaitForExit(500); } catch { }
        }, ct);
    }

    // Embedded .ps1 resource'u string olarak döner
    public static string? GetEmbeddedScript(string scriptName)
    {
        var assembly = System.Reflection.Assembly.GetExecutingAssembly();
        var resourceName = assembly.GetManifestResourceNames()
            .FirstOrDefault(n => n.EndsWith(scriptName, StringComparison.OrdinalIgnoreCase));

        if (resourceName == null) return null;

        using var stream = assembly.GetManifestResourceStream(resourceName);
        if (stream == null) return null;
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }
}
