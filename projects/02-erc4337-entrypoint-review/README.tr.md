[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](README.md)

# Vaka çalışması: ERC-4337 EntryPoint v0.8 güvenlik incelemesi

> ### Bulgu: `EntryPoint` v0.8 çekirdeğinde deterministik bir doğruluk kusuru
>
> | | |
> |---|---|
> | Şiddet | Low (düşük): hata kaynağının atfedilmesiyle ilgili bir doğruluk kusuru; varlık hırsızlığına da sansüre de yol açmıyor |
> | Önceki denetimler | Repoda üç herkese açık denetim raporu bulunuyor |
> | Tekrar üretim | İki kez: önce yerel geliştirme ortamında, ardından digest ile sabitlenmiş Prague istemcisinde gerçek EIP-7702 semantiğiyle |
> | Kusuru ayıran kanıt | Eşdeğer durumu doğru ele alan paralel kod yolu; "tasarım böyle" ihtimalini eliyor |
> | Projenin durumu | İnceleme sırasında hâlâ düzeltilmemişti |
> | İfşa durumu | Herhangi bir programa gönderilmedi; mekanizma aşağıda açıklanan nedenle gizli tutuluyor |

- Rol: bağımsız güvenlik araştırmacısı
- Hedef: ERC-4337 Hesap Soyutlama, `EntryPoint` v0.8 çekirdek sözleşmeleri (açık kaynak, yaygın kullanım)
- Kapsam commit'i: `4cbc06072cdc19fd60f285c5997f4f7f57a588de`
- Sonuç: Low şiddetinde deterministik bir doğruluk kusuru bulundu, iki bağımsız PoC ile tekrar üretildi
  ve gönderime hazır biçimde raporlandı.

> Teknik olmayan okurlar için kısaca: Milyonlarca kripto para cüzdanı, profesyonel ekiplerce en az üç
> kez incelenmiş ortak bir altyapı koduna dayanıyor. Bu kodu bağımsız olarak inceledim ve belirli
> işlemler başarısız olduğunda hatanın kime ait olduğunu kaydeden bölümde küçük ama gerçek bir kusur
> buldum. Kusur bir muhasebe/atfetme hatası; para çalmak için kullanılamıyor. İki ayrı ortamda tekrar
> ürettim. Tam mekanizma kapalı kalıyor.

> İfşa durumu: Rapor gönderime hazırlandı, ancak herhangi bir bug bounty programına gönderilmedi ve
> kusur upstream'de henüz düzeltilmedi. Bu nedenle dosya, fonksiyon ve mekanizma bilgileri bu herkese
> açık vaka çalışmasından çıkarıldı. Hiçbir programın bulguyu incelediği, doğruladığı veya
> ödüllendirdiği iddia edilmiyor. Tam materyaller gizlilik koşuluyla, talep üzerine özel olarak
> paylaşılabilir.

## Hedef

ERC-4337 `EntryPoint` reposunda üç herkese açık denetim raporu bulunuyor ve kodu birden fazla
güvenlik firması inceledi.

Bulgu, Low şiddetinde bir atfetme/doğruluk kusuru; varlık çalmaya da sansüre de imkân vermiyor. Bu
sayfanın geri kalanı, kusurun nasıl bulunup kanıtlandığını anlatıyor.

## Yöntem

### Değişmez doğrudan protokol dokümantasyonundan alındı

Kusur, projenin arayüz dokümanında açıkça tanımlanan bir özelliği ihlal ediyor. Rapor, doğru
davranışın ölçütü olarak bu belgelenmiş semantiği kullanıyor; yani kusur, protokolün kendi
şartnamesine göre ölçülüyor. Kodun nasıl çalışması gerektiğine dair kişisel yorumum işin içine
girmiyor.

### Paralel bir kod yoluyla ayrıştırıldı

Aynı fonksiyondaki benzer bir yol, eşdeğer durumu doğru ele alıyor. Bu asimetriyi göstermek, "burası
şüpheli görünüyor" gözlemini "bu nesnel olarak gözden kaçmış bir durum" kanıtına dönüştürüyor.
Böylece "tasarım böyle" ihtimali eleniyor ve incelemeyi yapan kişinin en sık getirdiği itiraz baştan
ortadan kalkıyor.

### Kanıtın içinde negatif kontrol var

Hem kusurlu senaryoda hem kontrol senaryosunda başarısız işlem aynı konuma yerleştiriliyor; yalnızca
etkilenen kod yolu yanlış bilgi raporluyor. İki senaryo arasındaki tek fark izlenen kod yolu olduğu
için hatanın kaynağı test düzeneği olamaz.

### İki çalışma ortamı kullanıldı

Yerel geliştirme ortamı kontrol akışındaki kusuru ayırabiliyor, ama bu yolun dayandığı delegation
semantiğini çalıştıramayan bir EVM sürümünde kalıyor. Bu yüzden ikinci PoC, digest ile sabitlenmiş
Prague istemcisinde gerçek bir authorization tuple ve zincirde çalışan bir delegate ile koşuyor. İç
revert mesajı doğrudan delegate'in kendi mesajı. Bu da delegation kodunun gerçekten çalıştığını ve
dala ilgisiz bir nedenle girilmediğini doğruluyor.

### Etki, erişilebilirlik sınırlarıyla birlikte değerlendirildi

Rapor, birincil etkiyi (kapsam içindeki deterministik doğruluk kusuru) ikincil etkilerden ayırıyor.
İkincil etkiler olasılık kipiyle ("may") yazılıyor ve belirli bir zincir dışı tüketicinin davranışına
bağlı oldukları açıkça belirtiliyor. Rapor açıkça şunu söylüyor: varlık kaybı yok, yetkisiz çalıştırma
yok, zincir üzerinde doğrudan sansür yok. Standartlara uygun bir bundler'ın başarısız işlemi pakete
girmeden eleyeceği de belgeleniyor; incelemeyi yapan kişi bu erişilebilirlik sınırını kendisi keşfetmek
zorunda kalmıyor.

## Rapor yapısı

Raporun bölümleri şunlar:

Başlık · Özet · Şiddet · Etkilenen commit ve kapsam içindeki dosyalar (destek dosyaları kapsam dışı
olarak işaretli) · Hatalı kod ve doğru paralel yol ile kök neden · Beklenen ve gerçekleşen davranış ·
Gözlenebilir deterministik kusur · Protokol düzeyinde etki (birincil ve koşula bağlı ikincil) ·
Erişilebilirlik ve sınırlamalar · Ortamın sabitlenmesi · Üretim kodunda değişiklik olmadığının kanıtı ·
Dosyaların doğru konumuyla tekrar üretme adımları · Tam komutlar ve değiştirilmemiş çıktı · Negatif
kontrol · PoC kaynakları · Herkese açık mükerrer bulgu araması · Somut yama önerisi.

Mükerrer bulgu araması repodaki üç denetim raporunu, kod yorumlarını, mevcut testleri, upstream issue
ve pull request'leri, sürüm notlarını ve ilgili ERC şartnamelerini kapsadı. En yakın önceki bulgu
incelendi: konumu ve mekanizması farklı, üstelik incelenen ağaçta zaten düzeltilmiş. Herkese açık bir
mükerrer bulguya rastlanmadı. Özel raporlar ise dışarıdan görülemiyor.

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
