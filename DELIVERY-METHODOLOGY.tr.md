[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](DELIVERY-METHODOLOGY.md)

# Teslim ve quality gate metodolojisi

Bu belge, bir production sistemini değişiklik talebinden yayındaki release'e, kimsenin dikkatli
olmayı hatırlamasına güvenmeden nasıl götürdüğümü anlatıyor. Yöntem belirli bir stack'e bağlı değil;
GPU/ML workload'u olan, veri koruma kısıtları altında geliştirilen multi-tenant bir platformdan çıktı.

Tamamlayıcısı [güvenlik incelemesi ve PoC metodolojisi](METHODOLOGY.tr.md); o belge saldırgan
gözüyle incelemeyi, defect kanıtlamayı ve raporu değerlendirmeye hazır paketlemeyi anlatıyor. Bir
işin nasıl yürüdüğünün kısa hâli [portföy README'sinde](README.tr.md), içeride neler olduğunun uzun
hâli bu belgede.

Yöntemin dayandığı gözlem basit: birinin hatırlamasına bağlı bir kural er geç unutulur. Bu yüzden
öğrenmesi gerçekten vakit almış her ders sonunda bir makinenin denetlediği bir kontrole dönüşür;
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
5. Root cause'u gideren en küçük değişikliği yap. İlişkisiz temizlik ve formatlama aynı diff'e
   girmez; spekülatif abstraction ve istenmemiş API kırılmaları da girmez.

## 1. Bir değişikliğin "done" tanımı

Kod yazmadan önce gözlemlenebilir hedefi, kabul kriterlerini, scope'u ve ayakta kalması gereken
invariant'ları netleştiririm. Sonra okurum: mevcut implementasyonu ve testlerini, bir de tüm call
chain'i, yani değişen fonksiyonun içinde durduğu zincirin tamamını. Planın dayandığı her dosya,
route, komut ve ayarın gerçekten var olduğu işe başlamadan kontrol edilir.

Bunun ardından tutarlı en küçük değişikliği yazarım; çalışırken hedefli kontroller koşar, sonra
değişikliğin gerçekten gerektirdiği regression suite'ini çalıştırırım. Hedefli bir test ve bir
ekran görüntüsü regression geçişi sayılmaz.

Kapanışta diff'in tamamını scope, güvenlik ve yan etki açısından okur, neyin çalıştırıldığını ve ne
döndürdüğünü kaydederim. Atlanan iş, gerekçesiyle birlikte "atlandı" diye yazılır.

Davranışı koruyan refactor'lar uygulanmadan önce planlanır. Büyümüş bir modülün her bölünmesi ayrı,
küçük bir değişiklik olarak yazılır ve dört kurala bağlanır: yalnızca bölünen birimin içinde zaten
var olan kod taşınır; çıkarılan parça ince tutulur, bağımlılıkları dışarıdan verilir; route adı veya
response şekli taşımayla aynı değişiklikte değiştirilmez; mevcut testler de import satırları dışında
düzenlenmeden yeşil kalır.

## 2. Gate merdiveni

Dört kontrol seti var. Her biri ilk hatada duran bir zincir; hangi komutun düştüğü hep belli olur.

| Katman | Kapsam | Tetikleyici |
| --- | --- | --- |
| Hızlı gate | Secret scan, type build, lint, policy scanner'lar. Suite yok. | Pre-push hook |
| CI | Aynı policy seti, ardından lint, server testleri, frontend testleri, build, E2E ve smoke testleri; tek bir required check'te toplanır | Her pull request'te çalışacak şekilde ayarlı |
| Tam yerel koşu | Policy seti artı tüm suite'ler, build ve operasyonel smoke'lar | İhtiyaç hâlinde |
| Release ve drift | Yukarıdakilerin tamamı artı dependency ve lockfile policy'si, audit, governance, deploy readiness, release build'i ve artifact verification | Her release; ayrıca haftalık bir zamanlama ayarlı |

İşi gören gate yereldeki hook'tur. Kendini package lifecycle üzerinden kurar ve checkout dışında
hiçbir şey yapmaz; yeni bir clone, kimse ayar yapmadan korumalı gelir. Uzaktaki policy job'ı aynı
scanner setini koşar, yani yereli atlamak hatayı yalnızca geciktirir.

Escape hatch'ler asgari korumayı kapatamaz. Belgelenmiş birkaç bypass var ve her biri adı konmuş bir
durum için: acil bir push ya da çalışmayan bir uzak CI gibi. Her biri kullanıldığını çıktıda açıkça
belli eder, hiçbiri secret scan'i atlamaz ve zaman kazanmak için birine başvurmak kurallara
aykırıdır. Tekil scanner'lardaki istisnalar da aynı mantıkla çalışır: her biri satır düzeyindedir,
yazılı bir gerekçe taşır ve review için diff'te görünür. Hiçbiri bir kuralı sessizce susturmaz.

Her CI step'i çıktısını bir log dosyasına yazar ve child process'in kendi exit code'uyla sonlanır;
hiçbir wrapper bir failure'ı geçen bir step'e çeviremez. Her job ayrıca sanitize edilmiş bir
diagnostic paketi üretir ve onu yalnızca bir şey düştüğünde upload eder; environment dump'ları,
secret dosyaları, runtime database'leri ve upload'lar paketin dışında bırakılır.

## 3. Eski debt'i ratchet'le tutmak

Var olan debt ölçülür ve sabitlenir; büyüdüğü anda build düşer. Release'ler sürer, bu sırada debt
büyüyemez.

*Sayısal ratchet* yalnızca aşağı inebilen tek bir tam sayıdır. Örnekler: design token'ları dışında
kalan ham renk değerleri, API contract'ındaki gevşek schema girdileri ve hedeflenenin altında bir tier
ile korunan endpoint'ler. Baseline'ı yazan araç daha büyük bir sayıyı kaydetmeyi reddeder, yani sayı
kazara yukarı kayamaz.

*Envanter ratchet'i* bilinen ihlallerin sıralı listesidir. Yeni bir girdi build'i düşürür. *Stale*
bir girdi de düşürür: listedeki bir sorun çözülmüşse satırı aynı değişiklikte silinmelidir. Yoksa
ödenmiş debt, gelecekteki debt'e kılıf olarak listede kalır.

Makinenin gerekçe isteyebildiği her yerde gerekçe zorunludur. Yeni baseline'lanan bir istisna
`UNJUSTIFIED` placeholder'ıyla yazılır ve yerine gerçek bir gerekçe konana kadar gate düşmeye devam
eder.

Detector'lar kendilerini test eder. Her pattern kuralı eşleşen ve eşleşmeyen birer sample ile gelir;
bir kural kendi bad sample'ını yakalamayı bırakırsa veya good sample'ı yakalamaya başlarsa koşu düşer.
Zamanla no-op'a dönüşmüş bir kural, hiç kural olmamasından kötüdür: hâlâ coverage gibi görünür.

Baseline'lar, onları okuyan script'ten ayrı, kendi dosyalarında durur. Checker'a gömülü bir envanter
kimse fark etmeden stale olur. Repoya commit'lenmiş bir dosyada ise her istisna diff'e düşer ve
onaylanması gerekir.

## 4. Testler ne yakaladıklarıyla ölçülür

Coverage hangi satırların koştuğunu ölçer; suite'in düşüp düşmeyeceği hakkında bir şey söylemez.
Çöküşe karşı bir taban olarak kalır, ama asıl güvence aşağıdaki yöntemlerden gelir.

### Harness sadakati

Global middleware'e bağlı olan her şey (authentication, tenant resolution, CSRF, body parsing, rate
limiting) gerçek uygulama composition'ı üzerinden test edilir. Çıplak bir framework instance'ına
mount edilmiş bir handler bunun yerine geçmez. Mevcut kısayollar bir baseline'da dondurulur, yenileri
düşer.

