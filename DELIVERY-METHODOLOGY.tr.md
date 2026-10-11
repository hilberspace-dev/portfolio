[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](DELIVERY-METHODOLOGY.md)

# Teslim ve quality gate metodolojisi

Bu belge, bir değişikliğin talep edildiği andan production'a çıkana kadar izlediği yolu anlatır.
Yöntemin dayandığı fikir basit: hiçbir adım kimsenin dikkatine bırakılmaz.

Yöntem belirli bir stack'e bağlı değil. Çıktığı yer, GPU/ML workload'u olan ve veri koruma kısıtları
altında geliştirilen multi-tenant bir platform.

Saldırgan gözüyle incelemeyi, defect kanıtlamayı ve raporu değerlendirmeye hazır paketlemeyi anlatan
[güvenlik incelemesi ve PoC metodolojisi](METHODOLOGY.tr.md) bu belgenin tamamlayıcısıdır. Bir işin
nasıl yürüdüğünün kısa hâli [portföy README'sinde](README.tr.md), içeride neler olduğunun uzun hâli
bu belgede.

Hepsinin altındaki ilke şu: birinin hatırlamasına bağlı bir kural er geç unutulur. Bu yüzden
öğrenilmesi gerçekten pahalıya mal olmuş her ders, bir makinenin denetlediği bir kontrole dönüşür;
dönüşmezse aynı hata geri gelir.

## 0. Temel kurallar

1. İddiadan önce kanıt gelir. Çalıştırılan komut, çıktısı ve exit code'u ortada olmadan hiçbir iş
   için "düzeldi", "geçiyor" veya "bitti" denmez. Kodu okumak verification yerine geçmez; yeniden
   çalıştırıp yeşil almak da daha önceki bir failure'ı geçersiz kılmaz. Çalıştırılmayan ne varsa
   açıkça söylenir.
2. Hatanın kendisiyle birlikte ait olduğu hata sınıfını da düzelt. Hatayı gideren commit işin
   yarısıdır. Öbür yarısı, bu hatayı yakalaması gerekirken yakalamayan kontrolü bulup o kontrolü
   kurmaktır.
3. Debt dondurulur, büyümesine izin verilmez. Mevcut sorunlar ölçülür ve bugünkü büyüklüğünde
   sabitlenir; yenisi build'i düşürür. Gate'i yeşile çevirmek için kimse baseline'ı düzenlemez.
4. Fail-closed davran ve kör noktanı söyle. Para, güvenlik veya kişisel veri taşıyan bir path'te
   belirsizlik varsa istek reddedilir. Her ölçüm aracı, neyi göremediğini kendi dosyasında yazar.
5. Root cause'u gideren en küçük değişikliği yap. İlişkisiz temizlik, formatlama, spekülatif
   abstraction ve istenmemiş API kırılmaları aynı diff'e girmez.

## 1. Bir değişikliğin "done" tanımı

Kod yazmadan önce gözlemlenebilir hedef, kabul kriterleri, scope ve ayakta kalması gereken
invariant'lar belirlenir. Ardından mevcut kod, testleri ve tüm call chain okunur: değişen fonksiyonun
içinde durduğu zincirin tamamı. Planın dayandığı her dosya, route, komut ve ayarın var olduğu işe
başlamadan kontrol edilir.

Bunun ardından tutarlı en küçük değişiklik yazılır, çalışma sırasında hedefli kontroller koşulur ve
değişikliğin gerçekten gerektirdiği regression suite'i çalıştırılır. Hedefli bir test ve bir ekran
görüntüsü regression geçişi sayılmaz.

Kapanışta diff'in tamamı scope, güvenlik ve yan etki açısından okunur; neyin çalıştırıldığı ve ne
döndürdüğü kaydedilir. Atlanan iş, gerekçesiyle birlikte atlandı diye yazılır.

Davranışı koruyan refactor'lar uygulanmadan önce planlanır. Büyümüş bir modülün her bölünmesi ayrı,
küçük bir değişiklik olarak yazılır ve dört kurala bağlanır. Yalnızca bölünen birimin içinde zaten var
olan kod taşınır. Çıkarılan parça ince tutulur, bağımlılıkları dışarıdan verilir. Route adı veya
response şekli taşımayla aynı değişiklikte değiştirilmez. Mevcut testler, import satırları dışında
düzenlenmeden yeşil kalır.

## 2. Gate merdiveni

Dört kontrol seti vardır. Her biri ilk hatada duran bir zincirdir; böylece hangi komutun düştüğü hep
bellidir.

| Katman | Kapsam | Tetikleyici |
| --- | --- | --- |
| Hızlı gate | Secret scan, type build, lint, policy scanner'lar. Suite yok. | Pre-push hook |
| CI | Aynı policy seti, ardından lint, server testleri, frontend testleri, build, E2E ve smoke testleri; tek bir required check'te toplanır | Her pull request'te çalışacak şekilde ayarlı |
| Tam yerel koşu | Policy seti artı tüm suite'ler, build ve operasyonel smoke'lar | İhtiyaç hâlinde |
| Release ve drift | Yukarıdakilerin tamamı artı dependency ve lockfile policy'si, audit, governance, deploy readiness, release build'i ve artifact verification | Her release; ayrıca haftalık bir zamanlama ayarlı |

İşi gören gate yereldeki hook'tur. Kendini package lifecycle üzerinden kurar ve checkout dışında
hiçbir şey yapmaz; yeni bir clone, kimse ayar yapmadan korumalı gelir. Uzaktaki policy job'ı aynı
scanner setini koşar, yani yereli atlamak hatayı yalnızca geciktirir.

Escape hatch asgari korumayı kapatamaz. Belgelenmiş tek bir bypass var. Yalnızca hızlı gate'i atlar,
secret scan'i hiçbir zaman atlamaz ve kullanıldığını açıkça belli eder. Zaman kazanmak için ona
başvurmak açıkça kurallara aykırıdır. Tekil scanner'lardaki istisnalar da aynı mantıkla çalışır: her
biri satır düzeyindedir, yazılı bir gerekçe taşır ve review için diff'te görünür. Hiçbiri bir kuralı
sessizce susturmaz.

Her CI step'i çıktısını bir log dosyasına yazar ve child process'in kendi exit code'uyla sonlanır;
böylece hiçbir wrapper bir failure'ı geçen bir step'e çeviremez. Her job sanitize edilmiş bir
diagnostic paketi üretir ve onu yalnızca bir şey düştüğünde upload eder. Environment dump'ları, secret
dosyaları, runtime database'leri ve upload'lar paketin dışında bırakılır.

## 3. Ratchet: eski debt nasıl tutuluyor

Var olan debt ölçülür ve sabitlenir; büyüdüğü anda build düşer. Release'ler sürer, bu sırada debt
büyüyemez.

*Sayısal ratchet* yalnızca aşağı inebilen tek bir tam sayıdır. Örnekler: design token'ları dışında
kalan ham renk değerleri, API contract'ındaki gevşek schema girdileri ve hedeflenenin altında bir tier
ile korunan endpoint'ler. Baseline'ı yazan araç daha büyük bir sayıyı kaydetmeyi reddeder, yani sayı
kazara yukarı kayamaz.

*Envanter ratchet'i* bilinen ihlallerin sıralı listesidir. Yeni bir girdi build'i düşürür. *Stale* bir
girdi de düşürür: listedeki bir sorun çözülmüşse satırı aynı değişiklikte silinmelidir. Yoksa ödenmiş
debt, gelecekteki debt'e kılıf olarak listede kalır.

Makinenin gerekçe isteyebildiği her yerde gerekçe zorunludur. Yeni baseline'lanan bir istisna
`UNJUSTIFIED` placeholder'ıyla yazılır ve yerine gerçek bir gerekçe konana kadar gate düşmeye devam
eder.

Detector'lar kendilerini test eder. Her pattern kuralı eşleşen ve eşleşmeyen birer sample ile gelir;
bir kural kendi bad sample'ını yakalamayı bırakırsa veya good sample'ı yakalamaya başlarsa koşu düşer.
Zamanla no-op'a dönüşmüş bir kural, hiç kural olmamasından kötüdür, çünkü hâlâ coverage gibi görünür.

Baseline'lar, onları okuyan script'ten ayrı, kendi dosyalarında durur. Checker'a gömülü bir envanter
kimse fark etmeden stale olur. Repoya commit'lenmiş bir dosyada ise her istisna diff'e düşer ve
onaylanması gerekir.

## 4. Testler ne yakaladıklarıyla ölçülür

Coverage hangi satırların koştuğunu ölçer; suite'in düşüp düşmeyeceği hakkında bir şey söylemez.
Çöküşe karşı bir taban olarak kalır, asıl güvence aşağıdaki yöntemlerden gelir.

### Harness sadakati

Global middleware'e bağlı olan her şey (authentication, tenant resolution, CSRF, body parsing, rate
limiting) gerçek uygulama composition'ı üzerinden test edilir. Çıplak bir framework instance'ına mount
edilmiş bir handler bunun yerine geçmez. Mevcut kısayollar bir baseline'da dondurulur, yenileri
düşer.

