[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](README.md)

# Vaka Çalışması — Akıllı Sözleşme Güvenlik Denetimi (Immunefi Bug Bounty, Arbitrum One)

**Rol:** Bağımsız güvenlik araştırmacısı (tek başına)<br>
**Hedef:** Variational — Arbitrum One üzerindeki herkese açık Immunefi bug bounty programı
(chainId 42161)<br>
**Süre:** Odaklanmış 2 çalışma oturumu<br>
**Sonuç:** **NO-GO — bildirime uygun bir güvenlik açığı bulunmadı. Hiçbir şey gönderilmedi.**

> **Teknik olmayan kısa anlatım.** Yaklaşık 16,7 milyon dolarlık kullanıcı varlığını akıllı
> sözleşmelerde tutan bir yatırım platformu, sistemini bozabilen kişilere açık ödül veriyordu. En
> güçlü açık ihtimalini baştan sona inceledim ve platformun gerçek canlı durumunu kullanan çalışan
> bir simülasyon kurdum. Simülasyon, gözlenen durumun aynı işlem içinde geri alınabildiğini ve ödül
> kapsamına giren bir güvenlik açığı oluşturmadığını gösterdi. Hipotezin neden geçersiz olduğunu
> kanıtlarıyla belgeleyip herhangi bir rapor göndermeden incelemeyi durdurdum.

---

## Neden “bulgu yok” sonucunu anlatan bir vaka çalışması?

Bu çalışma, **disiplinli bir negatif sonucu** gösteriyor. Yoğun biçimde denetlenmiş bir hedefte yanlış
pozitif üretmek hem inceleme zamanını boşa harcar hem de zayıf bir başvuruya yol açar. Bu yüzden
teslim edilen şey yalnızca araştırma değil, hangi noktada durulacağına ilişkin kanıtlı karardır.

Buradaki çıktı, çalıştırılabilir kanıta dayanan şu karardır: **dur; çünkü devam etmemek için somut
gerekçe var.**

---

## Çalışmanın gerektirdikleri

1. Programın tam olarak hangi bulgulara ödeme yaptığını belirlemek ve kuralları zaman damgasıyla
   sabitlemek.
2. Zincir üzerindeki durumu tek bir bloğa sabitleyerek sonraki bütün iddiaları tekrar üretilebilir
   kılmak.
3. Benzer isimli açık kaynak repoyu değil, zincirde çalışan kodun **tam kaynağını** elde etmek.
4. Açık aramaya başlamadan önce sistemdeki para akışlarını, güven sınırlarını ve güvenlik
   değişmezlerini modellemek.
5. En güçlü hipotezi çalıştırılabilir bir kanıtla sınamak ve sonuç ne çıkarsa çıksın kabul etmek.

---

## Seçilmiş teknik çalışmalar

**Zincir analizi (salt okunur JSON-RPC).**

Bug bounty kapsamında adı geçen üç varlıktan ikisinin, üzerinde sözleşme kodu bulunmayan
**harici sahipli hesaplar (EOA)** olduğunu belirledim. Bu cüzdanlar sırasıyla yaklaşık 11,7 milyon ve
5,0 milyon USDC tutuyordu. Böylece gerçek saldırı yüzeyi, zincirde çalışan tek bir sözleşme ile onun
oluşturduğu minimal proxy klonlarına kadar daraldı. Yaklaşık 45 milyon bloktaki sözleşme oluşturma
olaylarını taradığımda **38.485 klon** buldum; her birinin aynı implementation sözleşmesi adresine
yönelen EIP-1167 minimal proxy olduğunu byte düzeyinde doğruladım.

**Kaynak kodun kökeni ve bytecode doğrulaması.**

Kod içeren üç sözleşmenin doğrulanmış kaynaklarını aldım; derleyici ayarlarını
(solc 0.8.28, optimizer runs=20000) kaydettim ve zincirdeki runtime bytecode'un yayımlanan kaynakla
eşleştiğini doğruladım. Zincirdeki her runtime kodunun keccak256 değerini kaydettim ve herhangi bir test
sonucuna güvenmeden önce bu değerleri fork içinde, sabitlenen blokta yeniden kontrol ettim.

**Değişmezler şartnamesi.**

Varlıkların saklanması, tekrar oynatma/benzersizlik, havuz kimliği, liveness, token davranışı ve
upgrade edilebilirlik başlıklarında 14 değişmez yazdım. Her değişmez için biçimsel koşulu, koşulu
uygulayan `dosya:satır` konumunu, varsayımları ve kırılabileceği en olası yolu kaydettim. Hipotezler
sezgiden değil, bu şartnameden üretildi.