### Önce kırmızı veren, doğru nedenle kırmızı veren regression testleri

Basit olmayan her test, defect'in sınıfını ve belirtisini, bir de önceki katmanın onu neden
kaçırdığını yazan bir açıklamayla başlar. En güçlü hâli bunu kanıtlar. Test, fix öncesi
implementasyonu kendi içine alır ve o implementasyonun sınanan kuralı ihlal ettiğini assert eder;
dosyayı koşunca eski kodun düştüğünü görürsün.

### Bağımsız oracle'lı property testleri

Bağımsız olması, referans implementasyonun sınanan kodla hiçbir aritmetik paylaşmaması demek;
paylaşsaydı, yakalamak için var olduğu defect'i miras alırdı. Para path'lerinde bu, beklenen değeri
yapısal olarak farklı bir yoldan hesaplamak demek. Örnek tabanlı testler bilinen zor noktaları
pinler; property testi ise o noktaların birer instance'ı olduğu kuralı ifade eder.

### Karşılığını verdiği yerde mutation testing

Para işleyen her modül için tek bir dosyayı mutate eden ve yalnızca o modülün testlerini koşan dar
bir config kullanılır. Threshold'lar ölçülmüş koşulardan gelir ve kanıtlanabilir biçimde equivalent
olan mutant'lar bir yorumda hesaba katılır; break değeri de buna göre şunu söyler: *yeni* hayatta
kalan her mutant koşuyu düşürür. Threshold'lar coverage iyileştikçe yükselir ve bir koşuyu geçirmek
için asla düşürülmez.

