[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](README.md)

# Vaka çalışması: ERC-4337 EntryPoint v0.8 güvenlik incelemesi

> ### Bulgu: `EntryPoint` v0.8 çekirdeğinde deterministik bir doğruluk kusuru
>
> | | |
> |---|---|
> | Şiddet | Low (düşük): hata kaynağının atfedilmesiyle ilgili bir doğruluk kusuru; varlık hırsızlığına da sansüre de yol açmıyor |
> | Önceki denetimler | Repoda üç herkese açık denetim raporu bulunuyor |
> | Tekrar üretim | İki kez: önce yerel geliştirme ortamında, ardından digest ile sabitlenmiş Prague istemcisinde gerçek EIP-7702 semantiğiyle |
> | Kusuru ayıran kanıt | Eşdeğer durumu doğru ele alan paralel kod yolu |
> | Projenin durumu | İnceleme sırasında hâlâ düzeltilmemişti |
> | İfşa durumu | Bakımcılarla 11 Ekim 2026'da iletişime geçildi ([issue #632](https://github.com/eth-infinitism/account-abstraction/issues/632)); tam rapor orada ya da verecekleri özel adreste paylaşılacak. Hiçbir programa gönderilmedi. Mekanizma, rapor paylaşılana kadar gizli (aşağıda) |

- Rol: bağımsız güvenlik araştırmacısı
- Hedef: ERC-4337 Hesap Soyutlama, `EntryPoint` v0.8 çekirdek sözleşmeleri (açık kaynak, yaygın kullanım)
- Kapsam commit'i: `4cbc06072cdc19fd60f285c5997f4f7f57a588de`
- Sonuç: Low şiddetinde deterministik bir doğruluk kusuru. İki bağımsız PoC ile tekrar üretildi ve
  tam bir rapor olarak yazıldı (bölümleri aşağıda).

> Teknik olmayan okurlar için kısaca: On milyonlarca kripto para cüzdanı hesabı, işlemlerini ortak
> bir altyapı kodundan, ERC-4337'nin `EntryPoint` sözleşmesinden geçiriyor. Bu kodun yayımlanmış üç
> profesyonel denetimi var. Kodun 0.8 sürümünü bağımsız olarak inceledim ve belirli
> işlemler başarısız olduğunda hatanın kime ait olduğunu kaydeden bölümde küçük ama gerçek bir kusur
> buldum. Bu bir muhasebe/atfetme hatası ve para çalmak için kullanılamıyor. İki ayrı ortamda tekrar
> ürettim; tam mekanizma kapalı kalıyor.

