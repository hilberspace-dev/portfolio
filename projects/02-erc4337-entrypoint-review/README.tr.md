[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](README.md)

# Vaka Çalışması — ERC-4337 EntryPoint v0.8 Güvenlik İncelemesi

> ### Bulgu: `EntryPoint` v0.8 çekirdeğinde deterministik bir doğruluk kusuru
>
> | | |
> |---|---|
> | **Şiddet** | Low (düşük) — hata kaynağının atfedilmesi/doğruluk; varlık hırsızlığı veya sansür değil |
> | **Hedefin zorluğu** | Ekosistemin en yoğun denetlenmiş sözleşmelerinden biri; repoda üç herkese açık denetim raporu bulunuyor |
> | **Tekrar üretim** | **İki kez** — önce yerel geliştirme ortamında, ardından digest ile sabitlenmiş Prague istemcisinde gerçek EIP-7702 semantiğiyle |
> | **Kusuru ayıran kanıt** | Eşdeğer durumu **doğru** ele alan paralel kod yolu; “tasarım böyle” ihtimalini eliyor |
> | **Projenin durumu** | İnceleme sırasında hâlâ düzeltilmemişti |
> | **İfşa durumu** | Herhangi bir programa **gönderilmedi**; mekanizma aşağıda açıklanan nedenle gizli tutuluyor |

**Rol:** Bağımsız güvenlik araştırmacısı (tek başına)<br>
**Hedef:** ERC-4337 Hesap Soyutlama — `EntryPoint` v0.8 çekirdek sözleşmeleri
(açık kaynak, yaygın kullanım)<br>
**Kapsam commit'i:** `4cbc06072cdc19fd60f285c5997f4f7f57a588de`<br>
**Sonuç:** **Low şiddetinde** deterministik bir doğruluk kusuru bulundu, iki bağımsız PoC ile tekrar
üretildi ve gönderime hazır raporlandı.

> **Teknik olmayan kısa anlatım.** Milyonlarca kripto para cüzdanı, profesyonel ekiplerce en az üç
> kez incelenmiş ortak bir altyapı koduna dayanıyor. Bu kodu bağımsız olarak inceledim ve belirli
> işlemler başarısız olduğunda hatanın kime ait olduğunu kaydeden bölümde küçük ama gerçek bir kusur
> buldum. Bu bir para çalma yöntemi değil, hatalı muhasebeleştirme/atfetme problemi. Kusuru iki ayrı
> ortamda tekrar ürettim; geliştiriciler düzeltme yapana kadar teknik tarifi yayımlamıyorum.

> **İfşa durumu — açık ifade.** Rapor gönderime hazırlandı ancak herhangi bir bug bounty programına
> **gönderilmedi** ve kusur upstream'de **henüz düzeltilmedi**. Bu nedenle dosya, fonksiyon ve
> mekanizma bilgileri bu herkese açık vaka çalışmasında özellikle çıkarıldı. Hiçbir programın bulguyu
> incelediği, doğruladığı veya ödüllendirdiği iddia edilmiyor. Tam materyaller, gizlilik koşuluyla ve
> talep üzerine özel olarak paylaşılabilir.

---

## Bu çalışma neyi gösteriyor?

ERC-4337 `EntryPoint`, ekosistemin en yoğun denetlenmiş sözleşmelerinden biri. Repoda üç herkese açık
denetim raporu bulunuyor ve kod birden fazla güvenlik firması tarafından incelendi. Böyle bir hedefte
gerçek bir kusur bulmak, kontrol listesi uygulamaktan çok daha dikkatli kaynak kod okuması gerektirir.

Bulgu, **Low şiddetinde bir atfetme/doğruluk kusuru**; varlık çalma veya sansür açığı değil. Çalışma,
yoğun biçimde denetlenmiş altyapıda şartnameye dayalı analizi, çalışma ortamına sadakati ve kontrollü
tekrar üretimi gösteriyor.

---

## Yöntem

**Değişmez doğrudan protokol dokümantasyonundan alındı.** Kusur, projenin arayüz dokümanında açıkça
tanımlanan bir özelliği ihlal ediyor. Rapor, doğru davranışın ölçütü olarak bu belgelenmiş semantiği
kullanıyor; yani sorun benim nasıl çalışması gerektiğine dair yorumum değil, protokolün kendi
şartnamesinden somut bir sapma.

