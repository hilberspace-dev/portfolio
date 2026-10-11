[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](README.md)

# Vaka çalışması: akıllı sözleşme güvenlik denetimi (Immunefi bug bounty, Arbitrum One)

- Rol: bağımsız güvenlik araştırmacısı
- Hedef: Variational, Arbitrum One üzerindeki herkese açık Immunefi bug bounty programı (chainId 42161)
- Süre: odaklanmış 2 çalışma oturumu
- Sonuç: **NO-GO.** Bildirime uygun bir güvenlik açığı bulunmadı; hiçbir şey gönderilmedi.

> Teknik olmayan okurlar için kısaca: Takas (settlement) mantığı akıllı sözleşmelerde çalışan bir
> platform, sistemini bozmanın yolunu bulana ödül vereceğini açıkça duyurmuştu. Yaklaşık 16,7 milyon
> dolarlık kullanıcı varlığı iki operatör cüzdanında duruyordu. En umut verici zayıflığı alıp baştan
> sona izledim; platformun gerçek, canlı durumunu kullanan, çalışan bir simülasyon kurdum. Tutmadı.
> Gözlediğim durum aynı işlem içinde geri alınabiliyordu ve ödül kapsamına giren bir açık değildi.
> Nedenini yazdım ve rapor göndermeden incelemeyi bıraktım.

## Neden "bulgu yok" diye biten bir vaka çalışması?

Çalışma bulgusuz bitti; bu sayfa o sonuca nasıl vardığımı anlatıyor. Çok denetlenmiş bir hedefte
yanlış pozitif, inceleme zamanını yiyip zayıf bir başvuruya dönüşebilir. Nerede durulacağını bilmek
de işin parçası. Burada sonuç bir durma kararıydı ve arkasındaki kanıt çalıştırılabilir.

## Çalışmanın gerektirdikleri

1. Programın tam olarak neye ödeme yaptığını belirlemek ve bu kuralları zaman damgasıyla
   sabitlemek.
2. Zincir üzerindeki durumu tek bir bloğa sabitleyerek sonraki bütün iddiaları tekrar üretilebilir
   kılmak.
3. Zincirde çalışan sözleşmelerin tam kaynağını elde etmek. Benzer isimli açık kaynak bir repo bunun
   yerini tutmaz.
4. Açık aramaya başlamadan önce sistemin para akışlarını, güven sınırlarını ve güvenlik
   değişmezlerini modellemek.
5. En güçlü hipotezi çalıştırılabilir bir kanıtla sınamak ve sonuç ne çıkarsa çıksın kabul etmek.

## Seçilmiş teknik çalışmalar

### Zincir analizi (salt okunur JSON-RPC)

Bug bounty kapsamında üç varlığın adı geçiyordu. İkisi, üzerinde sözleşme kodu olmayan harici
sahipli hesaplar (EOA) çıktı: yaklaşık 11,7 milyon ve 5,0 milyon USDC tutan cüzdanlar. Yani gerçek
saldırı yüzeyi, zincirde çalışan tek bir sözleşme ile onun oluşturduğu minimal proxy klonlarıydı.
Yaklaşık 45 milyon bloktaki sözleşme oluşturma olaylarını taradım ve 38.485 klon buldum. Her birinin
aynı implementation sözleşmesine yönelen bir EIP-1167 minimal proxy olduğunu byte düzeyinde
doğruladım.

### Kaynak kodun kökeni

Kod içeren üç sözleşmenin doğrulanmış kaynaklarını aldım, derleyici ayarlarını (solc 0.8.28,
optimizer runs=20000) kaydettim ve zincirdeki runtime bytecode'un yayımlanan kaynakla eşleştiğini
doğruladım: iki sözleşme birebir, üçüncüsü sondaki metadata hash'i dışında. Her runtime kodunun
keccak256 değerini de kaydettim. Sonra, herhangi bir test sonucuna güvenmeden önce, bu değerleri
fork içinde ve sabitlenen blokta bir kez daha kontrol ettim.

### Değişmezler şartnamesi

Varlıkların saklanması, tekrar oynatma/benzersizlik, havuz kimliği, liveness, token davranışı ve
upgrade edilebilirlik için toplam 14 değişmez yazdım. Her biri için biçimsel koşulu, onu uygulayan
kodun `dosya:satır` konumunu, varsayımları ve kırılabileceği en olası tek yolu kaydettim.
Hipotezleri bu şartnameden çıkardım.

### Fork üzerinde çalışan PoC

Arbitrum'u sabit bir blokta fork eden ve zincirdeki gerçek sözleşmelerle çalışan bir Foundry test
düzeneği kurdum. En güçlü hipotezi bir negatif kontrol ve bir maliyet sınırı testiyle birlikte uçtan
uca sınıyor. Üç test de geçti ve birlikte hipotezin ödüle uygun bir açık olmadığını gösterdi:
protokol operatörü durumu aynı işlem içinde geri alabildiği için yetkisiz bir kullanıcının varlıkları
kalıcı olarak etkilenmiyordu. Ayrıntılar `evidence/` klasöründe.

### Önceki incelemelerle mükerrerlik kontrolü

Hedefin herkese açık üçüncü taraf güvenlik incelemesini bulup arşivledim, SHA-256 değerini de
kaydettim. Raporda açıklanan iki High bulguyu şu an çalışan kodla karşılaştırdım: biri tasarım
değişikliğiyle zaten giderilmişti, öteki ayrıcalıklı yetkiye bağlı ve önceden kabul edilmiş bir
konuydu. Ama incelemedeki bulguların önemli bir kısmı kamuya açıklanmamıştı; mükerrer bulgu
riskini sayıya dökemedim. Karar bu riski "bilinmiyor" diye kaydediyor.

## Karar

Sistem, kullanıcı varlıklarının operatörün elinde durduğu ince bir settlement katmanı çıktı.
Kullanıcı teminatını yalnızca ayrıcalıklı operatör rolü hareket ettirebiliyordu; yetkisiz bir
kullanıcının çağırabildiği, durumu değiştiren tam olarak bir giriş noktası vardı. En güçlü hipotezi
fork üzerinde tekrar ürettim. Sonra kendi kanıtı onu çürüttü: gözlenen etki hemen geri
alınabiliyordu ve saldırgana maliyeti, mağdura verdiği zarardan yüksekti. Hipotezi koddan üç kez
yeniden kontrol ettim ve her seferinde aynı sonuca, aynı kod referanslarıyla vardım.

**Sonuç: NO-GO.** Rapor gönderilmedi. Varılan sonuç, emeği ödenebilir bir bulgu çıkma ihtimali daha
yüksek başka bir hedefe vermekti.

## Profesyonel yaklaşım

- Mainnet'ten yalnızca okuma yapıldı ve exploit testlerinin hepsi yerel bir fork üzerinde koştu;
  hiçbir işlem yayınlanmadı, canlı altyapı da yoklanmadı ya da yük altına sokulmadı.
- Hedef program, yayımdan önce onay istiyor. Bildirilebilir bir bulgu çıkmadığı için programa
  gönderilecek bir rapor yok. Yine de incelenen mekanizmayı bu herkese açık vaka çalışmasına
  koymadım.
- Erişilemeyen bir rapor ile pruned archive node sonucu, yerlerine tahmin konmadan `UNKNOWN` olarak
  kaydedildi.

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
