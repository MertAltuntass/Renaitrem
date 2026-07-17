param(
    [switch]$extended,
    [switch]$stealth,
    [string]$outputPath,
    [switch]$encrypt,
    [string]$encryptionKey,
    [switch]$bruteforce,
    [string]$userList,
    [string]$passwordList,
    [switch]$portscan,
    [string]$targetHost,
    [int[]]$ports,
    [switch]$htmlreport
)

# Kendini yönetici olarak yeniden başlat
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
    if ($extended) { $arguments += " -extended" }
    if ($stealth) { $arguments += " -stealth" }
    if ($outputPath) { $arguments += " -outputPath `"$outputPath`"" }
    if ($encrypt) { $arguments += " -encrypt" }
    if ($encryptionKey) { $arguments += " -encryptionKey `"$encryptionKey`"" }
    if ($bruteforce) { $arguments += " -bruteforce" }
    if ($userList) { $arguments += " -userList `"$userList`"" }
    if ($passwordList) { $arguments += " -passwordList `"$passwordList`"" }
    if ($portscan) { $arguments += " -portscan" }
    if ($targetHost) { $arguments += " -targetHost `"$targetHost`"" }
    if ($ports) { $arguments += " -ports $($ports -join ',')" }
    if ($htmlreport) { $arguments += " -htmlreport" }
    
    Start-Process powershell -ArgumentList $arguments -Verb RunAs
    return
}

# Stealth modu etkinse, olay günlüğü kaydını geçici olarak devre dışı bırak
if ($stealth) {
    try {
        Write-Host "Stealth mode aktif, PowerShell olay günlüğü devre dışı bırakılıyor..." -ForegroundColor Cyan
        $originalExecutionPolicy = Get-ExecutionPolicy
        Set-ExecutionPolicy Bypass -Scope Process -Force
        $logSettings = Get-WinEvent -ListLog "Microsoft-Windows-PowerShell/Operational"
        $logSettings.IsEnabled = $false
        $logSettings.SaveChanges()
    }
    catch {
        Write-Host "Olay günlüğü devre dışı bırakılamadı. Admin haklarınızı kontrol edin." -ForegroundColor Red
    }
}

$lines = "******************************************"
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

PenTest Otomasyonu v3.0
"

# HTML raporu için fonksiyon
function Generate-HTMLReport {
    param(
        [string]$basePath,
        [array]$vulnerabilities,
        [hashtable]$systemInfo
    )
    
    $htmlPath = Join-Path -Path $basePath -ChildPath "report.html"
    
    $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Penetrasyon Testi Raporu</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; color: #333; }
        .container { max-width: 1200px; margin: 0 auto; }
        h1, h2, h3 { color: #2c3e50; }
        .header { background-color: #2c3e50; color: white; padding: 20px; text-align: center; margin-bottom: 30px; }
        .section { margin-bottom: 30px; border-bottom: 1px solid #eee; padding-bottom: 20px; }
        .vulnerability { margin-bottom: 15px; padding: 10px; border-radius: 5px; }
        .high { background-color: #ffdddd; border-left: 5px solid #f44336; }
        .medium { background-color: #fff4dd; border-left: 5px solid #ff9800; }
        .low { background-color: #ddffdd; border-left: 5px solid #4CAF50; }
        .info { background-color: #e7f3fe; border-left: 5px solid #2196F3; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .summary-card { background: #f9f9f9; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .severity-count { display: flex; justify-content: space-between; margin-bottom: 20px; }
        .severity-box { flex: 1; text-align: center; padding: 15px; margin: 0 5px; border-radius: 5px; color: white; }
        .high-count { background-color: #f44336; }
        .medium-count { background-color: #ff9800; }
        .low-count { background-color: #4CAF50; }
        .info-count { background-color: #2196F3; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Penetrasyon Testi Raporu</h1>
            <p>Oluşturulma Tarihi: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
"@

    $htmlSystemInfo = @"
        <div class="section">
            <h2>Sistem Bilgileri</h2>
            <div class="summary-card">
                <table>
                    <tr><th>Özellik</th><th>Değer</th></tr>
                    $(foreach ($item in $systemInfo.GetEnumerator()) {
                        "<tr><td>$($item.Key)</td><td>$($item.Value)</td></tr>"
                    })
                </table>
            </div>
        </div>
"@

    $vulnCounts = @{
        High = ($vulnerabilities | Where-Object { $_.Severity -eq "High" } | Measure-Object).Count
        Medium = ($vulnerabilities | Where-Object { $_.Severity -eq "Medium" } | Measure-Object).Count
        Low = ($vulnerabilities | Where-Object { $_.Severity -eq "Low" } | Measure-Object).Count
        Informational = ($vulnerabilities | Where-Object { $_.Severity -eq "Informational" } | Measure-Object).Count
    }

    $htmlSummary = @"
        <div class="section">
            <h2>Güvenlik Açıkları Özeti</h2>
            <div class="summary-card">
                <div class="severity-count">
                    <div class="severity-box high-count">
                        <h3>Yüksek</h3>
                        <p>$($vulnCounts.High) Açık</p>
                    </div>
                    <div class="severity-box medium-count">
                        <h3>Orta</h3>
                        <p>$($vulnCounts.Medium) Açık</p>
                    </div>
                    <div class="severity-box low-count">
                        <h3>Düşük</h3>
                        <p>$($vulnCounts.Low) Açık</p>
                    </div>
                    <div class="severity-box info-count">
                        <h3>Bilgi</h3>
                        <p>$($vulnCounts.Informational) Açık</p>
                    </div>
                </div>
                <p>Toplam <strong>$($vulnerabilities.Count)</strong> güvenlik açığı tespit edildi.</p>
            </div>
        </div>
"@

    $htmlVulnerabilities = @"
        <div class="section">
            <h2>Detaylı Güvenlik Açıkları</h2>
            $(foreach ($vuln in $vulnerabilities | Sort-Object -Property @{Expression = {
                switch ($_.Severity) {
                    "High" { 1 }
                    "Medium" { 2 }
                    "Low" { 3 }
                    "Informational" { 4 }
                    default { 5 }
                }
            }}) {
                $severityClass = $vuln.Severity.ToLower()
                "<div class='vulnerability $severityClass'>
                    <h3>$($vuln.Finding)</h3>
                    <p><strong>Şiddet:</strong> $($vuln.Severity)</p>
                    <p><strong>Açıklama:</strong> $($vuln.Description)</p>
                    <p><strong>Önerilen Çözüm:</strong> $($vuln.Mitigation)</p>
                </div>"
            })
        </div>
"@

    $htmlFooter = @"
        <div class="section">
            <h2>Sonuçlar ve Öneriler</h2>
            <p>Bu rapor, sistemin güvenlik duruşunu değerlendirmek için otomatik olarak oluşturulmuştur.</p>
            <p><strong>Önerilen Eylemler:</strong></p>
            <ol>
                <li>Yüksek öncelikli güvenlik açıklarını hemen ele alın</li>
                <li>Orta seviyeli açıkları planlı bir şekilde düzeltin</li>
                <li>Bilgi amaçlı bulguları gözden geçirin ve gerektiğinde yapılandırmaları iyileştirin</li>
                <li>Düzenli güvenlik taramaları yapın</li>
            </ol>
        </div>
    </div>
</body>
</html>
"@

    $htmlHeader + $htmlSystemInfo + $htmlSummary + $htmlVulnerabilities + $htmlFooter | Out-File $htmlPath -Encoding UTF8
    Write-Host "HTML raporu oluşturuldu: $htmlPath" -ForegroundColor Green
}

# Çıkış dizini belirleme — öngörülebilir konum (RenaitreSabre çıktı klasörü)
if ($outputPath) {
    $basePath = $outputPath
} else {
    $basePath = Join-Path $env:USERPROFILE "Documents\RenaitreSabre\enum"
}

# Benzersiz bir klasör oluştur (timestamp ile)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$basePath = Join-Path -Path $basePath -ChildPath $timestamp
if (!(Test-Path $basePath)) {
    New-Item -Path $basePath -ItemType Directory | Out-Null
}

# Lisans anahtarlarını toplama fonksiyonu
function Get-SoftwareLicenses {
    $licenses = @()
    
    # Windows Ürün Anahtarı
    try {
        $winKey = (Get-WmiObject -Query "SELECT OA3xOriginalProductKey FROM SoftwareLicensingService").OA3xOriginalProductKey
        if ($winKey) {
            $licenses += [PSCustomObject]@{
                Software = "Windows OS"
                LicenseKey = $winKey
                Source = "WMI"
            }
        }
    } catch {}
    
    # Office ürün anahtarı
    try {
        $officePath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\*\Registration"
        $officeKeys = Get-ChildItem -Path $officePath -ErrorAction SilentlyContinue | ForEach-Object {
            $product = Get-ItemProperty -Path $_.PSPath
            if ($product.DigitalProductID -or $product.ProductID) {
                $licenses += [PSCustomObject]@{
                    Software = $product.ProductName
                    LicenseKey = if ($product.DigitalProductID) { "Encoded in DigitalProductID" } else { $product.ProductID }
                    Source = "Registry"
                }
            }
        }
    } catch {}
    
    # Popüler yazılımlar için lisans anahtarları
    $softwareKeys = @(
        @{Name="VMware"; Path="Registry::HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc.\VMware Workstation"},
        @{Name="Adobe"; Path="Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Adobe\*"},
        @{Name="AutoCAD"; Path="Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Autodesk\AutoCAD\*"},
        @{Name="WinRAR"; Path="Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WinRAR"}
    )
    
    foreach ($sw in $softwareKeys) {
        try {
            $keys = Get-ChildItem -Path $sw.Path -ErrorAction SilentlyContinue | ForEach-Object {
                $props = Get-ItemProperty -Path $_.PSPath
                if ($props.Serial -or $props.LicenseKey -or $props.ProductKey) {
                    $licenses += [PSCustomObject]@{
                        Software = $sw.Name
                        LicenseKey = if ($props.Serial) { $props.Serial } elseif ($props.LicenseKey) { $props.LicenseKey } else { $props.ProductKey }
                        Source = "Registry"
                    }
                }
            }
        } catch {}
    }
    
    return $licenses
}

# Domain şifre politikalarını alma fonksiyonu
function Get-DomainPasswordPolicy {
    try {
        if ((Get-WmiObject win32_computersystem).partofdomain) {
            $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
            $domainName = $domain.Name
            $domainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $domainName)
            $domainObject = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($domainContext)
            $domainDN = $domainObject.GetDirectoryEntry().distinguishedName
            
            $searcher = New-Object System.DirectoryServices.DirectorySearcher
            $searcher.SearchRoot = "LDAP://$domainDN"
            $searcher.Filter = "(objectClass=domainDNS)"
            $result = $searcher.FindOne()
            
            if ($result) {
                $domainEntry = $result.GetDirectoryEntry()
                $policy = [PSCustomObject]@{
                    DomainName = $domainName
                    MinPasswordLength = $domainEntry.minPwdLength
                    PasswordHistory = $domainEntry.pwdHistoryLength
                    PasswordComplexity = if ($domainEntry.pwdProperties -band 1) { "Enabled" } else { "Disabled" }
                    LockoutThreshold = $domainEntry.lockoutThreshold
                    LockoutDuration = [timespan]::FromMinutes($domainEntry.lockoutDuration / -600000000)
                    LockoutObservationWindow = [timespan]::FromMinutes($domainEntry.lockoutObservationWindow / -600000000)
                    MaxPasswordAge = [timespan]::FromDays($domainEntry.maxPwdAge / -864000000000)
                    MinPasswordAge = [timespan]::FromDays($domainEntry.minPwdAge / -864000000000)
                }
                return $policy
            }
        }
        return "Machine is not part of a domain or policy cannot be retrieved."
    } catch {
        return "Error retrieving domain password policy: $($_.Exception.Message)"
    }
}

# Port tarama fonksiyonu
function Invoke-PortScan {
    param(
        [string]$hostname,
        [int[]]$ports,
        [int]$timeout = 1000
    )
    
    $results = @()
    
    foreach ($port in $ports) {
        $socket = New-Object System.Net.Sockets.TcpClient
        $connection = $socket.BeginConnect($hostname, $port, $null, $null)
        $connection.AsyncWaitHandle.WaitOne($timeout, $false) | Out-Null
        
        if ($socket.Connected) {
            $service = try { [System.Net.Dns]::GetHostByAddress($hostname).HostName } catch { "Unknown" }
            $results += [PSCustomObject]@{
                Port = $port
                Status = "Open"
                Service = $service
            }
            $socket.Close()
        } else {
            $results += [PSCustomObject]@{
                Port = $port
                Status = "Closed/Filtered"
                Service = "N/A"
            }
        }
    }
    
    return $results
}

# Bruteforce fonksiyonu (temel)
function Invoke-BruteForce {
    param(
        [string]$userList,
        [string]$passwordList
    )
    
    $results = @()
    $users = Get-Content $userList -ErrorAction SilentlyContinue
    $passwords = Get-Content $passwordList -ErrorAction SilentlyContinue
    
    if (-not $users -or -not $passwords) {
        return "User list or password list not found or empty."
    }
    
    foreach ($user in $users) {
        foreach ($password in $passwords) {
            $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential($user, $securePassword)
            
            try {
                # Yerel oturum açma denemesi
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c echo test" -Credential $credential -WindowStyle Hidden -ErrorAction Stop
                $results += [PSCustomObject]@{
                    Username = $user
                    Password = $password
                    Status = "Success"
                }
                break
            } catch {
                $results += [PSCustomObject]@{
                    Username = $user
                    Password = $password
                    Status = "Failed"
                }
            }
        }
    }
    
    return $results
}

# Anti-virüs ürünlerini tespit et
function Get-AVProducts {
    Write-Host "Anti-virüs ürünleri tespit ediliyor..." -ForegroundColor Cyan
    $avProducts = @()
    
    # Windows Security Center'dan bilgi alma
    try {
        $wsc = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
        if ($wsc) {
            $avProducts += $wsc | Select-Object displayName, productState, @{Name="Status"; Expression={
                $state = $_.productState
                $hex = [Convert]::ToString($state, 16).PadLeft(6, '0')
                $enabled = $hex.Substring(2, 2)
                if ($enabled -eq "10" -or $enabled -eq "11") { "Enabled" } else { "Disabled" }
            }}
        }
    } catch {
        $avProducts += "SecurityCenter2 bilgilerine erişilemedi"
    }
    
    # Windows Defender durumunu kontrol et
    try {
        $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($defender) {
            $avProducts += [PSCustomObject]@{
                DisplayName = "Windows Defender"
                Status = if ($defender.RealTimeProtectionEnabled) { "Enabled" } else { "Disabled" }
                AMServiceEnabled = $defender.AMServiceEnabled
                AntispywareEnabled = $defender.AntispywareEnabled
                AntivirusEnabled = $defender.AntivirusEnabled
            }
        }
    } catch {
        $avProducts += "Windows Defender durumu alınamadı"
    }
    
    # Servisleri kontrol et
    $avServices = @(
        "WinDefend", # Windows Defender
        "McAfeeFramework", # McAfee
        "vsserv", # Bitdefender
        "ekrn", # ESET
        "KAVFS", # Kaspersky
        "kltsrv", # Kaspersky
        "SavService", # Sophos
        "SAVAdminService", # Sophos
        "symantec", # Symantec
        "SepMasterService", # Symantec Endpoint Protection
        "TMCCSF" # Trend Micro
    )
    
    foreach ($service in $avServices) {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            $avProducts += [PSCustomObject]@{
                DisplayName = "Service: $($svc.DisplayName)"
                Name = $svc.Name
                Status = $svc.Status
            }
        }
    }
    
    return $avProducts
}

# Standart komut listesi
$standard_commands = [ordered]@{
    'Basic System Information'                    = 'systeminfo'
    'Environment Variables'                       = 'Get-ChildItem Env: | Format-Table Key,Value'
    'Network Information'                         = 'Get-NetIPConfiguration | Format-Table InterfaceAlias,InterfaceDescription,IPv4Address'
    'DNS Servers'                                 = 'Get-DnsClientServerAddress -AddressFamily IPv4 | Format-Table'
    'ARP cache'                                   = 'Get-NetNeighbor -AddressFamily IPv4 | Format-Table ifIndex,IPAddress,LinkLayerAddress,State'
    'Routing Table'                               = 'Get-NetRoute -AddressFamily IPv4 | Format-Table DestinationPrefix,NextHop,RouteMetric,ifIndex'
    'Network Connections'                         = 'Get-NetTCPConnection | Format-Table LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess,@{Name="ProcessName";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}}'
    'Connected Drives'                            = 'Get-PSDrive | Where-Object {$_.Provider -like "Microsoft.PowerShell.Core\FileSystem"}| Format-Table'
    'Firewall Config'                             = 'Get-NetFirewallProfile | Format-Table Name,Enabled'
    'Firewall Rules'                              = 'Get-NetFirewallRule | Where-Object {$_.Enabled -eq $true -and $_.Direction -eq "Inbound"} | Format-Table Name,DisplayName,Profile,Direction,Action,Enabled'
    'Current User'                                = 'Write-Output "$env:UserDomain\$env:UserName"'
    'User Privileges'                             = 'whoami /priv'
    'Local Users'                                 = 'Get-LocalUser | Format-Table Name,Enabled,LastLogon'
    'Logged in Users'                             = 'qwinsta'
    'Credential Manager'                          = 'cmdkey /list'
    'User Autologon Registry Items'               = 'Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon" | Select-Object "Default*" | Format-Table'
    'Local Groups'                                = 'Get-LocalGroup | Format-Table Name'
    'Local Administrators'                        = 'Get-LocalGroupMember Administrators | Format-Table Name, PrincipalSource'
    'User Directories'                            = 'Get-ChildItem C:\Users | Format-Table Name'
    'Anti-virus Products'                         = { Get-AVProducts }
    'Windows Defender Configuration'              = 'Get-MpPreference | Format-List *enabled*'
    'Windows Defender Exclusions'                 = 'Get-MpPreference | Select-Object -Property *Exclusion* | Format-List'
    'Running Processes'                           = 'Get-WmiObject -Query "Select * from Win32_Process" | Where-Object {$_.Name -notlike "svchost*"} | Select-Object Name, Handle, @{Label="Owner";Expression={$_.GetOwner().User}} | Format-Table -AutoSize'
    'Auto-Starting Programs'                      = 'Get-CimInstance Win32_StartupCommand | Select-Object Name, command, Location, User | Format-List'
    'Installed Services'                          = 'Get-WmiObject win32_service | Select-Object Name, DisplayName, PathName, StartMode, StartName, State | Format-Table'
    'Installed Software Directories'              = 'Get-ChildItem "C:\Program Files", "C:\Program Files (x86)" | Format-Table Parent,Name,LastWriteTime'
    'Software in Registry'                        = 'Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_.DisplayName -ne $null } | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table'
    'PowerShell Version'                          = '$PSVersionTable'
    'PowerShell Execution Policy'                 = 'Get-ExecutionPolicy -List | Format-Table'
    'Folders with Everyone Permissions'           = 'Get-ChildItem "C:\Program Files\*", "C:\Program Files (x86)\*" | ForEach-Object { try { $acl = Get-Acl $_ -ErrorAction SilentlyContinue; if ($acl.Access | Where-Object {$_.IdentityReference -match "Everyone"}) { $_ | Select-Object FullName } } catch {}}'
    'Folders with BUILTIN\Users Permissions'      = 'Get-ChildItem "C:\Program Files\*", "C:\Program Files (x86)\*" | ForEach-Object { try { $acl = Get-Acl $_ -ErrorAction SilentlyContinue; if ($acl.Access | Where-Object {$_.IdentityReference -match "BUILTIN\\Users"}) { $_ | Select-Object FullName } } catch {}}'
    'AlwaysInstallElevated Check'                 = 'try { $hkcu = Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -ErrorAction SilentlyContinue; $hklm = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -ErrorAction SilentlyContinue; Write-Output "HKCU: $(if($hkcu -ne $null){"Enabled"} else {"Disabled"}), HKLM: $(if($hklm -ne $null){"Enabled"} else {"Disabled"})" } catch { Write-Output "Disabled" }'
    'Unquoted Service Paths'                      = 'Get-WmiObject -Class Win32_Service -Property Name, DisplayName, PathName, StartMode | Where-Object {$_.StartMode -eq "Auto" -and $_.PathName -notlike "C:\Windows*" -and $_.PathName -notlike "`"*`"" -and $_.PathName -like "* *"} | Select-Object PathName, DisplayName, Name | Format-Table'
    'Scheduled Tasks'                             = 'Get-ScheduledTask | Where-Object {$_.TaskPath -notlike "\Microsoft*"} | Format-Table TaskName,TaskPath,State'
    'Tasks Folder'                                = 'Get-ChildItem C:\Windows\Tasks | Format-Table'
    'SMB Shares'                                  = 'Get-SmbShare | Format-Table Name, Path, Description'
    'Missing Software Patches'                    = 'Get-HotFix | Sort-Object -Property InstalledOn -Descending | Format-Table HotFixID, Description, InstalledOn -AutoSize'
    'LAPS Check'                                  = 'try { Get-Command Get-LapsAADPassword -ErrorAction Stop; Write-Output "LAPS is installed" } catch { Write-Output "LAPS command not found" }'
    'WSL Status'                                  = 'Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux | Format-Table'
    'RDP Status'                                  = 'Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" | Format-Table'
    'WinRM Status'                                = 'Get-Service WinRM | Format-Table Name, DisplayName, Status'
    'Installed Licenses'                          = { Get-SoftwareLicenses }
    'Domain Password Policy'                      = { Get-DomainPasswordPolicy }
}

# Extended komut listesi
$extended_commands = [ordered]@{
    'Searching for Unattend and Sysprep files' = 'Get-ChildItem -Path C:\ -Include *unattend*,*sysprep* -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "\.(xml|txt|ini)$" } | Select-Object FullName, LastWriteTime, Length'
    'Searching for web.config files'           = 'Get-ChildItem -Path C:\ -Include web.config -File -Recurse -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime, Length'
    'Searching for other interesting files'    = 'Get-ChildItem -Path C:\ -Include *password*,*cred*,*vnc*,*.config,*.conf,*.ini -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -lt 100KB } | Select-Object FullName, LastWriteTime, Length'
    'Searching for SSH keys'                   = 'Get-ChildItem -Path C:\Users -Include id_rsa,id_dsa,*.ppk -File -Recurse -ErrorAction SilentlyContinue -Force | Select-Object FullName, LastWriteTime'
    'Searching HKLM for passwords'             = 'reg query HKLM /f password /t REG_SZ /s'
    'Searching HKCU for passwords'             = 'reg query HKCU /f password /t REG_SZ /s'
    'Searching for stored credentials'         = 'Get-ChildItem -Path "C:\Users\$env:username\AppData\Local\Microsoft\Credentials\","C:\Users\$env:username\AppData\Roaming\Microsoft\Credentials\" -ErrorAction SilentlyContinue'
    'PowerShell History'                       = 'Get-Content "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -ErrorAction SilentlyContinue'
    'Searching for database files'             = 'Get-ChildItem -Path C:\ -Include *.sqlite,*.db,*.mdf,*.ldf -File -Recurse -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime, Length'
    'Checking for common misconfigurations'    = {
        $results = @()
        
        # Proxy ayarları
        try {
            $proxy = Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" | Select-Object ProxyServer, ProxyEnable
            $results += "Proxy settings: $($proxy.ProxyServer) (Enabled: $($proxy.ProxyEnable))"
        } catch {
            $results += "Proxy settings: Error retrieving"
        }
        
        # WSL kontrolleri
        if (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux | Where-Object { $_.State -eq 'Enabled' }) {
            $results += "WSL is enabled - could check for Linux misconfigurations"
        }
        
        # WDigest kimlik bilgilerini belleğe kaydetme kontrolü
        try {
            $wdigest = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential" -ErrorAction SilentlyContinue
            if ($wdigest -and $wdigest.UseLogonCredential -eq 1) {
                $results += "WDigest UseLogonCredential enabled - passwords stored in plaintext in memory!"
            }
        } catch {
            $results += "WDigest check: Error"
        }
        
        # Hibernasyon dosyası var mı?
        if (Test-Path "C:\hiberfil.sys") {
            $results += "Hibernation file exists - may contain sensitive data"
        }
        
        # Denetim politikasını kontrol et
        try {
            $auditPolicy = auditpol /get /category:* /r | ConvertFrom-Csv
            $weakAuditing = $auditPolicy | Where-Object { $_."Inclusion Setting" -eq "No Auditing" }
            if ($weakAuditing) {
                $results += "Weak auditing settings found: $($weakAuditing.count) categories have 'No Auditing'"
            }
        } catch {
            $results += "Audit policy check: Error"
        }
        
        # Otomatik güncellemeleri kontrol et
        try {
            $au = (New-Object -ComObject "Microsoft.Update.AutoUpdate").Settings
            $results += "Windows Auto Update enabled: $($au.NotificationLevel -ne 1)"
        } catch {
            $results += "Auto Update check: Error"
        }
        
        return $results
    }
    'Checking for vulnerable drivers'         = {
        $drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DriverVersion -ne $null }
        $knownVulnDrivers = @(
            @{Name="dbutil_2_3.sys"; Version="2.3"; Vendor="Dell"},
            @{Name="rtcore64.sys"; Version=""; Vendor="Micro-Star"},
            @{Name="gdrv.sys"; Version=""; Vendor="Gigabyte"},
            @{Name="atillk64.sys"; Version=""; Vendor="ATI"},
            @{Name="nvlddmkm.sys"; Version="<455.23.04"; Vendor="NVIDIA"}
        )
        
        $results = foreach ($vulnDriver in $knownVulnDrivers) {
            foreach ($driver in $drivers) {
                if ($driver.DeviceName -like "*$($vulnDriver.Name)*" -or $driver.DriverName -like "*$($vulnDriver.Name)*") {
                    [PSCustomObject]@{
                        DriverName = $driver.DeviceName
                        DriverFile = $driver.DriverName
                        Version = $driver.DriverVersion
                        KnownVulnerable = $true
                        Details = "Matches known vulnerable driver: $($vulnDriver.Name)"
                    }
                }
            }
        }
        
        return $results
    }
    'Checking registry for AutoRuns'         = 'Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run","Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"'
    'Checking for saved RDP connections'     = 'Get-ChildItem -Path "HKCU:\Software\Microsoft\Terminal Server Client\Servers" -ErrorAction SilentlyContinue | ForEach-Object { [PSCustomObject]@{ Server = $_.PSChildName; Username = (Get-ItemProperty -Path "Registry::$($_.Name)").UsernameHint } }'
    'Checking for weak SSL/TLS'              = {
        $sslSettings = @()
        
        # SSL 2.0
        $ssl2Server = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" -Name Enabled -ErrorAction SilentlyContinue).Enabled
        $sslSettings += "SSL 2.0 Server: $(if($ssl2Server -eq 0){"Disabled"} elseif($ssl2Server -eq 1){"Enabled"} else{"Not configured"})"
        
        # SSL 3.0
        $ssl3Server = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" -Name Enabled -ErrorAction SilentlyContinue).Enabled
        $sslSettings += "SSL 3.0 Server: $(if($ssl3Server -eq 0){"Disabled"} elseif($ssl3Server -eq 1){"Enabled"} else{"Not configured"})"
        
        # TLS 1.0
        $tls10Server = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Name Enabled -ErrorAction SilentlyContinue).Enabled
        $sslSettings += "TLS 1.0 Server: $(if($tls10Server -eq 0){"Disabled"} elseif($tls10Server -eq 1){"Enabled"} else{"Not configured"})"
        
        # TLS 1.1
        $tls11Server = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -Name Enabled -ErrorAction SilentlyContinue).Enabled
        $sslSettings += "TLS 1.1 Server: $(if($tls11Server -eq 0){"Disabled"} elseif($tls11Server -eq 1){"Enabled"} else{"Not configured"})"
        
        # TLS 1.2
        $tls12Server = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -Name Enabled -ErrorAction SilentlyContinue).Enabled
        $sslSettings += "TLS 1.2 Server: $(if($tls12Server -eq 0){"Disabled"} elseif($tls12Server -eq 1){"Enabled"} else{"Not configured"})"
        
        # TLS 1.3 (Windows Server 2022 ve Windows 11'de)
        $tls13Server = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server" -Name Enabled -ErrorAction SilentlyContinue).Enabled
        $sslSettings += "TLS 1.3 Server: $(if($tls13Server -eq 0){"Disabled"} elseif($tls13Server -eq 1){"Enabled"} else{"Not configured"})"
        
        return $sslSettings
    }
    'Hardware Information'                  = 'Get-WmiObject -Class Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory, DomainRole'
    'Installed Windows Features'            = 'Get-WindowsFeature | Where-Object {$_.Installed -eq $true} | Format-Table Name,DisplayName'
    'PowerShell Module Logging'             = 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name EnableModuleLogging -ErrorAction SilentlyContinue | Format-Table'
    'PowerShell Script Block Logging'       = 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name EnableScriptBlockLogging -ErrorAction SilentlyContinue | Format-Table'
    'Active Directory Information'          = {
        if ((Get-WmiObject win32_computersystem).partofdomain -eq $true) {
            try {
                $results = @()
                $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                $results += "Domain Name: $($domain.Name)"
                $results += "Domain Controllers: $($domain.DomainControllers | ForEach-Object { $_.Name })"
                $results += "Forest Name: $($domain.Forest.Name)"
                $results += "Forest Functional Level: $($domain.Forest.ForestMode)"
                return $results
            } catch {
                return "Machine is domain-joined but cannot retrieve AD information."
            }
        } else {
            return "Machine is not part of a domain."
        }
    }
}