**Paralel bir kod yoluyla ayrıştırıldı.** Aynı fonksiyondaki benzer bir yol, eşdeğer durumu
**doğru** ele alıyor. Bu asimetriyi göstermek, “burası şüpheli görünüyor” gözlemini “bu nesnel olarak
gözden kaçmış bir durum” kanıtına dönüştürüyor ve incelemeyi yapan kişinin en güçlü itirazını baştan
ortadan kaldırıyor.

**Kanıtın içinde negatif kontrol var.** Hem kusurlu senaryoda hem kontrol senaryosunda başarısız
işlem aynı konuma yerleştiriliyor; yalnızca etkilenen kod yolu yanlış bilgi raporluyor. İki senaryo
arasındaki tek fark izlenen kod yolu olduğu için hatanın test düzeneğinden kaynaklanmadığı gösteriliyor.

**İki çalışma ortamı kullanıldı.** Yerel geliştirme ortamı, kontrol akışındaki kusuru ayırabiliyor ancak bu
yolun dayandığı delegation semantiğini **çalıştıramayan bir EVM sürümünde** kalıyor. Bu nedenle ikinci
PoC, digest ile sabitlenmiş Prague istemcisinde gerçek bir authorization tuple ve zincirde çalışan delegate
ile çalışıyor. İç revert mesajı doğrudan delegate'in kendi mesajı; böylece delegation kodunun gerçekten
çalıştığı ve dala ilgisiz bir nedenle girilmediği doğrulanıyor.

**Etki, erişilebilirlik sınırlarıyla birlikte değerlendirildi.** Rapor, **birincil etkiyi**
(kapsam içindeki deterministik doğruluk kusuru) belirli bir zincir dışı tüketicinin davranışına bağlı
**ikincil etkilerden** ayırıyor. İkincil etkiler kesin sonuç gibi değil, olasılık olarak yazılıyor.
Rapor açıkça şunları belirtiyor: *varlık kaybı yok, yetkisiz çalıştırma yok, zincir üzerinde doğrudan
sansür yok.* Standartlara uygun bir bundler'ın başarısız işlemi pakete girmeden eleyeceği de
belgeleniyor; böylece erişilebilirlik sınırını incelemeyi yapan kişinin sonradan keşfetmesi gerekmiyor.

---

## Rapor yapısı

Her bulguda kullandığım gönderim şablonu izlendi:

Başlık · Özet · Şiddet · Etkilenen commit ve kapsam içindeki dosyalar (destek dosyaları kapsam dışı
olarak işaretli) · Hatalı kod ve doğru paralel yol ile kök neden · Beklenen ve gerçekleşen davranış ·
Gözlenebilir deterministik kusur · Protokol düzeyinde etki (birincil ve koşula bağlı ikincil) ·
Erişilebilirlik ve sınırlamalar · Ortamın sabitlenmesi · Üretim kodunda değişiklik olmadığının kanıtı ·
Dosyaların doğru konumuyla tekrar üretme adımları · Tam komutlar ve değiştirilmemiş çıktı · Negatif
kontrol · PoC kaynakları · Herkese açık mükerrer bulgu araması · Somut yama önerisi.

**Mükerrer bulgu araması**; repodaki üç denetim raporunu, kod yorumlarını, mevcut testleri, upstream
issue ve pull request'leri, sürüm notlarını ve ilgili ERC şartnamelerini kapsadı. En yakın önceki
bulgu bulunup incelendi; konum ve mekanizma bakımından **farklı** olduğu, ayrıca incelenen ağaçta
zaten düzeltildiği doğrulandı. Herkese açık bir mükerrer bulguya rastlanmadı; özel raporların içeriği
ise gözlemlenemiyor.

---

## Kanıt dosyaları

| Dosya | İçerik |
|---|---|
| `evidence/reproducibility.md` | Ortam sabitleme, istemci digest'i, iki PoC sonucu ve üretim kodu diff kanıtı |
| [`METHODOLOGY.tr.md`](../../METHODOLOGY.tr.md) | Bu çalışmada izlenen mühendislik standardının Türkçe sürümü |
| `private-annex/` | Tam rapor, iki PoC test dosyası ve yalnızca teste ait yardımcı sözleşme — gizlilik koşuluyla talep üzerine |

*Kanıt dosyalarındaki komutlar ve ham çıktılar, birebir doğrulanabilirlik için özgün dilinde
tutulur.*

## Kullanılan teknoloji

Solidity · Hardhat · TypeScript · ERC-4337 Hesap Soyutlama · EIP-7702 delegation · EVM hardfork
semantiği (Cancun ve Prague) · Digest ile sabitlenmiş geth · Foundry tarzı negatif kontrollü test
tasarımı