### Önce kırmızı veren, doğru nedenle kırmızı veren regression testleri

Basit olmayan her test, defect'in class'ını, belirtisini ve önceki katmanın onu neden kaçırdığını
yazan bir açıklamayla başlar. En güçlü hâli bunu kanıtlar: test, fix öncesi implementasyonu kendi
içine alır ve o implementasyonun sınanan kuralı ihlal ettiğini assert eder. Böylece dosya koşunca eski
kodun düştüğü görülür.

### Bağımsız oracle'lı property testleri

Bağımsız olması, referans implementasyonun sınanan kodla hiçbir aritmetik paylaşmaması demektir;
paylaşırsa yakalamak için var olduğu defect'i miras alır. Para path'lerinde bu, beklenen değeri
yapısal olarak farklı bir yoldan hesaplamak anlamına gelir. Örnek tabanlı testler bilinen zor
noktaları pinler; property testi ise o noktaların birer instance'ı olduğu kuralı ifade eder.

### Karşılığını verdiği yerde mutation testing

Para işleyen her modül için tek bir dosyayı mutate eden ve yalnızca o modülün testlerini koşan dar bir
config kullanılır. Threshold'lar ölçülmüş koşulardan gelir; kanıtlanabilir biçimde equivalent olan
mutant'lar bir yorumda hesaba katılır. Böylece break değeri şu anlama gelir: *yeni* hayatta kalan her
mutant koşuyu düşürür. Threshold'lar coverage iyileştikçe yükselir ve bir koşuyu geçirmek için asla
düşürülmez.

