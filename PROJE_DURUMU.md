# Renaitre — Proje Durum Dosyası
> Son güncelleme: 2026-07-17

---

## Proje Nedir?

**Renaitre** (RenaitreSabre), Mert Altuntaş tarafından geliştirilen bir Windows IT / Sistem / Ağ / Pentest araç kitidir.

### Vizyon
Tek bir arayüzden:
- **Siber güvenlik** araçları (yetkili denetim / pentest)
- **Klasik kullanıcı ütiliteleri** (uygulama kurma, ağ tanılama)
- **Güvenli IT / helpdesk** bölümü (tek tıkla onarım, güvenlik durumu)

> "Bunu yaptığımda yapay zeka dünyada bile yoktu." — Mert
> Şimdi AI desteğiyle gerçek bir ürüne dönüştü.

---

## Mimari (C# WPF)

| Karar | Neden |
|---|---|
| **C# WPF / .NET 8** | Native Windows exe, self-contained publish, AV false-positive minimum |
| **HandyControl** | Dark tema temeli |
| **Süreç tabanlı PS** | `System.Management.Automation` yok; scriptler `powershell.exe`/`cmd.exe` süreci olarak çalışır → hafif, AV dostu, iptal edilebilir |
| **app.manifest** | `requireAdministrator` (temiz elevation, UAC bypass yok) |
| **Cyberpunk tema** | Neon magenta + cyan, glow, grid arka plan — projenin kimliği |

### Klasör Yapısı
```
RenaitreGUI/
├── App.xaml(.cs)              → başlangıç + global hata loglama (error.log)
├── MainWindow.xaml(.cs)       → başlık çubuğu + sidebar + frame navigasyon
├── app.manifest               → requireAdministrator
├── Views/
│   ├── DashboardView          → sistem özeti + canlı CPU/RAM/çoklu-disk ölçerleri (GB bilgisi)
│   ├── AppStoreView           → winget arama/kurulum/yükseltme
│   ├── RepairView             → tek tık onarım (SFC/DISM/chkdsk/temp/restore point/explorer)
│   ├── NetworkView            → ağ araçları + Wi-Fi profil görüntüleyici
│   ├── SecurityView           → güvenlik durumu paneli (Defender/Firewall/BitLocker/UAC/WU)
│   ├── PentestView            → WindowsEnum, SabreNum, Soul (SMB brute) — guardrail'li
│   ├── SabreView              → çift onaylı sistem temizleyici
│   ├── SettingsView           → çıktı klasörü / log yönetimi / hakkında
│   └── ConfirmDialog          → cyberpunk temalı onay penceresi (MessageBox yerine)
├── Services/
│   ├── PowerShellService.cs   → async PS/cmd, real-time output, çıktı klasörü yönetimi
│   ├── WingetService.cs       → winget (admin PATH çözümü + yapılandırılmış arama)
│   └── AdminService.cs        → admin kontrolü
└── Resources/
    ├── Scripts/ (windowsenum, sabrenum, soul .ps1 — embedded)
    └── Themes/RenaitreTheme.xaml → cyberpunk palet + stiller + glow efektleri
```

---

## Şu An Neredeyiz?

### ✅ Tamamlananlar
- [x] Build çalışıyor (0 uyarı, 0 hata), uygulama açılıyor
- [x] İlk 5 kusur düzeltildi (winget PATH, admin badge, null uyarıları, script çıktı klasörü, winget çıktı temizliği)
- [x] **Cyberpunk tema** — neon magenta+cyan, glow, grid arka plan
- [x] **Dashboard** — kaydırmasız Grid layout, canlı CPU/RAM/**çoklu disk** ölçerleri + GB bilgisi
- [x] **Repair Center** — tek tık onarım/bakım (SFC, DISM, chkdsk, temp, restore point, explorer restart, DNS flush, Store cache)
- [x] **Security Posture** paneli — Defender/Firewall/BitLocker/UAC/WU/reboot → renkli durum pill'leri
- [x] **Wi-Fi profil görüntüleyici** (Network) — kayıtlı ağlar + şifreleri
- [x] **Temalı ConfirmDialog** — Windows MessageBox yerine cyberpunk onay
- [x] **Hata loglama** → `Belgeler\RenaitreSabre\error.log`
- [x] **Settings** sayfası — çıktı klasörü / log yönetimi / sistem bilgisi
- [x] Pentest: WindowsEnum/SabreNum'a **Stop**, Soul'a **IP doğrulama**
- [x] Enum çıktı yolları öngörülebilir yapıldı (`Belgeler\RenaitreSabre\enum`)
- [x] Ölü kod temizliği
- [x] **DoS aracı (DDoS/Ping-flood) kaldırıldı** — ilkelere aykırı; yedek `Renaitreold/`'da

### ❌ Sonraki Adımlar
- [ ] Kullanıcı tarafından son özelliklerin canlı doğrulanması (Security/Wi-Fi/Repair)
- [ ] Tek-dosya publish (`dotnet publish -r win-x64 --self-contained -p:PublishSingleFile=true`)
- [ ] Terminal çıktısını dosyaya kaydet + Ctrl+L kısayolu
- [ ] Winget "upgrade" checklist (seç-kur)
- [ ] Tema aksan renk presetleri (Settings)
- [ ] (İsteğe bağlı) kod imzalama — ticari dağıtım

---

## Nasıl Çalıştırılır?

```powershell
cd "C:\Users\merta\Desktop\All in one\Github\Renaitre\RenaitreGUI"
dotnet build
.\bin\Debug\net8.0-windows\RenaitreSabre.exe   # UAC → Evet
```

### Dağıtım için tek .exe
```powershell
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o ./publish
```

---

## Önemli Notlar
1. **Pentest araçları** (Soul, enum'lar) AV tarafından flaglenebilir — beklenen; GUI'nin kendisi flaglenmemeli.
2. **Yalnızca yetkili sistemlerde** kullanılmalıdır — Pentest sayfasında uyarı + IP doğrulama + onay mevcut.
3. **Sabre** geri alınamaz işlemler yapar — çift onay kasıtlı.
4. Uygulama elevated açıldığından, geliştirme sırasında açık uygulama `.dll`'i kilitler → yeniden derlemeden önce kapatılmalı.
5. **Color↔Brush tuzağı:** WPF'te `Color` kaynağını Brush özelliğine verme; ayrı `SolidColorBrush` tanımla (runtime hatası, derlemede görünmez).
