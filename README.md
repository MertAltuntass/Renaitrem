# Renaitre (RenaitreSabre)

Windows için tek arayüzlü **IT / Sistem / Ağ / Güvenlik / Pentest** araç kiti — C# WPF (.NET 8).

Eski `.bat` sürümünden modern, cyberpunk temalı bir masaüstü uygulamasına taşındı.

## Bölümler
- **Dashboard** — canlı CPU/RAM/disk izleme, hızlı aksiyonlar
- **App Store** — winget ile uygulama kur/yükselt
- **Repair Center** — tek tıkla sistem onarımı (SFC, DISM, chkdsk, temp, geri yükleme noktası…)
- **Network** — ağ tanılama + Wi-Fi profil görüntüleyici
- **Security** — güvenlik durumu paneli (Defender, Firewall, BitLocker, UAC…)
- **Pentest** — yetkili sistemler için enum/denetim araçları
- **Sabre** — çift onaylı sistem temizleyici
- **Settings** — çıktı/log yönetimi, sistem bilgisi

## Çalıştırma
```powershell
cd RenaitreGUI
dotnet build
.\bin\Debug\net8.0-windows\RenaitreSabre.exe
```
> Uygulama yönetici hakları ister (UAC).

## Uyarı
Pentest araçları **yalnızca kendi sistemlerinde veya izin alınmış çalışmalarda** kullanılmalıdır. İzinsiz kullanım yasa dışıdır.

Ayrıntılı durum ve mimari için: [`PROJE_DURUMU.md`](PROJE_DURUMU.md)