### Test hijyeni

- Determinizm baştan kurulur. Rastgele sleep yoktur; asenkron assertion'lar bir koşulu bekler. Zamana
  bağlı mantık saati parametre olarak alır; böylece mock gerekmez ve o mantığı mutate etmek de
  ucuzlar. Assertion'lar açık UTC timestamp'leriyle yazılır.
- Hiçbir şey ölçmemiş bir probe failure sayılır. Bir isolation testi sınır ötesine hiç deneme
  yapmadıysa ya da control probe kendi tarafında hiç başarılı olmadıysa, koşu boş ölçüm olarak düşer
  ve temiz sonuç bildirmez. Bu, [güvenlik metodolojisindeki](METHODOLOGY.tr.md) negative control'ün
  teslim tarafındaki ikizidir.
- Flaky testler araştırılır, retry'lanmaz. Accessibility hataları için bu iki kat geçerlidir; bunlar
  hukuki boyutu olan gerçek defect'lerdir. Doğası gereği kırılgan bir suite'te flakiness'in kaynağı
  ortadan kaldırılır (animasyon kapatılır, font yüklenmesi beklenir). Testi bir retry'a sarmak gerçek
  bir regression'ı gizlerdi.

### Baskı altında

CI ayarlarında haftalık zamanlanmış bir non-functional katman, sistemin baskı altında sağlıklı kalıp
kalmadığını ölçer. Bu katmanda bir load smoke'u, uzun bir soak ve bir stress suite'i vardır. Stress
suite'i bir miktar hataya izin verir ve failure'ın *şeklini* assert eder. Çekişmeli bir randevu
slot'u tam olarak bir kazanan üretmelidir. Hostile input, process'i devirmeden reddedilmelidir. Aynı
anda yarışan tenant'lar birbirinin verisini okumamalıdır. Backpressure kalkanın çalıştığını gösterir;
başka türden bir failure bu sayılmaz. Load threshold'ları ölçülmüş bir plateau'dan kalibre edilir,
kulağa rahat geldiği için seçilmez.

## 5. API contract'ı ve modül sınırları

API spec'i contract'ın kendisidir. Cross-cutting davranışı bir kez, tek bir yerde söyler; yeni bir
route da orada görünmeden push edilemez.