### Test hijyeni

- Determinizm baştan kurulur. Rastgele sleep yok; asenkron assertion'lar bir koşulu bekler. Zamana
  bağlı mantık saati parametre olarak alır, mock'a gerek kalmaz ve o mantığı mutate etmek de
  ucuzlar. Assertion'lar açık UTC timestamp'leriyle yazılır.
- Hiçbir şey ölçmemiş bir probe failure sayılır. Bir isolation testi sınır ötesine hiç deneme
  yapmadıysa ya da control probe kendi tarafında hiç başarılı olmadıysa, koşu boş ölçüm olarak düşer
  ve temiz sonuç bildirmez. Bu, [güvenlik metodolojisindeki](METHODOLOGY.tr.md) negative control'ün
  teslim tarafındaki ikizidir.
- Flaky testler araştırılır, retry'lanmaz. Accessibility hataları için bu iki kat geçerlidir; bunlar
  hukuki boyutu olan gerçek defect'lerdir. Doğası gereği kırılgan bir suite'te flakiness'in kaynağı
  ortadan kaldırılır (animasyon kapatılır, font yüklenmesi beklenir); testi bir retry'a sarmak
  gerçek bir regression'ı gizlerdi.

### Baskı altında

CI ayarlarında haftalık zamanlanmış bir non-functional katman, sistemin baskı altında sağlıklı kalıp
kalmadığını ölçer. Bu katmanda bir load smoke'u, uzun bir soak ve bir stress suite'i vardır. Stress
suite'i bir miktar hataya izin verir. Assert ettiği şey failure'ın *şeklidir*: çekişmeli bir randevu
slot'u tam olarak bir kazanan üretmeli, hostile input process'i devirmeden reddedilmeli, aynı anda
yarışan tenant'lar da birbirinin verisini okumamalı. Backpressure kalkanın çalıştığını gösterir;
başka türden bir failure bunu göstermez. Load threshold'ları ölçülmüş bir plateau'dan kalibre edilir,
kulağa rahat geldiği için seçilmez.

## 5. API contract'ı ve modül sınırları

API spec'i contract'ın kendisidir. Cross-cutting davranışı bir kez, tek bir yerde söyler; yeni bir
route da orada görünmeden push edilemez.

Coverage iki kez ve iki yönden ölçülür. Kaynak üzerinde metin taraması yalnızca bir route metoduna
doğrudan verilen literal path'leri görebilir; bir prefix altına mount edilmiş router'ları, path'i
değişken olarak alan registration'ları veya bir path dizisi üzerinde dönen loop'ları göremez. İkinci
ölçüm bunun için uygulamayı ayağa kaldırır, canlı routing table'ı gezer ve path şekline göre
karşılaştırır. Bulunan route sayısına konan bir sanity assertion'ı, bozuk bir walker'ın sessizce
geçmesini engeller. İki sayının farklı çıkması beklenir; doğru olan runtime sayısıdır.

