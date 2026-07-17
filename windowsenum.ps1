param($extended)

# Kendini yönetici olarak yeniden başlat
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`" -extended `"$extended`"" -Verb RunAs
    exit
}

$lines="******************************************"
function whost($a) {
    Write-Host
    Write-Host -ForegroundColor Yellow $lines
    Write-Host -ForegroundColor Yellow " "$a 
    Write-Host -ForegroundColor Yellow $lines
}

whost "
____________________________________________   ______  _______  ___
__  ___/__    |__  __ )__  __ \__  ____/__  | / /_  / / /__   |/  /
_____ \__  /| |_  __  |_  /_/ /_  __/  __   |/ /_  / / /__  /|_/ / 
____/ /_  ___ |  /_/ /_  _, _/_  /___  _  /|  / / /_/ / _  /  / /  
/____/ /_/  |_/_____/ /_/ |_| /_____/  /_/ |_/  \____/  /_/  /_/   
"

# USB veya temp klasörü belirleme
$usbDrive = Get-PSDrive -PSProvider 'FileSystem' | Where-Object { $_.Root -match '^[E-Z]:\\$' -and $_.Root -ne "C:\\" } | Select-Object -First 1
if ($usbDrive) {
    $basePath = "$($usbDrive.Root)\sabrenum"
} else {
    $basePath = "C:\temp\sabrenum"
}
if (!(Test-Path $basePath)) {
    New-Item -Path $basePath -ItemType Directory | Out-Null
}

# Standart komut listesi
$standard_commands = [ordered]@{
    'Basic System Information'                    = 'systeminfo'
    'Environment Variables'                       = 'Get-ChildItem Env: | ft Key,Value'
    'Network Information'                         = 'Get-NetIPConfiguration | ft InterfaceAlias,InterfaceDescription,IPv4Address'
    'DNS Servers'                                 = 'Get-DnsClientServerAddress -AddressFamily IPv4 | ft'
    'ARP cache'                                   = 'Get-NetNeighbor -AddressFamily IPv4 | ft ifIndex,IPAddress,LinkLayerAddress,State'
    'Routing Table'                               = 'Get-NetRoute -AddressFamily IPv4 | ft DestinationPrefix,NextHop,RouteMetric,ifIndex'
    'Network Connections'                         = 'netstat -ano'
    'Connected Drives'                            = 'Get-PSDrive | where {$_.Provider -like "Microsoft.PowerShell.Core\FileSystem"}| ft'
    'Firewall Config'                             = 'netsh firewall show config'
    'Current User'                                = 'Write-Output "$env:UserDomain\$env:UserName"'
    'User Privileges'                             = 'whoami /priv'
    'Local Users'                                 = 'Get-LocalUser | ft Name,Enabled,LastLogon'
    'Logged in Users'                             = 'qwinsta'
    'Credential Manager'                          = 'cmdkey /list'
    'User Autologon Registry Items'               = 'Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon" | select "Default*" | ft'
    'Local Groups'                                = 'Get-LocalGroup | ft Name'
    'Local Administrators'                        = 'Get-LocalGroupMember Administrators | ft Name, PrincipalSource'
    'User Directories'                            = 'Get-ChildItem C:\Users | ft Name'
    'Searching for SAM backup files'              = 'Test-Path $env:SYSTEMROOT\repair\SAM; Test-Path $env:SYSTEMROOT\system32\config\regback\SAM'
    'Running Processes'                           = 'gwmi -Query "Select * from Win32_Process" | where {$_.Name -notlike "svchost*"} | Select Name, Handle, @{Label="Owner";Expression={$_.GetOwner().User}} | ft -AutoSize'
    'Installed Software Directories'              = 'Get-ChildItem "C:\Program Files", "C:\Program Files (x86)" | ft Parent,Name,LastWriteTime'
    'Software in Registry'                        = 'Get-ChildItem -path Registry::HKEY_LOCAL_MACHINE\SOFTWARE | ft Name'
    'Folders with Everyone Permissions'           = 'Get-ChildItem "C:\Program Files\*", "C:\Program Files (x86)\*" | % { try { Get-Acl $_ -EA SilentlyContinue | Where {($_.Access|select -ExpandProperty IdentityReference) -match "Everyone"} } catch {}} | ft'
    'Folders with BUILTIN\User Permissions'       = 'Get-ChildItem "C:\Program Files\*", "C:\Program Files (x86)\*" | % { try { Get-Acl $_ -EA SilentlyContinue | Where {($_.Access|select -ExpandProperty IdentityReference) -match "BUILTIN\\Users"} } catch {}} | ft'
    'Checking registry for AlwaysInstallElevated' = 'Test-Path -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer"'
    'Unquoted Service Paths'                      = 'gwmi -class Win32_Service -Property Name, DisplayName, PathName, StartMode | Where {$_.StartMode -eq "Auto" -and $_.PathName -notlike "C:\Windows*" -and $_.PathName -notlike ''"*''} | select PathName, DisplayName, Name | ft'
    'Scheduled Tasks'                             = 'Get-ScheduledTask | where {$_.TaskPath -notlike "\Microsoft*"} | ft TaskName,TaskPath,State'
    'Tasks Folder'                                = 'Get-ChildItem C:\Windows\Tasks | ft'
    'Startup Commands'                            = 'Get-CimInstance Win32_StartupCommand | select Name, command, Location, User | fl'
}