Coverage iki yönden ve iki kez ölçülür. Kaynak üzerinde metin taraması yalnızca bir route metoduna
doğrudan verilen literal path'leri görebilir; bir prefix altına mount edilmiş router'ları, path'i
değişken olarak alan registration'ları veya bir path dizisi üzerinde dönen loop'ları göremez. Bu
yüzden ikinci ölçüm uygulamayı ayağa kaldırır, canlı routing table'ı gezer ve path şekline göre
karşılaştırır. Bulunan route sayısına konan bir sanity assertion'ı, bozuk bir walker'ın sessizce
geçmesini engeller. İki sayının farklı çıkması beklenir; doğru olan runtime sayısıdır.

Coverage'ın göremediğini başka kontroller yakalar. Biri çözülemeyen `$ref`'leri arar; bunlar
review'da iyi görünür ama dokümanı her katı consumer için geçersiz kılar. Bir diğeri eski dialect'ten
kalma keyword'leri arar; güncel bir validator onları hata vermeden yok sayar, yani anlam sessizce
kaybolur. Bir başkası security tanımı olmayan operation'ları arar; her entegratör ve code generator
bunları public kabul eder.

Modül sınırlarını kontroller korur. Server kodu browser kodunu import etmez. Modül graph'ında cycle
yoktur; bu, parse edilmiş bir import graph'ı üzerinde, runtime'da yok olan type-only edge'ler dışarıda
bırakılarak tespit edilir. Her iki allowlist de sıfırdadır; bu yüzden ratchet olmaktan çıkıp invariant
olarak çalışırlar. Browser'dan API'ye giden tüm trafik, credential'ları, header'ları, timeout'ları ve
circuit breaker'ı sahiplenen tek bir client'tan geçer. Onu bypass eden her şeyin bir baseline'da
yazılı gerekçesi olmak zorundadır.

Type check, project graph'ı üzerinde build modunda koşar. Project'lerin lib ve target ayarları
farklıdır; hepsini tek bir düz pass'e indirmek, server kodunu DOM global'lerine karşı kontrol etmek
olurdu.

## 6. Migration ve recovery

Migration'lar dosyadır, sırayla apply edilir ve content hash'iyle kaydedilir. Commit'lenmiş bir
migration dosyası asla düzenlenmez ve bunu review'un yakalaması gerekmez: bir sonraki boot hash'i
yeniden hesaplar, başlamayı reddeder ve bunun yerine ne yapılması gerektiğini söyler.

Migration'ları yalnızca leader process çalıştırır; process'ler arası bir lock altında ve dosya başına
atomic olarak. Lock ilk schema yazımından önce alınır; böylece aynı anda başlayan birkaç process taze
bir database'de aynı tabloları oluşturmak için yarışamaz. Crash sonrası recovery, lock'u yalnızca
kanıtlanabilir biçimde ölmüş bir process'ten geri alır. Lock'u tutan process'in yaşayıp yaşamadığı
belirlenemezse dosya yaşına bakan bir staleness kontrolüne düşer. Bu sıralamanın nedeni şu:
senkron bir migration event loop'u bloke eder, bu yüzden uzun süren bir index build'i gayet hayattayken
kendi timestamp'ini yenileyemez. Yalnızca yaşa bakan bir kural ise boot etmekte olan bir peer'in lock'u
onun elinden almasına izin verirdi. Bunun testleri, aynı dosya için çekişen gerçek process'ler başlatır;
mock kullanılmaz.

Down migration yoktur. Rollback, bir snapshot'tan restore etmektir. Bu, müşteri başına tek stack
çalışan bir deployment'a uyar ve bir karar olarak yazılıdır; kimse bunu ilk kez bir incident
sırasında öğrenmez.

Operasyonel prosedürler script'tir, kimsenin hatırlaması gerekmez: retention ve pruning içeren
zamanlanmış backup'lar, uyarı ve kritik kademeli boyut monitoring'i, path traversal'a karşı doğrulama
yapan bir restore komutu ve varsayılan olarak dry-run koşan bir cleanup komutu. Recovery hedefleri ve
storage modelinin dayattığı sıra bir runbook'ta, bir sonraki mimari kararı tetikleyen sayıların
yanında durur.

## 7. Güvenlik duruşu

Her savunma primitifi kendi modülünde durur. Modülün başındaki yorum, kapattığı saldırıyı veya
incident'ı adıyla yazar. Böylece her primitif tek başına incelenebilir ve gerekçe, refactor'lar boyunca
kodun yanında kalır.

