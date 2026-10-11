[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](README.md)

# Vaka çalışması: akıllı sözleşme güvenlik denetimi (Immunefi bug bounty, Arbitrum One)

- Rol: bağımsız güvenlik araştırmacısı
- Hedef: Variational, Arbitrum One üzerindeki herkese açık Immunefi bug bounty programı (chainId 42161)
- Süre: odaklanmış 2 çalışma oturumu
- Sonuç: **NO-GO.** Bildirime uygun bir güvenlik açığı bulunmadı; hiçbir şey gönderilmedi.

> Teknik olmayan okurlar için kısaca: Takas (settlement) mantığı akıllı sözleşmelerde çalışan ve
> yaklaşık 16,7 milyon dolarlık kullanıcı varlığı iki operatör cüzdanında duran bir platform,
> sistemini bozmanın yolunu bulana ödül vereceğini açıkça duyurmuştu. En güçlü açık ihtimalini
> baştan sona inceledim ve platformun gerçek, canlı durumunu kullanan çalışan bir simülasyon kurdum.
> Simülasyon, gözlenen durumun aynı işlem içinde geri alınabildiğini ve ödül kapsamına giren bir
> güvenlik açığı oluşturmadığını gösterdi. Hipotezin neden geçersiz olduğunu kanıtlarıyla belgeledim
> ve rapor göndermeden incelemeyi durdurdum.

## Neden "bulgu yok" diye biten bir vaka çalışması?

Çalışma negatif bir sonuçla bitti; bu sayfa o sonuca nasıl varıldığını anlatıyor. Yoğun biçimde
denetlenmiş bir hedefte yanlış pozitif, inceleme zamanını boşa harcayabilir ve zayıf bir başvuruya
dönüşebilir. O yüzden nerede durulacağını bilmek de işin parçası. Sonuç, gerekçesi çalıştırılabilir
kanıta dayanan bir durma kararı oldu.

## Çalışmanın gerektirdikleri

1. Programın tam olarak hangi bulgulara ödeme yaptığını belirlemek ve kuralları zaman damgasıyla
   sabitlemek.
2. Zincir üzerindeki durumu tek bir bloğa sabitleyerek sonraki bütün iddiaları tekrar üretilebilir
   kılmak.
3. Zincirde çalışan sözleşmelerin tam kaynağını elde etmek. Benzer isimli açık kaynak bir repo bunun
   yerini tutmaz.
4. Açık aramaya başlamadan önce sistemdeki para akışlarını, güven sınırlarını ve güvenlik
   değişmezlerini modellemek.
5. En güçlü hipotezi çalıştırılabilir bir kanıtla sınamak ve sonuç ne çıkarsa çıksın kabul etmek.

## Seçilmiş teknik çalışmalar

### Zincir analizi (salt okunur JSON-RPC)

Bug bounty kapsamında adı geçen üç varlıktan ikisinin, üzerinde sözleşme kodu bulunmayan harici
sahipli hesaplar (EOA) olduğu ortaya çıktı. Bu cüzdanlar sırasıyla yaklaşık 11,7 milyon ve 5,0 milyon
USDC tutuyordu. Böylece gerçek saldırı yüzeyi, zincirde çalışan tek bir sözleşmeye ve onun oluşturduğu
minimal proxy klonlarına indi. Yaklaşık 45 milyon bloktaki sözleşme oluşturma olaylarını taradığımda
38.485 klon buldum; her birinin aynı implementation sözleşmesine yönelen EIP-1167 minimal proxy
olduğunu byte düzeyinde doğruladım.

### Kaynak kodun kökeni

Kod içeren üç sözleşmenin doğrulanmış kaynaklarını aldım, derleyici ayarlarını (solc 0.8.28,
optimizer runs=20000) kaydettim ve zincirdeki runtime bytecode'un yayımlanan kaynakla eşleştiğini
doğruladım. Her runtime kodunun keccak256 değerini de kaydettim; herhangi bir test sonucuna güvenmeden
önce bu değerleri fork içinde, sabitlenen blokta yeniden kontrol ettim.

### Değişmezler şartnamesi

Varlıkların saklanması, tekrar oynatma/benzersizlik, havuz kimliği, liveness, token davranışı ve
upgrade edilebilirlik başlıklarında 14 değişmez yazdım. Her değişmez için biçimsel koşulu, onu
uygulayan `dosya:satır` konumunu, varsayımları ve kırılabileceği en olası yolu kaydettim. Hipotezler
bu şartnameden çıkarıldı.

