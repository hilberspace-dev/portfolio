[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](DELIVERY-METHODOLOGY.md)

# Teslim ve Quality Gate Metodolojisi

Bu belge, bir değişikliğin talep edildiği andan production'a çıkana kadar izlediği yolu anlatır.
Yöntemin dayandığı fikir basit. Hiçbir adım kimsenin dikkatine bırakılmaz.

Anlatılan yöntem stack'ten bağımsızdır. Onu ortaya çıkaran ürün ise multi-tenant ticari bir
platformdu. Bu platform GPU/ML workload'u koşuyor, veri koruma kısıtları altında işletiliyor ve çok
küçük bir ekiple sürdürülüyordu.

Bu belge, saldırgan bakış açılı incelemeyi ve defect kanıtlamayı anlatan [Güvenlik İncelemesi ve PoC
Metodolojisi'nin](METHODOLOGY.tr.md) tamamlayıcısıdır. Bir işin nasıl yürüdüğünü kısaca görmek
isterseniz [portföy README'sine](README.tr.md) bakın. İşin içinde ne olduğu ise burada ayrıntısıyla
anlatılır.

**Temel ilke: hatırlanmaya bağlı kural, kural değildir.** Öğrenilmesi gerçekten pahalıya mal olmuş
her ders ya bir makinenin denetlediği bir kontrole dönüşür ya da er geç geri gelir.

---

## 0. Değişmez kurallar

1. **İddiadan önce kanıt.** Çalıştırılan komut, çıktısı ve exit code'u ortada olmadan hiçbir iş için
   "düzeldi", "geçiyor" veya "bitti" denmez. Kodu okumak verification yerine geçmez. Yeniden
   çalıştırıp yeşil almak, daha önceki bir failure'ı geçersiz kılmaz. Çalıştırılmayan ne varsa
   açıkça belirtilir.
2. **Instance'ı değil class'ı düzelt.** Bug'ı gideren commit işin yalnızca yarısıdır. Diğer yarısı
   şudur: bu defect'i hangi kontrol yakalamalıydı ama yakalamadı? O kontrol bulunur ve kurulur.
3. **Debt'i dondur, asla genişletme.** Mevcut sorunlar ölçülür ve bugünkü büyüklüğünde sabitlenir;
   yenisi build'i düşürür. Gate'i yeşile çevirmek için hiç kimse bir baseline'ı düzenlemez.
4. **Fail-closed davran ve kör noktanı bildir.** Para, güvenlik veya kişisel veri taşıyan bir
   path'te belirsizlik varsa istek reddedilir. Her ölçüm aracı, neyi göremediğini kendi dosyasında
   yazar.
5. **Root cause'u gideren en küçük değişikliği yap.** Aynı diff'e ilişkisiz temizlik, formatlama,
   spekülatif abstraction veya istenmemiş bir API kırılması eklenmez.

---

## 1. Bir değişikliğin "done" tanımı

Kod yazmadan önce gözlemlenebilir hedef, kabul kriterleri, scope ve ayakta kalması gereken
invariant'lar belirlenir. Ardından mevcut kod, testleri ve **tüm call chain** okunur; yalnızca
değişen fonksiyon değil, onun içinde yer aldığı zincir incelenir. Planın dayandığı her dosya, route,
komut ve ayar gerçekten var mı diye kontrol edilir. Adına bakıp tahmin etmek yetmez.

Bunun ardından tutarlı en küçük değişiklik yazılır, çalışma sırasında hedefli kontroller koşulur ve
değişikliğin gerçekten gerektirdiği regression suite'i çalıştırılır. Hedefli bir test ve bir ekran
görüntüsü regression geçişi sayılmaz. Bunu baştan söylemek, sonradan fark etmekten çok daha ucuzdur.

Kapanışta diff'in tamamı scope, güvenlik ve yan etki açısından okunur; neyin çalıştırıldığı ve ne
döndürdüğü kaydedilir. Bilinçli olarak atlanan iş, gerekçesiyle birlikte atlanmış olarak yazılır.

Davranışı koruyan refactor'lar uygulanmadan önce planlanır. Büyümüş bir modülü bölmek tek bir küçük
değişikliktir ve dört kurala tabidir. Yalnızca bölünen birimin içinde zaten var olan kod taşınır.
Çıkarılan parça ince tutulur, bağımlılıkları dışarıdan verilir. Route adı veya response şekli
taşımayla aynı değişiklikte değiştirilmez. Mevcut testler, import satırları dışında düzenlenmeden
yeşil kalır.

---

## 2. Gate merdiveni

Dört kontrol seti vardır. Her biri ilk hatada duran bir zincirdir; böylece hangi komutun düştüğü hiç
belirsiz kalmaz.

| Katman | Kapsam | Nerede |
| --- | --- | --- |
| Hızlı gate | Secret scan, type build, lint, policy scanner'lar. Suite yok. | Pre-push hook |
| CI | Aynı policy seti, ardından lint, server testleri, frontend testleri, build, E2E ve smoke testleri; tek bir required check'te toplanır | Her pull request |
| Tam yerel koşu | Policy seti artı tüm suite'ler, build ve operasyonel smoke'lar | İhtiyaç hâlinde |
| Release ve drift | Yukarıdakilerin tamamı artı dependency ve lockfile policy'si, audit, governance, deploy readiness, release build'i ve artifact verification | Haftalık ve her release'te |

Bunu kâğıt üstünde kalmaktan çıkaran iki şey var.

**Asıl gate yereldeki hook'tur.** Kendini package lifecycle üzerinden kurar ve checkout dışında
hiçbir şey yapmaz. Böylece yeni bir clone, kimse ayar yapmasa da korumalı gelir. Uzaktaki policy
job'ı aynı scanner setini koşar; dolayısıyla yereli atlamak gecikmeden başka bir şey kazandırmaz.

**Escape hatch asgari korumayı düşüremez.** Belgelenmiş tek bir bypass var. Yalnızca hızlı gate'i
atlar, secret scan'i asla atlamaz ve kendini stderr'e yazar. Zaman kazanmak için bu bypass'a
başvurmak tavsiye edilmemekle kalmaz, kurallara da aykırıdır. Tekil scanner içindeki istisnalar da
aynı mantığa tabidir: satır düzeyindedir, yazılı gerekçelidir ve bir kuralı sessizce susturmak
yerine diff'te görünür.

Her CI step'i çıktısını bir log dosyasına yazar ve child process'in kendi exit code'uyla sonlanır;
böylece hiçbir wrapper bir failure'ı geçen bir step'e çeviremez. Her job sanitize edilmiş bir
diagnostic paketi üretir. Paket yalnızca bir şey düştüğünde upload edilir. Environment dump'ları,
secret dosyaları, runtime database'leri ve upload'lar bilinçli olarak dışarıda bırakılır.

---

## 3. Ratchet: eski debt nasıl tutuluyor

Codebase temizlenene kadar release yapmamak bir plan değildir. Debt'i görmezden gelmek de bir plan
değildir. Ortadaki yol, onu ölçmek, sabitlemek ve büyümesini fail ettirmektir.

**Sayısal ratchet** yalnızca aşağı inebilen tek bir tam sayıdır. Bu sayı şunları sayar: design
token'ları dışında kalan ham renk değerleri, API contract'ındaki gevşek schema girdileri ve
hedeflenenin altında bir tier ile korunan endpoint'ler. Baseline'ı yazan araç daha büyük bir sayıyı
kaydetmeyi reddeder; yukarı giden kazara bir yol yoktur.

**Envanter ratchet'i** bilinen ihlallerin sıralı listesidir. Yeni bir girdi build'i düşürür. *Stale*
bir girdi de düşürür: listedeki bir sorun bu arada çözülmüşse, satırı aynı değişiklikte
silinmelidir. Aksi hâlde ödenmiş debt, gelecekteki debt'e kılıf olarak listede kalır.

Çalışan bir ratchet'i repoyu süsleyen bir ratchet'ten ayıran üç ayrıntı var:

- **Gerekçe, makinenin zorlayabildiği yerde zorunludur.** Yeni baseline'lanan bir istisna
  `UNJUSTIFIED` placeholder'ıyla yazılır ve biri onun yerine gerçek bir gerekçe koyana kadar gate
  düşmeye devam eder.
- **Detector'lar kendilerini test eder.** Her pattern kuralı, eşleşen ve eşleşmeyen birer sample ile
  gelir; bir kural kendi bad sample'ını yakalamayı bırakırsa veya good sample'ı yakalamaya başlarsa
  koşu düşer. Sessizce no-op'a dönüşmüş bir kural, hiç kural olmamasından kötüdür; çünkü coverage
  gibi okunur.
- **Baseline'lar dosyada durur, onları okuyan script'in içinde değil.** Checker'a gömülü bir
  envanter sessizce stale olur. Repoya commit'lenmiş bir dosyada ise her istisna diff'e düşer ve
  birinin onaylaması gerekir.

---

## 4. Çalıştıran değil, yakalayan testler

Coverage hangi satırların koştuğunu ölçer; suite'in düşüp düşmeyeceğini ölçmez. Coverage çöküşe
karşı bir taban olarak kalır; asıl güvence dört başka şeyden gelir.

**Harness sadakati.** Global middleware'e bağlı olan her şey — authentication, tenant resolution,
CSRF, body parsing, rate limiting — gerçek uygulama composition'ı üzerinden test edilir; asla çıplak
bir framework instance'ına mount edilmiş bir handler üzerinden değil. Bu ayrım teorik değil.
Production'a ulaşan iki defect, kolaycı test setup'larında hiç görünmedi. Testler gerçek
composition'ı ayağa kaldırınca ikisi de apaçık hâle geldi. Mevcut kısayollar bir baseline'da
dondurulur; yenileri düşer.

**Önce kırmızı veren, doğru nedenle kırmızı veren regression testleri.** Basit olmayan her test,
defect'in class'ını, belirtisini ve önceki katmanın onu neden kaçırdığını yazan bir açıklamayla
başlar. En güçlü hâli bunu kanıtlar: test, fix öncesi implementasyonu kendi içine alır ve o
implementasyonun sınanan kuralı ihlal ettiğini assert eder. Böylece dosya, eski kodda düşeceğini
iddia etmekle kalmaz, gösterilebilir biçimde düşer.

**Bağımsız oracle'lı property testleri.** Bağımsız olması, referans implementasyonun sınanan kodla
hiçbir aritmetik paylaşmaması demektir; paylaşırsa yakalamak için var olduğu defect'i miras alır.
Para path'lerinde bu, beklenen değeri yapısal olarak farklı bir yoldan hesaplamak anlamına gelir.
Örnek tabanlı testler bilinen zor noktaları pinler; property testi ise o noktaların birer instance'ı
olduğu kuralı ifade eder.

**Karşılığını verdiği yerde mutation testing.** Para işleyen her modül için tek bir dosyayı mutate
eden ve yalnızca o modülün testlerini koşan dar bir config kullanılır. Threshold'lar ölçülmüş
koşulardan gelir; kanıtlanabilir biçimde equivalent olan mutant'lar bir yorumda hesaba katılır.
Böylece break değeri şu anlama gelir: *yeni* hayatta kalan her mutant koşuyu düşürür. Threshold'lar
coverage iyileştikçe yükselir. Bir koşuyu geçirmek için asla düşürülmez.

Bunların altında üç alışkanlık var:

- **Determinizm umut edilmez, kurulur.** Rastgele sleep yok; asenkron assertion'lar bir koşulu
  bekler. Zamana bağlı mantık mock'lanmak yerine saati parametre olarak alır — bu, söz konusu
  mantığı mutate etmeyi de ucuzlatır. Assertion'lar açık UTC timestamp'leriyle yazılır.
- **Hiçbir şey ölçmemiş bir probe, failure'dır.** Bir isolation testi sınır ötesi hiç deneme
  yapmadıysa ya da control probe kendi tarafında hiç başarılı olmadıysa, koşu temiz sonuç bildirmek
  yerine boş ölçüm olarak düşer. Bu, [güvenlik metodolojisindeki](METHODOLOGY.tr.md) negative
  control'ün teslim tarafındaki ikizidir.
- **Flake araştırılır, retry'lanmaz.** Bu kural özellikle accessibility hataları için geçerlidir:
  bunlar gürültü değil, hukuki boyutu olan defect'lerdir. Doğası gereği kırılgan bir suite'te
  flake'in kaynağı ortadan kaldırılır: animasyon kapatılır, font yüklenmesi beklenir. Test bir
  retry'a sarılmaz; retry gerçek bir regression'ı gizler.

Doğruluğun ötesinde, haftalık bir non-functional katman sistemin baskı altında sağlıklı kalıp
kalmadığını ölçer. Bu katmanda bir load smoke'u, uzun bir soak ve bir stress suite'i vardır. Stress
suite'i hataların yokluğunu değil **failure'ın şeklini** assert eder. Çekişmeli bir randevu slot'u
tam olarak bir kazanan üretmelidir. Hostile input, process'i devirmeden reddedilmelidir. Aynı anda
yarışan tenant'lar birbirinin verisini okumamalıdır. Bilinçli backpressure, kalkanın çalıştığının
kanıtı sayılır; başka hiçbir şey sayılmaz. Load threshold'ları kulağa rahat geldiği için değil,
ölçülmüş bir plateau'dan kalibre edilir.

---

## 5. Contract'lar ve sınırlar

API spec'i contract'tır; sonradan yazılan dokümantasyon değil. Cross-cutting davranışı her
operation'da tekrar etmek yerine bir kez söyler ve yeni bir route orada görünmeden push edilemez.

Coverage iki yönden ve iki kez ölçülür. Kaynak üzerinde metin taraması yalnızca bir route metoduna
doğrudan verilen literal path'leri görebilir; bir prefix altına mount edilmiş router'ları, path'i
değişken olarak alan registration'ları veya bir path dizisi üzerinde dönen loop'ları göremez. Bu
yüzden ikinci ölçüm uygulamayı ayağa kaldırır, canlı routing table'ı gezer ve path şekline göre
karşılaştırır; bozuk bir walker'ın sessizce geçmemesi için bulunan route sayısına da bir sanity
assertion'ı koyar. Dürüst olan sayı runtime'ınkidir ve ikisinin ayrışması beklenir. Coverage'ın
göremediğini üç ek kontrol korur. Birincisi çözülemeyen `$ref`'leri arar; bunlar review'da iyi
görünür ama dokümanı her katı consumer için geçersiz kılar. İkincisi eski dialect'ten kalma
keyword'leri arar; güncel bir validator onları reddetmez, yok sayar, yani anlam sessizce kaybolur.
Üçüncüsü security tanımı olmayan operation'ları arar; entegratör ve code generator bunları public
kabul eder.

Modül sınırları iyi niyetle değil kontrollerle korunur. Server kodu browser kodunu import etmez.
Modül graph'ında cycle yoktur; bu, parse edilmiş bir import graph'ı üzerinde, runtime'da yok olan
type-only edge'ler dışarıda bırakılarak tespit edilir. Her iki allowlist de sıfırdadır; bu da onları
ratchet olmaktan çıkarıp invariant'a dönüştürür. Browser'dan API'ye giden tüm trafik,
credential'ları, header'ları, timeout'ları ve circuit breaker'ı sahiplenen tek bir client'tan geçer.
Onu bypass eden her şeyin bir baseline'da yazılı gerekçesi olmak zorundadır.

Type check, düz tek bir pass yerine project graph'ı üzerinde build modunda koşulur; çünkü
project'lerin lib ve target ayarları farklıdır ve hepsini tek pass'e indirmek server kodunu DOM
global'lerine karşı kontrol etmek anlamına gelir.

---

## 6. Veri, migration ve recovery

Migration'lar dosyadır, sırayla apply edilir ve content hash'iyle kaydedilir. Commit'lenmiş bir
migration dosyası asla düzenlenmez; bu bir review geleneği değildir: bir sonraki boot hash'i yeniden
hesaplar, başlamayı reddeder ve bunun yerine ne yapılması gerektiğini söyler.

Yürütme yalnızca leader process'te, process'ler arası lock altında ve dosya başına atomic yapılır.
Lock ilk schema yazımından önce alınır; böylece aynı anda başlayan birkaç process taze bir
database'de aynı tabloları oluşturmak için yarışamaz. Crash sonrası recovery, lock'u yalnızca
kanıtlanabilir biçimde ölmüş bir process'ten geri alır. Liveness belirlenemezse dosya yaşına bakan
staleness kontrolüne düşer. Bu sıralamanın nedeni şu: senkron bir migration event loop'u bloke eder,
uzun süren bir index build'i hayattayken kendi timestamp'ini yenileyemez. Yalnızca yaşa bakan bir
kural ise boot etmekte olan bir peer'in lock'unu elinden alırdı. Bu, mock'larla değil, aynı dosya
üzerinde çekişen gerçek process'lerle doğrulanır.

Down migration yoktur. Rollback, bir snapshot'tan restore etmektir. Müşteri başına tek stack çalışan
bir deployment'ta dürüst cevap budur ve bunu bir karar olarak yazmak, bir incident sırasında
keşfetmekten yeğdir.

Operasyonel prosedürler hatırlanmaz, script'lenir: retention ve pruning içeren zamanlanmış
backup'lar, uyarı ve kritik kademeli boyut monitoring'i, path traversal'a karşı doğrulama yapan bir
restore ve varsayılan olarak dry-run koşan bir cleanup komutu. Recovery hedefleri ve storage
modelinin dayattığı sıra, bir sonraki mimari kararı tetikleyen sayıların yanında, bir runbook'ta
durur.

---

## 7. Güvenlik duruşu

Her savunma primitifi kendi modülünde durur. Modülün başındaki yorum, kapattığı saldırıyı veya
incident'ı adıyla yazar. Böylece her primitif tek başına incelenebilir ve gerekçe, refactor'lar
boyunca kodun yanında kalır.

Para hareket ettiren callback'ler hostile input kabul edilir: önce signature doğrulanır, dönen token
constant-time karşılaştırmayla intent üzerindeki token'a bind edilir, authoritative kayıt
provider'dan çekilir, tahsil edilen tutar beklenenle karşılaştırılır ve ancak ondan sonra state
değişir. Tutarlar floating point'te çarpılmak yerine digit string'inden parse edilir; çünkü floating
point yolu tutarsız yuvarlar ve doğru bir settlement'ı eksik okuyabilir. State geçişleri, guard'ını
SQL predicate'inin içinde tekrarlar, böylece eşzamanlı bir callback read-then-write race'ini
kazanamaz; terminal state'ler terminaldir ve idempotency bir uygulama kontrolü değil database
constraint'idir.

Bir kontrolün birbiriyle uyuşması gereken iki yarısı varsa — örneğin body parsing'den muaf bir path
ile aynı path'in CSRF muafiyeti — structural bir test ikisini birden assert eder ve eksik girdide
olduğu kadar stale girdide de düşer; böylece bir sonraki ekleme tek tarafı bağlanmış hâlde yayına
giremez.

Yetki tier'ları tartışılmaz, ölçülür. "Kaç endpoint olması gerekenden düşük bir tier'la korunuyor"
sorusu iki ayrı günde iki ayrı cevap üretince, çözüm üçüncü bir görüş değil, aynı census'ü her
seferinde aynı şekilde üreten bir script oldu: hem sayı hem liste donduruldu, böylece bir girdiyi
başkasıyla değiştirmek yenisini gizleyemez. Behavioural bir test bunu destekler; çünkü dependency
injection'ın guard'ı gizlediği her yerde metin taraması stale olur.

Secret scan iki derinlikte yapılır: working tree'de ve commit'lenmiş history'de — böylece bir
zamanlar commit'lenip sonra silinmiş bir credential hâlâ push'u engeller. Supply chain, kod olarak
policy'dir: sabitlenmiş lockfile formatı, yalnızca registry üzerinden resolution, install script'i
çalıştırmasına izin verilen paketler için bir allowlist, tam commit hash'ine pin'lenmiş üçüncü taraf
CI action'ları, her workflow'da explicit permission tanımı ve untrusted input'un shell komutlarına
interpolate edilmemesi.

Bulgular kabul edilmez veya düşürülmez, triage edilir. Review turları önceki bulguları yeniden
derecelendirir, her birinin primary citation'ını koda karşı kontrol eder ve çürütülen bulguları
silmek yerine karşı kanıtıyla birlikte düzeltme olarak yazar. Review bütçesi biten bir alan
"yapılmadı" diye kaydedilir, asla "temiz" diye anlatılmaz.

---

## 8. Release ve deployment

Release artifact'ı, ignore listesiyle değil explicit bir allowlist ile derlenir, bir staging
dizinine alınır ve aynı exclusion'ları yeniden uygulamak için ikinci kez gezilir. Çıktıya bir
checksum ve içine neyin girdiğini, hangi kuralların uygulandığını kaydeden bir manifest eşlik eder.

Verification, working tree'yi değil **extract edilmiş kopyayı** yeniden build edip yeniden test
eder. Verifier önce hash'i kontrol eder. Arşivi, absolute path'leri ve path traversal'ı reddeden bir
reader ile açar. Ardından working directory extract edilmiş kopyanın içindeyken install, policy
scanner'ları, lint, build ve test suite'lerini koşar. Engellenmiş bir subprocess, environment
blocker olarak raporlanır ve CI'da fatal'dır; böylece kontrol sessizce bir dosya listelemesine
indirgenemez.

Deployment, hâlihazırda publish edilmiş bir artifact'ı promote eder; asla yenisini build etmez.
Remote script checksum'ı doğrular, release'e özel bir dizine extract eder, var olanın üzerine
yazmayı reddeder, önce veriyi snapshot'lar, host üzerinde install eder, çıkan release'i kaydeder,
canlı symlink'i çevirir, servisi restart eder, health endpoint'lerini poll eder ve failure hâlinde
otomatik rollback yapar. Readiness endpoint'i gerçek bir dependency probe'udur — gerçek bir query ve
gerçek filesystem kontrolleri — çünkü koşulsuz "healthy" döndüren bir endpoint, bozuk bir instance'ı
rotasyonda tutar.

Release dokümantasyonu, yeşil bir test koşusunun production sign-off ile aynı şey olmadığını açıkça
söyler ve sign-off için gerekenleri sayar: gerçek bir provider'a karşı canlı bir ödeme ve iade,
yeniden üretilmiş secret'lar ve yalnızca yapılandırılmış değil **restore edildiği kanıtlanmış** host
dışı bir backup.

---

## 9. Dark launch ve ön koşul olarak compliance

Önemli feature'lar kapalı yayınlanır. Operatörler için tek bir küratörlü catalog bu flag'leri
listeler. Catalog her flag'i, o flag'i tüketen kodun kendi semantiğiyle anlatmak zorundadır; aynı
kontrolün daha gevşek bir kopyasını yeniden yazamaz. Her girdi ilgili kodu işaret eder.

Status vocabulary'sinin üç değeri bilinçlidir. *On*, bir precondition sonradan bozulmuş olsa bile
gerçekte neyin çalıştığını doğru söyler. *Off*, dark ve hazır demektir. *Blocked*, dark demektir ve
karşılanmamış bir precondition olduğunu gösterir.

İşin ilginç yanı, neyin precondition sayıldığıdır. Bir kısmı makinece kontrol edilebilir: bir key
mevcut mu, bir provider yapılandırılmış mı. Bir kısmı ise insana bağlı; örneğin bir aydınlatma
metninin onaylanıp yayımlanmış olması ya da bir deneyin pre-registration'ının tamamlanmış olması.
Bunlar, kontrolün makine tarafından okunabilir kalması için aynı flag mekanizmasıyla beyan edilir.
Sonuç şudur: hukuki veya yöntemsel bir yükümlülük, yanındaki bir checklist'te değil, **activation
path'inin üzerinde** durur. Bir kontrol ile iyi bir niyet arasındaki fark budur.

Rollout yüzdeleri, flag ve entity üzerinden stable bir hash ile bucket'lanır; böylece kısmi bir
rollout her evaluation'da aynı entity'leri içerir, request başına yeniden karılmaz. Her evaluation,
kararı veren kuralı adlandıran machine-readable bir reason döndürür.

Dışa giden entegrasyonlar dayanıklı bir outbox ve bir worker üzerinden yürür; böylece kullanıcıya
bakan bir request hiçbir zaman üçüncü tarafı beklemez. Idempotency, logical event üzerinde bir
unique index'tir. Retry'lar cap'li exponential backoff ile yapılır ve tükenmiş job'lar kaybolmak
yerine operatöre görünür explicit bir "dead" state'ine geçer. Düzenleyici yükümlülük taşıyan
entegrasyonlar fail-closed davranır ve primary source'unu modül başlığında belirtir: onay izin
verir, ret **veya hiçbir kaydın bulunmaması** engeller; çünkü kayıt yoksa eylem hukuka uygun
değildir. Cache'leri kesin cevap için uzun, hata için kısa bir TTL kullanır; böylece bir kesinti
permissive tarafa değil, blocked-ama-hızlı-toparlanır tarafına degrade olur.

---

## 10. Kanıt olarak dokümantasyon

Üzerine iş kurulacak bir belge, her iddiayı işaretler. İddia ya doğrulanmıştır ve onu üreten komut
yanında yazılıdır, ya da açık olduğu belirtilir. Üçüncü bir durum yoktur; işaretsiz kalan iddia
doğrulanmamış sayılır.

Ölçüm içeren her belge, ölçümün alındığı commit'i ve tarihi kaydeder ve sayıların bayatladığını
söyler. Stale sayı taşıyan bir belge, okuyucuyu içindeki diğer her şeyi kontrol etmeye davet eder;
bu ise belgenin yazılma amacının tam tersidir.

Karar kayıtlarının (ADR) sabit bir şekli vardır. Başlıkta tarih, durum ve kararı tetikleyen bulguya
bağlantı bulunur. Context bir gözlem-kanıt tablosudur; her gözlem somut bir dosyayı veya ayarı
işaret eder. Karar tek cümledir. İş de ikiye ayrılır: "şimdi yapılacak" maddeleri ve "adlandırılmış
sayısal trigger geldiğinde yapılacak" maddeleri. Her "şimdi" maddesi onu tutacak kontrole bağlanır.
Kapanış, koddan türetilemeyen tek girdiyi adlandırıp onun için karar istemektir.

Audit bulguları sabit ID'ler alır ve bu ID'ler sistem içinde izlenebilir kalır. Aynı ID karar
kaydında, fix'i zorlayan kontrolde ve takip işinde görünür. Bir audit ayrıca hangi kontrollerin
gerçekten koşulduğunu kaydeder ve neyi kapsamadığını açıkça söyler.

Nedensellik iddiası taşıyan her şey, veri var olmadan önce pre-register edilir. Pre-registration
şunları içerir: primary metric ve hipotez, exclusion'lar, stopping rule ve hangi secondary
metric'lerin manşet iddiada kullanılamayacağı. Tasarım ayrıca bir tablo taşır; tablo pre-register
edilen her kuralı onu zorlayan teste bağlar. Simülasyon işleri iki arm koşar. Null arm'ın gate'i
"asla kullanılabilir bir sonuç üretmemek"tir. Known-truth arm'ı ise analitik olarak türetilmiş bir
tolerance'a karşı kontrol edilir; bu tolerance koşu geçene kadar ayarlanmaz.

---

## 11. Çalışma disiplini

**Push ve merge ayrı yetkilerdir.** Yeşil bir gate push'a yetki verir, merge'e değil. Değişiklikler
pull request olarak gelir ve authentication, authorization, tenant isolation, ödeme mantığı,
signature doğrulama veya migration'lara dokunan diff'ler, onları yazmakta rol almamış biri
tarafından review edilir.

**Kimse yazmadığı işi yeniden yazmaz.** Başkasına ait commit'lenmemiş iş olduğu gibi bırakılır;
yerini almış bir branch, toparlanmak yerine sahibinin kararını bekler.

**Failure'ın tanımlı bir durma noktası vardır.** Aynı alanda arka arkaya iki başarısız düzeltmeden
sonra düzenlemeyi bırak: hatayı yeniden üret, varsayımları ve tüm call chain'i gözden geçir, doğru
nedenle düşen bir test yaz ve ancak ondan sonra root cause'u gider. O fix de tutmazsa üçüncü bir
patch'e kalkışma — düşen testi ve working tree'yi olduğu gibi bırak, iki denemeyi, hipotezi ve neden
tutmadığını yaz ve bunu bir karar olarak yukarı taşı. Yeşile doğru zorlamak, sonunda hangi fix'in
gerçek olduğunu kimsenin bilmediği bir codebase üretir.

**Geliştirme yalnızca local ortamlara ve CI'ya karşı yapılır.** Production database'lerine,
host'larına veya secret'larına bağlanılmaz ve aciliyeti ne olursa olsun production'a karşı ad-hoc
query çalıştırılmaz. Gerçek müşteri verisi debug'da asla kullanılmaz; production'dan bildirilen bir
defect, rapora benzer şekilde üretilmiş sentetik veriyle yeniden üretilir. Gerçekten production
erişimi gerektiren adımlar hazırlanır ve devredilir, çalıştırılmaz.

**Geliştirme ortamına katlanılmaz; o da mühendislik işidir.** Build ve start öncesinde koşan bir
preflight script'i gerekli dosya ve dizinleri denetler. Native dependency'lerin yüklendiğine
güvenmek yerine onları gerçekten çalıştırır. Bilinen platform arızaları, ağızdan ağıza aktarılan
bilgi yerine repoya commit'lenmiş script'lerle karşılanır. Ağır job'lar üst üste binmez ve biri
başlamadan önce mevcut headroom kontrol edilir.

---

## 12. Bu yöntemin vermediği şeyler

**Ratchet regression'ı durdurur, debt'i ödemez.** Hiçbir gate sana debt'in fazla olduğunu söylemez;
yalnızca büyüdüğünü söyler. Azaltma bilinçli olarak planlanmalıdır ve planlanmadıysa olmaz.

**Bir gate bir özelliği kanıtlar, sorunların yokluğunu değil.** Buradaki her kontrolün tanımlı bir
scope'u vardır ve birçoğu kendi kör noktasını kendi dosyasında yazar. Yeşil bir koşu, ölçülen
şeylerin kötüleşmediği anlamına gelir.

**Beyan edilen governance, uygulanan governance değildir.** Required check'leri ve review'ları
tanımlayan bir manifest kendi içinde tutarlı olabilir ve bu tutarlılık doğrulanabilir. Yine de
hiçbiri hosting platformunda enforce edilmiyor olabilir. İkisini ayrı tutmak gerekir.

**Süreç, ikinci bir çift gözün yerine geçmez.** Hassas bir değişikliğin bağımsız review'ı, bir şey
onu fiilen zorlamadığı sürece bir mekanizma değil bir taahhüttür. Küçük bir ekipte bu boşluk
gerçektir ve üstünü örtmek yerine adını koymak gerekir.

**Bazı tercihler yalnızca bu ölçekte doğrudur.** Bir metrics stack'i işletmek yerine operasyonel
görünürlüğü query zamanında hesaplamak, müşteri başına tek instance için makul, elli instance için
kötü bir trade-off'tur. Buradaki her mimari seçimin doğru olmaktan çıktığı bir büyüklük vardır; işe
yarayan kısım, oraya vardığını sana hangi sayısal trigger'ın söyleyeceğini bilmektir.