Para hareket ettiren callback'ler hostile input kabul edilir. Önce signature doğrulanır. Sonra dönen
token, constant-time karşılaştırmayla intent üzerindeki token'a bind edilir, authoritative kayıt
provider'dan çekilir ve tahsil edilen tutar beklenenle karşılaştırılır. State ancak bundan sonra
değişir. Tutarlar digit string'inden parse edilir, çünkü floating point'te çarpmak tutarsız yuvarlar
ve doğru bir settlement'ı eksik okuyabilir. State geçişleri, guard'larını SQL predicate'inin içinde
tekrarlar; böylece eşzamanlı bir callback read-then-write race'ini kazanamaz. Terminal state'ler
terminaldir ve idempotency bir database constraint'idir.

Bazı kontrollerin birbiriyle uyuşması gereken iki yarısı vardır; örneğin body parsing'den muaf bir path
ile aynı path'in CSRF muafiyeti. Structural bir test iki yarıyı birden assert eder ve eksik girdide
olduğu kadar stale girdide de düşer. Böylece bir sonraki ekleme tek tarafı bağlanmış hâlde yayına
giremez.

Yetki tier'ları ölçümle belirlenir. "Kaç endpoint olması gerekenden düşük bir tier'la korunuyor"
sorusu iki ayrı günde iki ayrı cevap üretince, buna aynı census'ü her seferinde aynı şekilde üreten bir
script'le cevap verildi. Script hem sayıyı hem listeyi dondurur; böylece bir girdiyi başkasıyla
değiştirmek yeni bir girdiyi gizleyemez. Behavioural bir test bunu destekler, çünkü dependency
injection'ın guard'ı gizlediği her yerde metin taraması stale olur.

Secret scan iki derinlikte yapılır: working tree'de ve commit'lenmiş history'de. Böylece bir zamanlar
commit'lenip sonra silinmiş bir credential da push'u engeller. Supply chain policy'si kod olarak
yazılıdır: sabitlenmiş lockfile formatı, yalnızca registry üzerinden resolution, install script'i
çalıştırmasına izin verilen paketler için bir allowlist, tam commit hash'ine pin'lenmiş üçüncü taraf CI
action'ları, her workflow'da explicit permission tanımı ve untrusted input'un shell komutlarına
interpolate edilmemesi.

Her bulgu triage edilir; hiçbiri doğrudan kabul edilmez ya da atılmaz. Sonraki bir review, önceki her
bulguyu koda karşı yeniden kontrol eder. Çürütülen bir bulgu silinmez, karşı kanıtıyla birlikte
düzeltme olarak kayda geçer. Ayrılan sürede incelenemeyen bir alan "incelenmedi" diye kaydedilir,
hiçbir zaman "temiz" diye anlatılmaz.

## 8. Release ve deployment

Release artifact'ı explicit bir allowlist ile derlenir (ignore listesi kullanılmaz), bir staging
dizinine alınır ve aynı exclusion'ları yeniden doğrulamak için ikinci kez gezilir. Çıktıya bir checksum
ve içine neyin girdiğini, hangi kuralların uygulandığını kaydeden bir manifest eşlik eder.

Doğrulama, arşivden *açılan kopyayı* yeniden build eder ve test eder; working tree bu işe karışmaz.
Verifier önce hash'i kontrol eder. Arşivi, absolute path'leri ve path traversal'ı reddeden bir reader
ile açar. Ardından working directory açılan kopyanın içindeyken install,
policy scanner'ları, lint, build ve test suite'lerini koşar. Engellenmiş bir subprocess environment
blocker olarak raporlanır ve CI'da fatal'dır; böylece kontrol sessizce bir dosya listelemesine
indirgenemez.

Deployment, hâlihazırda publish edilmiş bir artifact'ı promote eder; hiçbir zaman yenisini build etmez.
Remote script checksum'ı doğrular, release'e özel bir dizine extract eder (var olanın üzerine yazmayı
reddeder), önce veriyi snapshot'lar, host üzerinde install eder, çıkan release'i kaydeder, canlı
pointer'ı çevirir, servisi restart eder, health endpoint'lerini poll eder ve failure hâlinde otomatik
rollback yapar. Readiness endpoint'i gerçek bir dependency probe'udur: gerçek bir query ve gerçek
filesystem kontrolleri çalıştırır. Koşulsuz "healthy" döndüren bir endpoint, bozuk bir instance'ı
rotasyonda tutar.