Coverage'ın göremediğini başka kontroller yakalar. Biri çözülemeyen `$ref`'leri arar; bunlar
review'da iyi görünür ama dokümanı her katı consumer için geçersiz kılar. Bir diğeri eski
dialect'ten kalma keyword'leri arar; güncel bir validator onları hata vermeden yok sayar ve anlam
sessizce kaybolur. Bir başkası security tanımı olmayan operation'ları arar; her entegratör ve code
generator bunları public kabul eder.

Modül sınırlarını kontroller korur. Server kodu browser kodunu import etmez ve modül graph'ında cycle
yoktur; cycle tespiti parse edilmiş bir import graph'ı üzerinde yapılır ve runtime'da yok olan
type-only edge'leri dışarıda bırakır. Her iki allowlist de sıfırdadır; ratchet olmaktan çıkıp
invariant olarak çalışırlar. Browser'dan API'ye giden tüm trafik, credential'ları, header'ları,
timeout'ları ve circuit breaker'ı sahiplenen tek bir client'tan geçer ve onu bypass eden her şeyin
bir baseline'da yazılı gerekçesi olmak zorundadır.

Type check, project graph'ı üzerinde build modunda koşar. Project'lerin lib ve target ayarları
farklıdır; hepsini tek bir düz pass'e indirmek, server kodunu DOM global'lerine karşı kontrol etmek
olurdu.

## 6. Migration ve recovery

Migration'lar dosyadır, sırayla apply edilir ve content hash'iyle kaydedilir. Commit'lenmiş bir
migration dosyası asla düzenlenmez: düzenlenirse bir sonraki boot hash'i yeniden hesaplar, başlamayı
reddeder ve bunun yerine ne yapılması gerektiğini söyler.

Migration'ları yalnızca leader process çalıştırır; process'ler arası bir lock altında ve dosya başına
atomic olarak. Lock ilk schema yazımından önce alınır, böylece aynı anda başlayan birkaç process taze
bir database'de aynı tabloları oluşturmak için yarışamaz.

Crash sonrası recovery, lock'u yalnızca kanıtlanabilir biçimde ölmüş bir process'ten geri alır;
lock'u tutan process'in yaşayıp yaşamadığını belirleyemezse dosya yaşına bakan bir staleness
kontrolüne düşer. Bu sıralamanın nedeni şu: senkron bir migration event loop'u bloke eder, uzun süren
bir index build'i gayet hayattayken kendi timestamp'ini yenileyemez ve yalnızca yaşa bakan bir kural,
boot etmekte olan bir peer'in lock'u onun elinden almasına izin verirdi. Bunun testleri, aynı dosya
için çekişen gerçek process'ler başlatır; mock kullanılmaz.

Down migration yoktur; rollback, bir snapshot'tan restore etmektir. Bu, müşteri başına tek stack
çalışan bir deployment'a uyar ve bir karar olarak yazılıdır; kimse bunu ilk kez bir incident
sırasında öğrenmez.

Operasyonel prosedürler script'tir, kimsenin hatırlaması gerekmez: retention ve pruning içeren
zamanlanmış backup'lar, uyarı ve kritik kademeli boyut monitoring'i, path traversal'a karşı doğrulama
yapan bir restore komutu ve varsayılan olarak dry-run koşan bir cleanup komutu. Recovery hedefleri ve
storage modelinin dayattığı sıra bir runbook'ta, bir sonraki mimari kararı tetikleyen sayıların
yanında durur.

## 7. Güvenlik duruşu

Her savunma primitifi kendi modülünde durur ve modülün başındaki yorum, kapattığı saldırıyı ya da
incident'ı adıyla yazar. Her primitif böylece tek başına incelenebilir ve gerekçe, refactor'lar
boyunca kodun yanında kalır.

Para hareket ettiren callback'ler hostile input kabul edilir. Önce signature doğrulanır. Sonra dönen
token, constant-time karşılaştırmayla intent üzerindeki token'a bind edilir, authoritative kayıt
provider'dan çekilir ve tahsil edilen tutar beklenenle karşılaştırılır. State ancak bundan sonra
değişir. Tutarlar digit string'inden parse edilir, çünkü floating point'te çarpmak tutarsız yuvarlar
ve doğru bir settlement'ı eksik okuyabilir. State geçişleri, guard'larını SQL predicate'inin içinde
tekrarlar; eşzamanlı bir callback read-then-write race'ini kazanamaz. Terminal state'ler terminaldir
ve idempotency bir database constraint'idir.