> İfşa durumu, 11 Ekim 2026. Rapor yazıldı, gönderilmeye hazır. Aynı gün bakımcılara
> [issue #632](https://github.com/eth-infinitism/account-abstraction/issues/632) üzerinden yazdım ve
> tam raporu orada mı yoksa özel bir adreste mi istediklerini sordum. Rapor paylaşılana kadar dosya,
> fonksiyon ve mekanizma ne issue'da ne bu sayfada geçiyor; rapor ve iki kanıt, hangisini
> söylerlerse oraya gidecek. Bulgu hiçbir bug bounty programına gönderilmedi, kusur da upstream'de
> henüz düzeltilmedi. Bağımsız teyit henüz bekleniyor ve bunun önünü bakımcıların yanıtı açar. Teyit
> gelirse bu sayfa bunu söyleyecek. Hiçbir programın bulguyu incelediği, doğruladığı veya
> ödüllendirdiği iddia edilmiyor; tam materyaller talep üzerine, gizlilik koşuluyla özel olarak
> paylaşılabilir.

## Hedef

ERC-4337 `EntryPoint` reposunda üç herkese açık denetim raporu var: ikisi OpenZeppelin'in (Şubat
2023 ve Şubat 2024), biri de v0.8 değişikliklerini kapsayan, 25 Mart 2025 tarihli Spearbit raporu.
Kodun ne kadar kullanıldığına gelince:
[Alchemy](https://www.alchemy.com/overviews/what-is-account-abstraction), Ethereum ve layer-2
ağlarında 40 milyondan fazla ERC-4337 akıllı hesabı açıldığını söylüyor;
[BundleBear](https://www.bundlebear.com/erc4337-overview/all) ise 11 Ekim 2026'da en az bir user
operation göndermiş 68,9 milyon adres gösteriyordu. İki sayı da tüm `EntryPoint` sürümlerini
birlikte sayıyor; ikisi de yalnızca v0.8 için ayrı bir sayı vermiyor.

Bulgunun kendisi küçük: varlık çalmaya ya da sansüre yarayan bir açık değil, Low şiddetinde bir
atfetme/doğruluk kusuru. Sayfanın geri kalanı, kusurun nasıl bulunup kanıtlandığını anlatıyor.

## Yöntem

### Değişmez doğrudan protokol dokümantasyonundan alındı

Projenin arayüz dokümanı bir özelliği açıkça tanımlıyor; kusur bu özelliği ihlal ediyor. Rapor bu
belgelenmiş semantiği kaynak gösteriyor ve kusuru protokolün kendi şartnamesine göre ölçüyor.

### Paralel bir kod yoluyla ayrıştırıldı

Aynı fonksiyondaki benzer bir yol eşdeğer durumu doğru ele alıyor; yani kod aynı durumu bir yerde
doğru, öbür yerde yanlış işliyor. Bu, gözden kaçmış bir şeye benziyor ve bulguyu değerlendirenlerin
en sık getirdiği itiraza, "tasarım böyle" itirazına da baştan cevap veriyor.

### Kanıtın içinde negatif kontrol var

Kusurlu senaryoda da kontrol senaryosunda da başarısız işlem aynı konumda duruyor ve yanlış bilgiyi
yalnızca etkilenen kod yolu raporluyor. İki senaryo arasındaki tek fark izlenen kod yolu; hatanın
kaynağı test düzeneği olamaz.

### İki çalışma ortamı kullanıldı

Yerel geliştirme ortamı kontrol akışındaki kusuru ayırabiliyor, ama bu yolun dayandığı delegation
semantiğini çalıştıramayan bir EVM sürümünde kalıyor. İkinci PoC, delegation'ı gerçekten
çalıştırmak için digest ile sabitlenmiş Prague istemcisinde, gerçek bir authorization tuple ve
zincirde çalışan bir delegate ile koşuyor. Orada görülen iç revert mesajı delegate'in kendi mesajı;
yani delegation kodu gerçekten çalışmış ve dala ilgisiz bir nedenle girilmemiş.

### Etki, erişilebilirlik sınırlarıyla birlikte değerlendirildi

Rapor, birincil etkiyi (kapsam içindeki deterministik doğruluk kusuru) ikincil etkilerden ayrı
tutuyor. İkincil etkiler olasılık kipiyle ("may") yazılıyor. Belirli bir zincir dışı tüketicinin
davranışına bağlı oldukları da açıkça belirtiliyor. Rapor ayrıca kusurun kimseye varlık
kaybettirmediğini, yetkisiz çalıştırmaya ya da zincir üzerinde doğrudan sansüre de yol açmadığını
açıkça söylüyor. Erişilebilirlik sınırını da belgeliyor: standartlara uygun bir bundler, başarısız
işlemi daha pakete girmeden eleyecek.

## Rapor yapısı

Raporun bölümleri şunlar:

Başlık · Özet · Şiddet · Etkilenen commit ve kapsam içindeki dosyalar (destek dosyaları kapsam dışı
olarak işaretli) · Hatalı kod ve doğru paralel yol ile kök neden · Beklenen ve gerçekleşen davranış ·
Gözlenebilir deterministik kusur · Protokol düzeyinde etki (birincil ve koşula bağlı ikincil) ·
Erişilebilirlik ve sınırlamalar · Ortamın sabitlenmesi · Üretim kodunda değişiklik olmadığının kanıtı ·
Dosyaların doğru konumuyla tekrar üretme adımları · Tam komutlar ve değiştirilmemiş çıktı · Negatif
kontrol · PoC kaynakları · Herkese açık mükerrer bulgu araması · Somut yama önerisi.

Mükerrer bulgu araması repodaki üç denetim raporunu, kod yorumlarını, mevcut testleri, upstream
issue ve pull request'leri, sürüm notlarını ve ilgili ERC şartnamelerini kapsadı. Herkese açık bir
mükerrer bulguya rastlanmadı. En yakın önceki bulgunun konumu da mekanizması da farklı; üstelik
incelenen ağaçta zaten düzeltilmiş. Özel raporlar ise dışarıdan görülemiyor.

## Kanıt dosyaları

| Dosya | İçerik |
|---|---|
| `evidence/reproducibility.md` | Ortam sabitleme, istemci digest'i, iki PoC sonucu ve üretim kodu diff kanıtı |
| [`METHODOLOGY.tr.md`](../../METHODOLOGY.tr.md) | Bu çalışmada izlenen mühendislik standardının Türkçe sürümü |
| `private-annex/` | Tam rapor, iki PoC test dosyası ve yalnızca teste ait yardımcı sözleşme (gizlilik koşuluyla, talep üzerine) |

*Kanıt dosyalarındaki komutlar ve ham çıktılar, birebir doğrulanabilsin diye özgün dillerinde
bırakıldı.*

## Kullanılan teknoloji

Solidity · Hardhat · TypeScript · ERC-4337 Hesap Soyutlama · EIP-7702 delegation · EVM hardfork
semantiği (Cancun ve Prague) · Digest ile sabitlenmiş geth · Foundry tarzı negatif kontrollü test
tasarımı