Release dokümantasyonu, yeşil bir test koşusunun production sign-off olmadığını açıkça söyler ve
sign-off için gerekenleri sayar: gerçek bir provider'a karşı canlı bir ödeme ve iade, yeniden
üretilmiş secret'lar ve restore edildiği *kanıtlanmış* host dışı bir backup. Restore'un yalnızca
yapılandırılmış olması yetmez.

## 9. Dark launch ve ön koşul olarak compliance

Önemli feature'lar kapalı yayınlanır. Operatörler için bu flag'leri listeleyen tek yer, küratörlü bir
catalog'dur. Catalog her flag'i, o flag'i tüketen kodun kendi semantiğiyle anlatmak zorundadır ve her
girdi ilgili kodu işaret eder; aynı kontrolün daha gevşek bir kopyasını yazmak kabul edilmez.

Status vocabulary'sinin üç değeri var. *On*, bir precondition sonradan bozulmuş olsa bile gerçekte
neyin çalıştığını doğru söyler. *Off*, dark ve hazır demektir. *Blocked*, dark demektir ve
karşılanmamış bir precondition olduğunu gösterir.

Bazı precondition'ları makine kontrol edebilir: bir key mevcut mu, bir provider yapılandırılmış mı.
Bazıları ise insana bağlıdır; örneğin bir aydınlatma metninin onaylanıp yayımlanmış olması ya da bir
deneyin pre-registration'ının tamamlanmış olması. Bunlar da, kontrol makine tarafından okunabilir
kalsın diye aynı flag mekanizmasıyla beyan edilir. Böylece hukuki veya yöntemsel bir yükümlülük
*activation path'inin üzerinde* durur ve karşılanana kadar feature blocked kalır.

Rollout yüzdeleri, flag ve entity üzerinden stable bir hash ile bucket'lanır; böylece kısmi bir rollout
her evaluation'da aynı entity'leri içerir ve request başına yeniden karılmaz. Her evaluation, kararı
veren kuralı adlandıran machine-readable bir reason döndürür.

Dışa giden entegrasyonlar dayanıklı bir outbox ve bir worker üzerinden yürür; böylece kullanıcıya
bakan bir request hiçbir zaman üçüncü tarafı beklemez. Idempotency, logical event üzerinde bir unique
index'tir. Retry'lar üst sınırı olan bir backoff ile yapılır. Retry hakkı tükenen bir job kaybolmaz,
operatörün görebildiği explicit bir "dead" state'ine geçer. Düzenleyici yükümlülük taşıyan
entegrasyonlar fail-closed davranır ve primary source'larını modül başlığında belirtir. Onay izin
verir; ret *veya hiçbir kaydın bulunmaması* engeller, çünkü kayıt yoksa eylem hukuka uygun değildir.
Cache'leri kesin cevabı uzun, hatayı kısa bir TTL ile tutar. Böylece bir kesinti sırasında entegrasyon
permissive hâle gelmez; blocked kalır ve çabuk toparlanır.

## 10. Kanıt olarak dokümantasyon

Üzerine iş kurulacak bir belge her iddiayı işaretler. İddia ya doğrulanmıştır ve onu üreten komut
yanında yazılıdır, ya da açık olduğu belirtilir. Üçüncü bir durum yoktur; işaretsiz kalan iddia
doğrulanmamış sayılır.

Ölçüm içeren her belge, ölçümün alındığı commit'i ve tarihi kaydeder ve sayıların bayatladığını
söyler. Okuyucu tek bir bayat sayı bulduğunda belgedeki diğer her şeyden de şüphe etmeye başlar.

Karar kayıtlarının (ADR) sabit bir şekli vardır. Başlıkta tarih, durum ve kararı tetikleyen bulguya
bağlantı bulunur. Context bir gözlem-kanıt tablosudur; her gözlem somut bir dosyayı veya ayarı işaret
eder. Karar tek cümledir. İş de ikiye ayrılır: "şimdi yapılacak" maddeleri ve "adlandırılmış sayısal
trigger geldiğinde yapılacak" maddeleri. Her "şimdi" maddesi onu tutacak kontrole bağlanır. Kapanışta,
koddan türetilemeyen tek girdi adlandırılır ve onun için karar istenir.

Audit bulguları sabit ID'ler alır ve bu ID'ler bulguyla birlikte dolaşır. Aynı ID karar kaydında,
fix'i zorlayan kontrolde ve takip işinde görünür. Bir audit ayrıca hangi kontrollerin gerçekten
koşulduğunu kaydeder ve neyi kapsamadığını açıkça söyler.