Bazı kontrollerin birbiriyle uyuşması gereken iki yarısı vardır; örneğin body parsing'den muaf bir
path ile aynı path'in CSRF muafiyeti. Structural bir test iki yarıyı birden assert eder ve eksik
girdide olduğu kadar stale girdide de düşer, yani bir sonraki ekleme tek tarafı bağlanmış hâlde
yayına giremez.

Yetki tier'ları ölçümle belirlenir. "Kaç endpoint olması gerekenden düşük bir tier'la korunuyor"
sorusu iki ayrı günde iki ayrı cevap üretince, buna aynı census'ü her seferinde aynı şekilde üreten
bir script'le cevap verildi. Script hem sayıyı hem listeyi dondurur; bir girdiyi başkasıyla
değiştirmek yeni bir girdiyi gizleyemez. Behavioural bir test bunu destekler, çünkü dependency
injection'ın guard'ı gizlediği her yerde metin taraması stale olur.

Secret scan iki derinlikte yapılır, working tree'de ve commit'lenmiş history'de; bir zamanlar
commit'lenip sonra silinmiş bir credential da push'u engeller. Supply chain policy'si kod olarak
yazılıdır: sabitlenmiş lockfile formatı, yalnızca registry üzerinden resolution, install script'i
çalıştırmasına izin verilen paketler için bir allowlist, tam commit hash'ine pin'lenmiş üçüncü taraf
CI action'ları, her workflow'da explicit permission tanımı ve untrusted input'un shell komutlarına
interpolate edilmemesi.

Her bulgu triage edilir; hiçbiri doğrudan kabul edilmez ya da atılmaz. Sonraki bir review, önceki
her bulguyu koda karşı yeniden kontrol eder. Çürütülen bir bulgu, karşı kanıtıyla birlikte düzeltme
olarak kayıtta kalır; ayrılan sürede incelenemeyen bir alan da "incelenmedi" diye kaydedilir,
hiçbir zaman "temiz" diye anlatılmaz.

## 8. Release ve deployment

Release artifact'ı explicit bir allowlist ile derlenir (ignore listesi kullanılmaz), bir staging
dizinine alınır ve aynı exclusion'ları yeniden doğrulamak için ikinci kez gezilir. Çıktıya bir
checksum ve içine neyin girdiğini, hangi kuralların uygulandığını kaydeden bir manifest eşlik eder.

Doğrulama, arşivden *açılan kopyayı* yeniden build eder ve test eder; working tree bu işe karışmaz.
Verifier hash'i kontrol eder, arşivi absolute path'leri ve path traversal'ı reddeden bir reader ile
açar, ardından working directory açılan kopyanın içindeyken install, policy scanner'ları, lint,
build ve test suite'lerini koşar. Engellenmiş bir subprocess environment blocker olarak raporlanır ve
CI'da fatal'dır; kontrol sessizce bir dosya listelemesine indirgenemez.

Deployment, hâlihazırda publish edilmiş bir artifact'ı promote eder; hiçbir zaman yenisini build
etmez. Remote script checksum'ı doğrular, release'e özel bir dizine extract eder (var olanın üzerine
yazmayı reddeder), önce veriyi snapshot'lar, host üzerinde install eder, çıkan release'i kaydeder,
canlı pointer'ı çevirir, servisi restart eder, health endpoint'lerini poll eder ve failure hâlinde
otomatik rollback yapar. Readiness endpoint'i gerçek bir dependency probe'udur ve gerçek bir query
ile gerçek filesystem kontrolleri çalıştırır; koşulsuz "healthy" döndüren bir endpoint, bozuk bir
instance'ı rotasyonda tutar.

Release dokümantasyonu, yeşil bir test koşusunun production sign-off olmadığını açıkça söyler ve
sign-off için gerekenleri sayar: gerçek bir provider'a karşı canlı bir ödeme ve iade, yeniden
üretilmiş secret'lar ve restore edildiği *kanıtlanmış* host dışı bir backup. Restore'un yalnızca
yapılandırılmış olması yetmez.