# Seçim işlemi ve komut çalıştırma
function ExecuteCommands {
    param($commands, $outPath)
    $totalCommands = $commands.Count
    $currentCommand = 0
    
    foreach ($command in $commands.GetEnumerator()) {
        $currentCommand++
        $percent = [Math]::Round(($currentCommand / $totalCommands) * 100)
        Write-Progress -Activity "Running pentest commands" -Status "$($command.Key)" -PercentComplete $percent
        
        try {
            whost $command.Key
            
            # Command türüne göre çalıştır
            if ($command.Value -is [scriptblock]) {
                $output = & $command.Value
            } else {
                $output = Invoke-Expression $command.Value
            }
            
            # Sonuçları kaydet
            $outFile = Join-Path -Path $outPath -ChildPath "$($command.Key).txt"
            $output | Out-File $outFile -Encoding UTF8 -Force
            Write-Host "✓ Başarıyla tamamlandı" -ForegroundColor Green
        } catch {
            Write-Host "✗ Komut başarısız: $($command.Key)" -ForegroundColor Red
            Write-Host "  Hata: $($_.Exception.Message)" -ForegroundColor Red
            "ERROR: $($_.Exception.Message)" | Out-File (Join-Path -Path $outPath -ChildPath "$($command.Key)_ERROR.txt") -Encoding UTF8 -Force
        }
    }
    Write-Progress -Activity "Running pentest commands" -Status "Complete" -PercentComplete 100 -Completed
}

