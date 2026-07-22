# atilgandev — Backend Mühendisi

**Go · PostgreSQL · ödeme sistemleri · yüksek doğruluk gerektiren yazılım**

Ek derinlik: uçtan uca ürün teslimatı (full-stack), uygulamalı bilgisayarlı görü ve akıllı
kontrat güvenliği.

📍 Türkiye · ✉️ [E-posta](mailto:hilberspace@gmail.com) · Ayrıntılı portföy (İngilizce): [README.md](README.md)

---

## Çalışma biçimim

Bu portföydeki her iddianın arkasında okuyucunun kendisinin kontrol edebileceği bir şey vardır:
bir benchmark komutu, herkese açık bir CI koşusu, yazılı bir kanıt dosyası veya bir tekrar üretme
tarifi.

## Mühendislik standardı

→ **[`METHODOLOGY.md`](METHODOLOGY.md)** — bu portföyün tamamında uyguladığım doğrulama standardı:
ortamı sabitle, testten önce değişmezleri tanımla, negatif kontrolü zorunlu tut, kanıtı koru ve doğru
sonuç “bulgu yok” olduğunda da sonucu aynen raporla.

## Projeler

**1. ReconPilot — Ödeme Mutabakat Motoru** ([vaka çalışması](projects/03-reconpilot-payment-reconciliation/) · [kaynak kod](https://github.com/hilberspace-dev/reconpilot))
Bir e-ticaret operasyonunun üç para raporunu — PSP, banka ekstresi, pazaryeri hakedişi — kuruşuna
kadar uzlaştıran deterministik motor. Dört doğruluk garantisi çalışma zamanı kontrolleri ve
PostgreSQL kısıtları arasında açıkça bölünür. Herkese açık benchmark: ~50.000 işlem, 7 enjekte
edilmiş uyuşmazlık tipi → **7/7 tespit, 0 yanlış eşleşme, ~4 saniye**; her push'ta CI yeniden koşar.
Aynı statik binary, sürümlü bir REST endpoint'i, HTML raporu, health/readiness kontrollerini ve
Prometheus metriklerini sunar. Tohumlanmış PostgreSQL demosu tek Docker Compose komutuyla açılır.

**2. Aura — Fotogerçekçi 3D Cerrahi Önizleme ve Klinik Platformu** *(özel, ticari)* ([vaka çalışması](projects/04-aura-photoreal-3d-clinic-platform/))
Tek mühendis, ~800 commit: ~15 saniyelik telefon videosundan fotogerçekçi 3D kafa (3D Gaussian
Splatting, çevrimdışı GPU işi), tarayıcıda ~0,4 saniyede anlık 2.5D önizleme, milimetre cinsinden
simülasyon matematiği, 838 açık erişimli klinik yayınla doğrulanmış sonuç tahmini. KVKK/HIPAA
uyumlu veri işleme. Kaynak kod gizlidir; vaka çalışması yalnızca kapsamı ve hassas olmayan
ölçümleri anlatır.

**3. ERC-4337 EntryPoint v0.8 — Güvenlik İncelemesi** ([vaka çalışması](projects/02-erc4337-entrypoint-review/))
Defalarca denetlenmiş altyapı kodunda gerçek (düşük şiddetli) bir kusur bulundu ve iki bağımsız
yöntemle kanıtlandı. Sorumlu ifşa gereği mekanizma, üretici düzeltene kadar açıklanmıyor.

**4. Canlı Protokol Güvenlik Denetimi (~16,7M $) — Disiplinli bir "sorun yok" kararı** ([vaka çalışması](projects/01-smart-contract-security-audit/))
~16,7M $ tutan canlı bir sistemde en güçlü zafiyet hipotezi gerçek zincir verisi üzerinde yeniden
üretildi ve kendi kanıtıyla çürütüldü. Hiçbir bulgu şişirilmeden "güvenli" raporlandı — güvenlik
işinde en zor ve en değerli disiplin.

## Çalışma tercihi ve iletişim

**Sözleşmeli ve alt-yüklenici işlere açığım** — ajans veya lider geliştirici arkasında bağımsız
teknik teslimat: kapsamı belli bir işi alır, bağımsız çalışır, testleri ve kanıtıyla teslim ederim.

Yazılı İngilizcem şartname, dokümantasyon, ticket ve kod incelemesi için profesyonel düzeydedir;
sözlü iletişimi öncelikle Türkçe yürütürüm.

✉️ [E-posta](mailto:hilberspace@gmail.com)

---

*Bu, işler tamamlandıktan sonra yayımlanmış derlenmiş bir portföydür. Commit tarihleri yayımlama
ve dokümantasyon geçmişini yansıtır, orijinal geliştirme takvimini değil.*