## 9. Dark launch ve ön koşul olarak compliance

Önemli feature'lar kapalı yayınlanır. Operatörler için bu flag'leri listeleyen tek yer, küratörlü bir
catalog'dur. Catalog her flag'i, o flag'i tüketen kodun kendi semantiğiyle anlatmak zorundadır ve her
girdi ilgili kodu işaret eder; aynı kontrolün daha gevşek bir kopyasını yazmak kabul edilmez.

Status vocabulary'sinin üç değeri var. *On*, bir precondition sonradan bozulmuş olsa bile gerçekte
neyin çalıştığını doğru söyler. *Off*, dark ve hazır demektir. *Blocked* ise dark demektir ve
karşılanmamış bir precondition olduğunu gösterir.

Bazı precondition'ları makine kontrol edebilir: bir key mevcut mu, bir provider yapılandırılmış mı.
Bazıları ise insana bağlıdır; örneğin bir aydınlatma metninin onaylanıp yayımlanmış olması ya da bir
deneyin pre-registration'ının tamamlanmış olması. Bunlar da, kontrol makine tarafından okunabilir
kalsın diye aynı flag mekanizmasıyla beyan edilir; hukuki veya yöntemsel bir yükümlülük böylece
*activation path'inin üzerinde* durur ve karşılanana kadar feature blocked kalır.

Rollout yüzdeleri flag ile entity'nin stable bir hash'i üzerinden bucket'lanır; kısmi bir rollout
her evaluation'da aynı entity'leri içerir ve request başına yeniden karılmaz. Her evaluation, kararı
veren kuralı adlandıran machine-readable bir reason döndürür.

Dışa giden entegrasyonlar dayanıklı bir outbox ve bir worker üzerinden yürür; kullanıcıya bakan bir
request hiçbir zaman üçüncü tarafı beklemez. Idempotency, logical event üzerinde bir unique
index'tir. Retry'lar üst sınırı olan bir backoff ile yapılır; retry hakkı tükenen bir job kaybolmaz,
operatörün görebildiği explicit bir "dead" state'ine geçer. Düzenleyici yükümlülük taşıyan
entegrasyonlar fail-closed davranır ve primary source'larını modül başlığında belirtir. Onay izin
verir. Ret *veya hiçbir kaydın bulunmaması* engeller, çünkü kayıt yoksa eylem hukuka uygun değildir.
Cache'leri kesin cevabı uzun, hatayı kısa bir TTL ile tutar; bir kesinti sırasında entegrasyon
blocked kalır ve çabuk toparlanır, permissive hâle gelmez.

## 10. Kanıt olarak dokümantasyon

Üzerine iş kurulacak bir belge her iddiayı işaretler: iddia ya doğrulanmıştır ve onu üreten komut
yanında yazılıdır, ya da açık olduğu belirtilir. Üçüncü bir durum yoktur; işaretsiz kalan iddia
doğrulanmamış sayılır.

Ölçüm içeren her belge, ölçümün alındığı commit'i ve tarihi kaydeder; sayıların bayatladığını da
söyler. Okuyucu tek bir bayat sayı bulduğunda belgedeki diğer her şeyden de şüphe etmeye başlar.

Karar kayıtlarının (ADR) sabit bir şekli vardır. Başlıkta tarih ve durum, bir de kararı tetikleyen
bulguya bağlantı bulunur. Context bir gözlem-kanıt tablosudur; her gözlem somut bir dosyayı veya
ayarı işaret eder. Karar tek cümledir. İş de ikiye ayrılır: her biri onu tutacak kontrole bağlanan
"şimdi yapılacak" maddeleri ve "adlandırılmış sayısal trigger geldiğinde yapılacak" maddeleri.
Kapanışta, koddan türetilemeyen tek girdi adlandırılır ve onun için karar istenir.

Audit bulguları sabit ID'ler alır ve bu ID'ler bulguyla birlikte dolaşır. Aynı ID karar kaydında,
fix'i zorlayan kontrolde ve takip işinde görünür. Bir audit ayrıca hangi kontrollerin gerçekten
koşulduğunu kaydeder ve neyi kapsamadığını açıkça söyler.