### Fork üzerinde çalışan PoC

Arbitrum'u sabit bir blokta fork eden ve zincirdeki gerçek sözleşmelerle çalışan bir Foundry test
düzeneği kurdum. En güçlü hipotezi negatif kontrol ve maliyet sınırı testiyle birlikte uçtan uca
sınadım. Üç test de geçti ve birlikte hipotezin ödüle uygun bir açık olmadığını kanıtladı: protokol
operatörü durumu aynı işlem içinde geri alabiliyordu, dolayısıyla yetkisiz bir kullanıcının varlıkları
kalıcı biçimde etkilenmiyordu. Ayrıntılar `evidence/` klasöründe.

### Önceki incelemelerle mükerrerlik kontrolü

Hedefin herkese açık üçüncü taraf güvenlik incelemesini bulup arşivledim ve SHA-256 değerini
kaydettim. Rapordaki iki High bulguyu şu an çalışan kodla karşılaştırdım: biri tasarım değişikliğiyle
zaten giderilmişti, diğeri ise ayrıcalıklı yetkiye bağlı ve önceden kabul edilmiş bir konuydu.
İncelemedeki bulguların önemli bir kısmı kamuya açıklanmamıştı, bu yüzden mükerrer bulgu riskini
sayıya dökmek mümkün olmadı. Karar bu riski "bilinmiyor" diye kaydediyor.

## Karar

Sistemin, kullanıcı varlıklarının operatörün elinde durduğu ince bir settlement katmanı olduğu
ortaya çıktı. Kullanıcı teminatını yalnızca ayrıcalıklı operatör rolü hareket ettirebiliyordu ve
yetkisiz kullanıcıların çağırabildiği, durum değiştiren tam olarak bir giriş noktası vardı. En güçlü
hipotez fork üzerinde tekrar üretildi, ardından kendi kanıtıyla çürütüldü: gözlenen etki hemen geri
alınabiliyordu ve saldırgana maliyeti, mağdura verdiği zarardan yüksekti.

Hipotez koddan üç kez yeniden kontrol edildi; her kontrol aynı sonuca ve aynı kod referanslarına
ulaştı.

**Sonuç: NO-GO.** Rapor gönderilmedi. Varılan sonuç, emeği getiri yapısı daha elverişli başka bir
hedefe yöneltmekti.

## Profesyonel yaklaşım

- Mainnet'e yalnızca okuma amacıyla erişildi. Hiçbir işlem yayınlanmadı; bütün exploit testleri yerel
  fork üzerinde çalıştı, canlı altyapı yoklanmadı ve yük altına sokulmadı.
- Hedef program, yayımdan önce onay istiyor. Çalışma bildirilebilir bir bulgu üretmediği için
  programa gönderilecek bir rapor yok. Yine de incelenen mekanizma bu herkese açık vaka çalışmasında
  anlatılmıyor.
- Erişilemeyen bir rapor ile pruned archive node sonucu `UNKNOWN` olarak kaydedildi; ikisi için de
  tahmin yapılmadı.

## Kanıt dosyaları

| Dosya | İçerik |
|---|---|
| [`METHODOLOGY.tr.md`](../../METHODOLOGY.tr.md) | Çalışma boyunca izlenen mühendislik standardının Türkçe sürümü |
| `evidence/reproducibility.md` | Çalışma ortamının sabitlenmesi, sabit blok, kod hash'i doğrulaması ve test çıktısı |
| `evidence/ForkPoC.t.sol` | Foundry fork testi (mekanizmayı açığa çıkarmayan bölüm) |
| `private-annex/` | Bulguların tamamı, değişmezler şartnamesi ve tam PoC (talep üzerine) |

*Kanıt dosyalarındaki komutlar ve ham çıktılar, birebir doğrulanabilsin diye özgün dillerinde
bırakıldı.*

## Kullanılan teknoloji

Solidity · Foundry (forge / cast / anvil) · EVM fork testleri · JSON-RPC zincir analizi ·
EIP-1167 minimal proxy'ler · EIP-1967 proxy slot'ları · ERC-20 muhasebesi · Node.js araçları · Git