Nedensellik iddiası taşıyan her şey, veri var olmadan önce pre-register edilir. Pre-registration
şunları içerir: primary metric ve hipotez, exclusion'lar, stopping rule ve hangi secondary metric'lerin
manşet iddiada kullanılamayacağı. Tasarım ayrıca pre-register edilen her kuralı onu zorlayan teste
bağlayan bir tablo taşır. Simülasyon işleri iki arm'ı yan yana koşar. Null arm'ın gate'i "asla
kullanılabilir bir sonuç üretmemek"tir. Known-truth arm'ı ise analitik olarak türetilmiş bir
tolerance'a karşı kontrol edilir; bu tolerance koşu geçene kadar ayarlanmaz.

## 11. Çalışma disiplini

Yeşil bir gate bir branch'i push etmek için yeterlidir; merge için bu yetmez. Değişiklikler pull
request olarak gelir. Authentication, authorization, tenant isolation, ödeme mantığı, signature
doğrulama veya migration'lara dokunan diff'ler merge'den önce ikinci bir review'dan geçer.

Failure'ın tanımlı bir durma noktası vardır. Aynı alanda arka arkaya iki başarısız düzeltmeden sonra
düzenlemeyi bırak. Hatayı yeniden üret, varsayımları ve tüm call chain'i gözden geçir, doğru nedenle
düşen bir test yaz ve ancak ondan sonra root cause'u gider. O fix de tutmazsa üçüncü bir patch
denenmez. Düşen testi ve working tree'yi olduğu gibi bırak, iki denemeyi, hipotezi ve neden
tutmadığını yaz ve sonraki adımı bir karar olarak gündeme getir. Yeşile doğru zorlamak, sonunda
hangi fix'in gerçek olduğunu kimsenin bilmediği bir codebase bırakır.

Geliştirme yalnızca local ortamlara ve CI'ya karşı yapılır. Production database'lerine, host'larına
veya secret'larına bağlanılmaz ve aciliyeti ne olursa olsun production'a karşı ad-hoc query
çalıştırılmaz. Gerçek müşteri verisi debug'da asla kullanılmaz; production'dan bildirilen bir defect,
rapora benzer şekilde üretilmiş sentetik veriyle yeniden üretilir. Production erişimi gerektiren bir
adım geliştirme ortamından hiçbir zaman çalıştırılmaz.

Geliştirme ortamı da mühendislikle kurulur. Build ve start öncesinde koşan bir preflight script'i
gerekli dosya ve dizinleri denetler ve native dependency'lerin yüklendiğini görmek için onları
gerçekten çalıştırır. Bilinen platform arızaları için repoya commit'lenmiş script'ler vardır; çözüm
kimsenin hafızasına kalmaz.

## 12. Bu yöntemin vermediği şeyler

Ratchet regression'ı durdurur; debt'i azaltmak ayrı bir iştir. Gate, debt'in büyüdüğünü söyler; fazla
olup olmadığını söyleyemez. Azaltma ancak biri onu planladığında olur.

Bir gate tek bir özelliği kanıtlar; sorun olmadığını kanıtlayamaz. Buradaki her kontrolün tanımlı bir
scope'u vardır ve birçoğu kendi kör noktasını kendi dosyasında yazar. Yeşil bir koşu, ölçülen şeylerin
kötüleşmediği anlamına gelir.

Required check'leri ve review'ları tanımlayan bir manifest kendi içinde tutarlı olabilir ve bu
tutarlılık doğrulanabilir; bu sırada hosting platformu hiçbirini enforce etmiyor olabilir. Manifest'in
beyan ettiği ile platformun uyguladığı ayrı ayrı kontrol edilmelidir.

Hassas değişikliklerin ikinci bir review'dan geçmesi kuralı, bir şey onu zorlayana kadar yalnızca
bir taahhüttür.

Bazı tercihler yalnızca bu ölçekte doğrudur. Bir metrics stack'i işletmeden operasyonel görünürlüğü
query zamanında hesaplamak, müşteri başına tek instance için makul, elli instance için kötü bir
trade-off'tur. Buradaki her mimari seçimin doğru olmaktan çıktığı bir büyüklük vardır. İşe yarayan,
oraya vardığını sana hangi sayısal trigger'ın söyleyeceğini bilmektir.