# Extended komut listesi
$extended_commands = [ordered]@{
    'Searching for Unattend and Sysprep files' = 'Get-ChildItem -Path C:\ -Include *unattend*,*sysprep* -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "\.(xml|txt|ini)$" }'
    'Searching for web.config files'           = 'Get-ChildItem -Path C:\ -Include web.config -File -Recurse -ErrorAction SilentlyContinue'
    'Searching for other interesting files'    = 'Get-ChildItem -Path C:\ -Include *password*,*cred*,*vnc* -File -Recurse -ErrorAction SilentlyContinue'
    'Searching for various config files'       = 'Get-ChildItem -Path C:\ -Include php.ini, httpd.conf, httpd-xampp.conf, my.ini, my.cnf -File -Recurse -ErrorAction SilentlyContinue'
    'Searching HKLM for passwords'             = 'reg query HKLM /f password /t REG_SZ /s'
    'Searching HKCU for passwords'             = 'reg query HKCU /f password /t REG_SZ /s'
    'Searching for files with passwords'       = 'Get-ChildItem C:\ -Include *.xml,*.ini,*.txt,*.config -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "C:\\temp|Reference Assemblies|Windows Kits" } | Select-String -Pattern "password"'
    'Ping Flood Test (with error control)'     = {
        $target = "192.168.1.1"
        $failCount = 0
        $maxFails = 5
        $results = @()
        for ($i = 1; $i -le 10; $i++) {
            try {
                $res = Test-Connection -ComputerName $target -Count 1 -ErrorAction Stop
                $results += $res
            } catch {
                $failCount++
                $results += "ERROR: $_"
                if ($failCount -ge $maxFails) {
                    $results += "Too many failures. Skipping test."
                    break
                }
            }
        }
        $results
    }
}

# Komutları çalıştıran fonksiyon
function RunCommands($commands) {
    foreach ($entry in $commands.GetEnumerator()) {
        whost $entry.Key
        try {
            if ($entry.Value -is [scriptblock]) {
                $output = & $entry.Value
            } else {
                $output = Invoke-Expression $entry.Value
            }
            $filename = ($entry.Key -replace '[\\\/:*?"<>|]', '_') + ".txt"
            if ($output) {
                $output | Out-File -FilePath "$basePath\$filename" -Encoding UTF8 -Force
            } else {
                "No output returned." | Out-File -FilePath "$basePath\$filename" -Encoding UTF8 -Force
            }
        } catch {
            "ERROR: $_" | Out-File -FilePath "$basePath\ERROR_$($entry.Key).txt" -Encoding UTF8 -Force
        }
    }
}

# Çalıştır
RunCommands $standard_commands
if ($extended -and $extended.ToLower() -eq 'extended') {
    RunCommands $extended_commands
}

whost "Sabrenum completed. Output is in $basePath"