# Çalıştırma işlemi
$startTime = Get-Date
Write-Host "Pentest çalıştırılıyor... Başlangıç zamanı: $startTime" -ForegroundColor Cyan
Write-Host "Sonuçlar şuraya kaydedilecek: $basePath" -ForegroundColor Cyan

# Sistem özeti oluştur
$systemInfo = [ordered]@{
    "Host Name" = $env:COMPUTERNAME
    "Operating System" = (Get-WmiObject -Class Win32_OperatingSystem).Caption
    "OS Version" = (Get-WmiObject -Class Win32_OperatingSystem).Version
    "Architecture" = $env:PROCESSOR_ARCHITECTURE
    "User" = "$env:USERDOMAIN\$env:USERNAME"
    "Domain" = if ((Get-WmiObject win32_computersystem).partofdomain) { (Get-WmiObject win32_computersystem).domain } else { "Not in a domain" }
    "IP Address" = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1" } | Select-Object -First 1).IPAddress
    "Date/Time" = Get-Date
}

$systemInfo | Format-Table Name, Value | Out-File "$basePath\00_system_summary.txt" -Encoding UTF8 -Force

# Bruteforce işlemi
if ($bruteforce) {
    whost "Bruteforce saldırısı başlatılıyor..."
    if (-not $userList -or -not $passwordList) {
        Write-Host "Bruteforce için kullanıcı listesi ve şifre listesi gereklidir." -ForegroundColor Red
    } else {
        $bruteResults = Invoke-BruteForce -userList $userList -passwordList $passwordList
        $bruteResults | Out-File "$basePath\bruteforce_results.txt" -Encoding UTF8 -Force
        $bruteResults | Format-Table | Out-Host
    }
}

