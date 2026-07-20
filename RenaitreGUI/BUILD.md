# Build Talimatları

## 1. .NET 8 SDK Kur

Tarayıcıdan indir ve kur:
https://dotnet.microsoft.com/download/dotnet/8.0

Kurulumu doğrula:
```
dotnet --version
```
`8.x.x` çıktısı görmen gerekiyor.

## 2. Bağımlılıkları Yükle ve Derle

Proje klasörüne git:
```
cd RenaitreGUI
```

İlk derleme (NuGet paketlerini indirir):
```
dotnet build
```

## 3. Çalıştır (geliştirme sırasında)

```
dotnet run
```

## 4. Tek .exe Olarak Yayınla (dağıtım için)

```
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o ./publish
```

Çıktı: `./publish/RenaitreSabre.exe`
Bu dosyayı istediğin bilgisayara kopyalayabilirsin — .NET kurulu olmak zorunda değil.

## Notlar
- Uygulama admin yetkisi ister (app.manifest ayarı)
- HandyControl ve System.Management.Automation NuGet üzerinden otomatik indirilir
- İlk build internete ihtiyaç duyar (NuGet restore)