Nedensellik iddiası taşıyan her şey, veri var olmadan önce pre-register edilir: primary metric ve
hipotez, exclusion'lar, stopping rule ve hangi secondary metric'lerin manşet iddiada
kullanılamayacağı. Tasarım ayrıca pre-register edilen her kuralı onu zorlayan teste bağlayan bir
tablo taşır. Simülasyonlar iki arm'ı yan yana koşar. Null arm'ın gate'i "asla kullanılabilir bir
sonuç üretmemek"tir. Known-truth arm'ı ise analitik olarak türetilmiş bir tolerance'a karşı kontrol
edilir ve bu tolerance koşu geçene kadar ayarlanmaz.

## 11. Çalışma disiplini

Yeşil bir gate bir branch'i push etmek için yeterlidir; merge için bu yetmez. Değişiklikler pull
request olarak gelir; authentication, authorization, tenant isolation, ödeme mantığı, signature
doğrulama veya migration'lara dokunan diff'ler merge'den önce ikinci bir review'dan geçer.

Failure'ın tanımlı bir durma noktası vardır. Aynı alanda arka arkaya iki başarısız düzeltmeden sonra
düzenlemeyi bırak. Hatayı yeniden üret, varsayımları ve tüm call chain'i gözden geçir, doğru nedenle
düşen bir test yaz ve ancak ondan sonra root cause'u gider. O fix de tutmazsa üçüncü bir patch
denenmez: düşen testi ve working tree'yi olduğu gibi bırak, iki denemeyi, hipotezi ve neden
tutmadığını yaz ve koda yeniden dokunmadan önce ne yapılacağına karar ver. Yeşile doğru zorlamak,
sonunda hangi fix'in gerçek olduğunu kimsenin bilmediği bir codebase bırakır.

Geliştirme yalnızca local ortamlara ve CI'ya karşı yapılır; production database'lerine, host'larına
veya secret'larına bağlanmak da, aciliyeti ne olursa olsun production'a karşı ad-hoc query
çalıştırmak da bu işin dışındadır. Gerçek müşteri verisi debug'da asla kullanılmaz; production'dan
bildirilen bir defect, rapora benzer şekilde üretilmiş sentetik veriyle yeniden üretilir. Production
erişimi gerektiren adımlar geliştirme ortamının dışında kalır.

Geliştirme ortamı da mühendislikle kurulur. Build ve start öncesinde koşan bir preflight script'i
gerekli dosya ve dizinleri denetler ve native dependency'lerin yüklendiğini görmek için onları
gerçekten çalıştırır. Bilinen platform arızaları için repoya commit'lenmiş script'ler vardır; çözüm
kimsenin hafızasına kalmaz.

## 12. Bu yöntemin vermediği şeyler

Ratchet regression'ı durdurur; debt'i azaltmak ayrı bir iştir. Gate, debt'in büyüdüğünü söyler ama
fazla olup olmadığını söyleyemez. Azaltma ancak biri onu planladığında olur.

Bir gate tek bir özelliği kanıtlar; sorun olmadığını kanıtlayamaz. Buradaki her kontrolün tanımlı bir
scope'u vardır ve birçoğu kendi kör noktasını kendi dosyasında yazar. Yeşil bir koşu, ölçülen
şeylerin kötüleşmediğini gösterir.

Required check'leri ve review'ları tanımlayan bir manifest, kendi içinde tutarlı olduğu için
doğrulamadan geçebilir; bu sırada hosting platformu hiçbirini enforce etmiyor olabilir. Manifest'in
beyan ettiği ile platformun uyguladığı ayrı ayrı kontrol edilmeli.

Hassas değişikliklerin ikinci bir review'dan geçmesi kuralı, bir şey onu zorlayana kadar yalnızca
bir taahhüttür.

Bazı tercihler yalnızca bu ölçekte doğru. Bir metrics stack'i işletmeden operasyonel görünürlüğü
query zamanında hesaplamak, müşteri başına tek instance için makul, elli instance için kötü bir
trade-off'tur. Buradaki her mimari seçimin doğru olmaktan çıktığı bir büyüklük vardır. İşe yarayan,
oraya vardığını sana hangi sayısal trigger'ın söyleyeceğini bilmektir.