# Port tarama işlemi
if ($portscan) {
    whost "Port taraması başlatılıyor..."
    if (-not $targetHost) {
        $targetHost = "localhost"
    }
    
    if (-not $ports) {
        $ports = @(21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 3389, 8080)
    }
    
    $scanResults = Invoke-PortScan -hostname $targetHost -ports $ports
    $scanResults | Out-File "$basePath\port_scan_results.txt" -Encoding UTF8 -Force
    $scanResults | Format-Table | Out-Host
}

# Komutları çalıştır
if ($extended) {
    Write-Host "Genişletilmiş taramalar çalıştırılıyor..." -ForegroundColor Yellow
    ExecuteCommands $standard_commands $basePath
    ExecuteCommands $extended_commands $basePath
    
    # Potansiyel zayıf noktaları tanımla ve rapor oluştur
    whost "Potansiyel zayıf noktalar belirleniyor..."
    $vulnerabilities = @()
    
    # AlwaysInstallElevated kontrolü
    $aieFile = "$basePath\AlwaysInstallElevated Check.txt"
    if (Test-Path $aieFile) {
        $aieContent = Get-Content $aieFile
        if ($aieContent -match "Enabled") {
            $vulnerabilities += [PSCustomObject]@{
                Severity = "High"
                Finding = "AlwaysInstallElevated is enabled"
                Description = "This allows regular users to install MSI packages with SYSTEM privileges"
                Mitigation = "Disable AlwaysInstallElevated registry keys in HKLM and HKCU"
            }
        }
    }
    
    # Unquoted Service Paths kontrolü
    $uspFile = "$basePath\Unquoted Service Paths.txt"
    if (Test-Path $uspFile) {
        $uspContent = Get-Content $uspFile
        if ($uspContent -and $uspContent -notmatch "^$") {
            $vulnerabilities += [PSCustomObject]@{
                Severity = "Medium"
                Finding = "Unquoted Service Paths detected"
                Description = "Services with unquoted paths can lead to privilege escalation"
                Mitigation = "Use quotes around service paths with spaces"
            }
        }
    }
    
    # Antivirus kontrolü
    $avFile = "$basePath\Anti-virus Products.txt"
    if (Test-Path $avFile) {
        $avContent = Get-Content $avFile
        if (-not $avContent -or $avContent -match "Disabled") {
            $vulnerabilities += [PSCustomObject]@{
                Severity = "High"
                Finding = "Anti-virus software appears to be disabled or missing"
                Description = "System lacks proper anti-malware protection"
                Mitigation = "Install and enable anti-virus software"
            }
        }
    }
    
    # Geçersiz izinler kontrolü
    $permFiles = "$basePath\Folders with Everyone Permissions.txt", "$basePath\Folders with BUILTIN\Users Permissions.txt"
    foreach ($file in $permFiles) {
        if (Test-Path $file) {
            $permContent = Get-Content $file
            if ($permContent -and $permContent -notmatch "^$") {
                $vulnerabilities += [PSCustomObject]@{
                    Severity = "Medium"
                    Finding = "Excessive permissions detected on system folders"
                    Description = "Folders with overly permissive access rights could lead to privilege escalation"
                    Mitigation = "Review and restrict folder permissions"
                }
                break
            }
        }
    }
    
    # RDP erişimi kontrolü
    $rdpFile = "$basePath\RDP Status.txt"
    if (Test-Path $rdpFile) {
        $rdpContent = Get-Content $rdpFile
        if ($rdpContent -match "0") {
            $vulnerabilities += [PSCustomObject]@{
                Severity = "Informational"
                Finding = "RDP is enabled on this system"
                Description = "Remote Desktop is accessible, which increases attack surface"
                Mitigation = "Disable RDP if not required, or enforce Network Level Authentication"
            }
        }
    }
    
    # WinRM kontrolü
    $winrmFile = "$basePath\WinRM Status.txt"
    if (Test-Path $winrmFile) {
        $winrmContent = Get-Content $winrmFile
        if ($winrmContent -match "Running") {
            $vulnerabilities += [PSCustomObject]@{
                Severity = "Informational"
                Finding = "WinRM service is running"
                Description = "Windows Remote Management service increases attack surface"
                Mitigation = "Disable WinRM if not required"
            }
        }
    }
    
    # PowerShell Script Block Logging kontrolü
    $psLoggingFile = "$basePath\PowerShell Script Block Logging.txt"
    if (Test-Path $psLoggingFile) {
        $psLoggingContent = Get-Content $psLoggingFile
        if (-not $psLoggingContent -or -not ($psLoggingContent -match "1")) {
            $vulnerabilities += [PSCustomObject]@{
                Severity = "Low"
                Finding = "PowerShell Script Block Logging is disabled"
                Description = "Lack of PowerShell logging reduces visibility into potential attacks"
                Mitigation = "Enable PowerShell Script Block Logging through Group Policy"
            }
        }
    }
    
    # SSL/TLS konfigürasyon kontrolü
    $sslFile = "$basePath\Checking for weak SSL_TLS.txt"
    if (Test-Path $sslFile) {
        $sslContent = Get-Content $sslFile
        if ($sslContent -match "SSL [23].0.*Enabled|TLS 1.0.*Enabled|TLS 1.1.*Enabled") {
            $vulnerabilities += [PSCustomObject]@{
                Severity = "Medium"
                Finding = "Weak SSL/TLS protocols are enabled"
                Description = "Outdated SSL/TLS protocols pose security risks"
                Mitigation = "Disable SSL 2.0, SSL 3.0, TLS 1.0, and TLS 1.1"
            }
        }
    }
    
    # Firewall kontrolü
    $firewallFile = "$basePath\Firewall Config.txt"
    if (Test-Path $firewallFile) {
        $firewallContent = Get-Content $firewallFile
        if ($firewallContent -match "False") {
            $vulnerabilities += [PSCustomObject]@{
                Severity = "High"
                Finding = "Windows Firewall appears to be disabled"
                Description = "Disabled firewall exposes system to network-based attacks"
                Mitigation = "Enable Windows Firewall on all profiles"
            }
        }
    }
    
    # WDigest kontrolü
    $wdigestFile = "$basePath\Checking for common misconfigurations.txt"
    if (Test-Path $wdigestFile) {
        $wdigestContent = Get-Content $wdigestFile
        if ($wdigestContent -match "WDigest UseLogonCredential enabled") {
            $vulnerabilities += [PSCustomObject]@{
                Severity = "High"
                Finding = "WDigest credentials in memory"
                Description = "WDigest is storing credentials in plaintext in memory"
                Mitigation = "Disable WDigest by setting UseLogonCredential to 0 in registry"
            }
        }
    }
    
    # Zafiyet raporu oluştur
    $vulnerabilities | Sort-Object -Property @{Expression = {
        switch ($_.Severity) {
            "High" { 1 }
            "Medium" { 2 }
            "Low" { 3 }
            "Informational" { 4 }
            default { 5 }
        }
    }} | Format-Table -AutoSize | Out-File "$basePath\vulnerability_report.txt" -Encoding UTF8 -Force
    
    # HTML rapor oluştur
    if ($htmlreport) {
        Generate-HTMLReport -basePath $basePath -vulnerabilities $vulnerabilities -systemInfo $systemInfo
    }
    
    # Zarif özet raporu oluştur
    $summary = @"
# PenTest Sonuç Özeti
Tarih: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Makine: $env:COMPUTERNAME
Kullanıcı: $env:USERNAME

## Sistem Bilgisi
- İşletim Sistemi: $((Get-WmiObject -Class Win32_OperatingSystem).Caption)
- Versiyon: $((Get-WmiObject -Class Win32_OperatingSystem).Version)
- Domain: $(if ((Get-WmiObject win32_computersystem).partofdomain) { (Get-WmiObject win32_computersystem).domain } else { "Domain üyesi değil" })

## Güvenlik Açıkları Özeti
$(if ($vulnerabilities.Count -eq 0) { "Hiçbir belirgin güvenlik açığı tespit edilmedi." } else { "Toplam $($vulnerabilities.Count) potansiyel güvenlik açığı tespit edildi." })

### Şiddet Düzeyine Göre Açıklar
- Yüksek: $($vulnerabilities | Where-Object { $_.Severity -eq "High" } | Measure-Object).Count
- Orta: $($vulnerabilities | Where-Object { $_.Severity -eq "Medium" } | Measure-Object).Count
- Düşük: $($vulnerabilities | Where-Object { $_.Severity -eq "Low" } | Measure-Object).Count
- Bilgilendirme: $($vulnerabilities | Where-Object { $_.Severity -eq "Informational" } | Measure-Object).Count

## İleri Adımlar
1. Ekteki vulnerability_report.txt dosyasını inceleyin
2. Güvenlik açıklarını önceliklendirilmiş şekilde düzeltin
3. Düzeltmeleri doğrulamak için başka bir tarama çalıştırın
"@
    $summary | Out-File "$basePath\summary_report.txt" -Encoding UTF8 -Force
} else {
    # Sadece standart komutları çalıştır
    ExecuteCommands $standard_commands $basePath
    
    # HTML rapor oluştur
    if ($htmlreport) {
        Generate-HTMLReport -basePath $basePath -vulnerabilities @() -systemInfo $systemInfo
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime

# Sonuçları ZIP olarak sıkıştır ve şifrele
if ($encrypt) {
    whost "Sonuçlar şifreleniyor..."
    $zipFile = "$basePath.zip"
    
    if (-not $encryptionKey) {
        # Rastgele bir şifre oluştur
        $charSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
        $encryptionKey = 1..16 | ForEach-Object { $charSet[(Get-Random -Maximum $charSet.Length)] } | Join-String
    }
    
    # 7-Zip varsa onu kullan, yoksa .NET sıkıştırma kullan
    $7zipPath = "${env:ProgramFiles}\7-Zip\7z.exe"
    if (Test-Path $7zipPath) {
        & $7zipPath a -tzip -p"$encryptionKey" -mem=AES256 $zipFile $basePath
    } else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($basePath, $zipFile)
        Write-Host "Not: 7-Zip bulunamadı, şifreleme için 7-Zip kurmanız önerilir." -ForegroundColor Yellow
    }
    
    # Şifreyi farklı bir dosyaya kaydet
    $encryptionKey | Out-File "$basePath-password.txt" -Encoding UTF8 -Force
    Write-Host "ZIP şifresi: $encryptionKey" -ForegroundColor Cyan
    Write-Host "Şifreli ZIP oluşturuldu: $zipFile" -ForegroundColor Green
}

# Son durum mesajı
Write-Host "`nPenetrasyon testi tamamlandı!" -ForegroundColor Green
Write-Host "Başlangıç: $startTime" -ForegroundColor Cyan
Write-Host "Bitiş: $endTime" -ForegroundColor Cyan
Write-Host "Toplam süre: $($duration.TotalMinutes.ToString('0.00')) dakika" -ForegroundColor Cyan
Write-Host "Sonuçlar şurada bulunabilir: $basePath" -ForegroundColor Yellow

# Stealth modunu devre dışı bırak
if ($stealth) {
    try {
        Write-Host "Stealth mode devre dışı bırakılıyor..." -ForegroundColor Cyan
        $logSettings = Get-WinEvent -ListLog "Microsoft-Windows-PowerShell/Operational"
        $logSettings.IsEnabled = $true
        $logSettings.SaveChanges()
        Set-ExecutionPolicy $originalExecutionPolicy -Scope Process -Force
    }
    catch {
        Write-Host "Olay günlüğü etkinleştirilemedi. Hata: $($_.Exception.Message)" -ForegroundColor Red
    }
}