**Fork üzerinde çalışan PoC.**

Arbitrum'u sabit bir blokta fork eden ve **zincirdeki gerçek sözleşmelerle** çalışan bir Foundry test
düzeneği kurdum. En güçlü hipotezi, negatif kontrol ve maliyet sınırı testiyle birlikte uçtan uca
sınadım. Üç testin de geçmesi, hipotezin ödüle uygun bir açık **olmadığını** kanıtladı: protokol
operatörü durumu aynı işlem içinde geri alabiliyordu; dolayısıyla yetkisiz bir kullanıcının varlıkları
kalıcı biçimde etkilenmiyordu. Ayrıntılar `evidence/` klasöründe.

**Önceki çalışmalar ve mükerrer bulgu analizi.**

Hedefin herkese açık üçüncü taraf güvenlik incelemesini bulup arşivledim ve SHA-256 değerini
kaydettim. Rapordaki iki High bulguyu çalışan kodla karşılaştırdım: biri tasarım değişikliğiyle zaten
giderilmişti, diğeri ise ayrıcalıklı yetkiye bağlı ve önceden kabul edilmiş bir konuydu. İncelemedeki
çok sayıda bulgunun kamuya açıklanmadığını da belgeledim; bu nedenle mükerrer bulgu riskini sayısal
olarak belirlemek mümkün değildi. Kararda bu risk tahmin edilmedi, açıkça “bilinmiyor” olarak
kaydedildi.

---

## Karar

Sistemin, operatör gözetimindeki ince bir mutabakat katmanı olduğu ortaya çıktı: kullanıcı teminatını
yalnızca ayrıcalıklı operatör rolü hareket ettirebiliyor ve yetkisiz kullanıcıların çağırabildiği,
durum değiştiren yalnızca **bir** giriş noktası bulunuyordu. En güçlü hipotez fork üzerinde tekrar
üretildi, ardından **kendi kanıtıyla çürütüldü**. Gözlenen etki anında geri alınabiliyor ve saldırgana
maliyeti, mağdura verdiği zarardan daha yüksek oluyordu.

Her biri hipotezi desteklemek yerine *çürütmekle* görevlendirilen üç bağımsız itiraz turu, aynı kod
referanslarıyla aynı sonuca ulaştı.

**Sonuç: NO-GO.** Rapor gönderilmedi. Teslim edilen öneri, daha iyi yapısal getiri ihtimali olan başka
bir hedefe yönelmekti.

---

## Profesyonel yaklaşım

- **Mainnet'e karşı yalnızca okuma yapıldı.** Hiçbir işlem yayınlanmadı. Bütün exploit testleri yerel
  fork üzerinde çalıştı; canlı altyapı yoklanmadı veya yük altına sokulmadı.
- **İfşa yapılmadı.** Hedef program, yayımdan önce onay gerektiriyor. Çalışma bildirilebilir bir bulgu
  üretmediği için programa gönderilecek bir rapor yok; incelenen mekanizma da bu herkese açık vaka
  çalışmasında özellikle anlatılmıyor.
- **Bilinmeyenler açık bırakıldı.** Erişilemeyen bir rapor ile pruned archive node sonucu tahmin
  edilmek yerine `UNKNOWN` olarak kaydedildi.

---

## Kanıt dosyaları

| Dosya | İçerik |
|---|---|
| [`METHODOLOGY.tr.md`](../../METHODOLOGY.tr.md) | Çalışma boyunca izlenen mühendislik standardının Türkçe sürümü |
| `evidence/reproducibility.md` | Çalışma ortamının sabitlenmesi, sabit blok, kod hash'i doğrulaması ve test çıktısı |
| `evidence/ForkPoC.t.sol` | Foundry fork testi (mekanizmayı açığa çıkarmayan bölüm) |
| `private-annex/` | Bulguların tamamı, değişmezler şartnamesi ve tam PoC — talep üzerine |

*Kanıt dosyalarındaki komutlar ve ham çıktılar, birebir doğrulanabilirlik için özgün dilinde
tutulur.*

## Kullanılan teknoloji

Solidity · Foundry (forge / cast / anvil) · EVM fork testleri · JSON-RPC zincir analizi ·
EIP-1167 minimal proxy'ler · EIP-1967 proxy slot'ları · ERC-20 muhasebesi · Node.js araçları · Git
