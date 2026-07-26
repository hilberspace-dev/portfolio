[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](DELIVERY-METHODOLOGY.md)

# Teslim ve Kalite Kapısı Metodolojisi

Üretimdeki bir sistemi, bir değişiklik talebinden yayımlanmış bir sürüme, kimsenin dikkatli olmayı
hatırlamasına bel bağlamadan taşıma yöntemim. Teknoloji yığınından bağımsızdır; bu yöntemi ortaya
çıkaran uygulama, GPU/ML iş yükü taşıyan, veri koruma kısıtları altında işletilen ve çok küçük bir
ekiple sürdürülen çok kiracılı ticari bir platformdu.

Bu belge, saldırgan bakış açılı incelemeyi ve kusur kanıtlamayı anlatan
[Güvenlik İncelemesi ve PoC Metodolojisi'nin](METHODOLOGY.tr.md) tamamlayıcısıdır. Teslim akışının
kısa özeti [portföy README'sinde](README.tr.md); işin içinde ne olduğunun uzun hâli burada.

**Temel ilke: hatırlanmaya bağlı kural, kural değildir.** Öğrenmesi gerçekten pahalıya mal olmuş her
ders ya bir makinenin kontrol ettiği bir şeye dönüşür ya da geri gelir.

---

## 0. Değişmez kurallar

1. **İddiadan önce kanıt.** Hiçbir şey; çalıştırılan komut, çıktısı ve çıkış kodu olmadan "düzeldi",
   "geçiyor" veya "bitti" diye anlatılmaz. Kodu okumak doğrulama değildir. Yeniden çalıştırıp yeşil
   almak, önceki bir başarısızlığı geçersiz kılmaz. Çalıştırılmayan ne varsa açıkça söylenir.
2. **Örneği değil sınıfı düzelt.** Hatayı gideren commit işin yarısıdır. Diğer yarısı, bu kusuru
   hangi kontrolün yakalaması gerekirken yakalamadığını yanıtlamak ve o kontrolü kurmaktır.
3. **Borcu dondur, asla genişletme.** Mevcut sorunlar ölçülür ve bugünkü büyüklüğünde sabitlenir.
   Yenisi derlemeyi düşürür. Kapıyı yeşile çevirmek için kimse bir baseline'ı düzenlemez.
4. **Kapalı tarafa düş ve kör noktanı söyle.** Para, güvenlik veya kişisel veri taşıyan her yolda
   belirsizlik reddetmeye çözülür. Her ölçüm aracı, kendi dosyasında neyi göremediğini yazar.
5. **Kök nedeni gideren en küçük değişiklik.** Aynı diff'e ilişkisiz temizlik, biçimlendirme,
   spekülatif soyutlama veya istenmemiş API kırılması binmez.

---

## 1. Bir değişikliğin "bitti" tanımı

Kod yazmadan önce: gözlemlenebilir hedef, kabul kriterleri, kapsam ve ayakta kalması gereken
değişmezler. Ardından mevcut kod, testleri ve **tam çağrı zinciri** okunur — değişen fonksiyon değil,
içinde durduğu zincir. Planın dayandığı her dosyanın, rotanın, komutun ve ayarın adından tahmin
edilmek yerine gerçekten var olduğu doğrulanır.

Sonra tutarlı en küçük değişiklik yazılır, çalışırken hedefli kontroller koşulur ve değişikliğin
gerçekten gerektirdiği regresyon süiti çalıştırılır. Hedefli bir test artı ekran görüntüsü regresyon
geçişi sayılmaz; bunu baştan söylemek, sonradan yakalanmaktan ucuzdur.

Kapanış, diff'in tamamını kapsam, güvenlik ve yan etki açısından okumak ve neyin çalıştırılıp ne
döndüğünü kaydetmektir. Bilinçli olarak atlanan iş, gerekçesiyle birlikte atlanmış olarak yazılır.

Davranışı koruyan refactor'lar uygulanmadan önce planlanır. Büyümüş bir modülün her bölünmesi kendi
küçük değişikliği olarak yazılır ve kuralları eklenir: yalnızca bölünen birimin içinde hâlihazırda
var olan kod taşınır, çıkarılan parça ince tutulur ve bağımlılıkları dışarıdan verilir, taşıma ile
aynı değişiklikte rota adı veya yanıt şekli değiştirilmez, mevcut testler import'lar dışında
düzenlenmeden yeşil kalır.

---

## 2. Kapı merdiveni

Dört kontrol seti. Her biri ilk hatada duran bir zincir, böylece hangi komutun düştüğü hiç
belirsiz kalmaz.

| Katman | Kapsam | Nerede |
| --- | --- | --- |
| Hızlı kapı | Secret taraması, tip derlemesi, lint, politika tarayıcıları. Süit yok. | Pre-push hook |
| CI | Aynı politika seti, ardından lint, sunucu testleri, arayüz testleri, build, uçtan uca ve smoke testleri; tek bir zorunlu kontrolde toplanır | Her pull request |
| Tam yerel koşu | Politika seti artı tüm süitler, build ve operasyonel smoke'lar | İhtiyaç hâlinde |
| Sürüm ve sapma | Yukarıdakilerin tamamı artı bağımlılık ve lockfile politikası, audit, yönetişim, dağıtım hazırlığı, sürüm derlemesi ve artefakt doğrulaması | Haftalık ve her sürümde |

Bunu kâğıt üstünde kalmaktan çıkaran iki şey var.

**Asıl kapı yereldeki hook'tur.** Paket yaşam döngüsü üzerinden kendini kurar ve checkout dışında hiçbir
şey yapmaz; böylece taze bir klon kimse ayar yapmadan korunur. Uzaktaki politika işi aynı tarayıcı
setini koşar, dolayısıyla yereli atlamak gecikmeden başka bir şey kazandırmaz.

**Kaçış kapısı tabanı kapatamaz.** Belgelenmiş tek bir bypass var. Yalnızca hızlı kapıyı atlar, secret
taramasını asla; kendini stderr'e duyurur ve zaman kazanmak için ona uzanmak tavsiye edilmemekle
kalmaz, kurallara aykırıdır. Tekil tarayıcı içindeki istisnalar da aynı mantıkta: satır düzeyinde,
yazılı gerekçeli ve bir kuralı sessizce susturmak yerine diff'te görünür.

Her CI adımı çıktısını bir log dosyasına yazar ve alt sürecin kendi çıkış koduyla sonlanır; böylece
hiçbir sarmalayıcı bir hatayı geçen bir adıma çeviremez. Her iş, yalnızca bir şey düştüğünde
yüklenen ve ortam dökümlerini, secret dosyalarını, çalışma zamanı veritabanlarını ve yüklemeleri
bilinçli olarak dışarıda bırakan temizlenmiş bir teşhis paketi üretir.

---

## 3. Ratchet: eski borç nasıl tutuluyor

Kod tabanı temizlenene kadar yayın yapmamak bir plan değildir. Borcu görmezden gelmek de. Ortadaki
yol, borcu ölçmek, sabitlemek ve büyümesini düşürmektir.

**Sayısal ratchet** yalnızca aşağı inebilen tek bir tam sayıdır: tasarım token'ları dışında kalan ham
renk değerleri, API sözleşmesindeki gevşek şema girdileri, hedeflenenin altında bir katmanla korunan
uç noktalar. Baseline'ı yazan araç daha büyük bir sayıyı kaydetmeyi reddeder; yukarı giden kazara bir
yol yoktur.

**Envanter ratchet'i** bilinen ihlallerin sıralı listesidir. Yeni bir girdi derlemeyi düşürür.
*Bayat* bir girdi de düşürür: listedeki bir sorun bu arada çözülmüşse, satırı aynı değişiklikte
silinmelidir. Aksi hâlde ödenmiş borç, gelecekteki borca kılıf olarak listede kalır.

Çalışan bir ratchet'i depoyu süsleyen bir ratchet'ten ayıran üç ayrıntı var:

- **Gerekçe, makinenin zorlayabildiği yerde zorunludur.** Yeni baseline'lanan bir istisna
  `UNJUSTIFIED` yer tutucusuyla yazılır ve biri onun yerine gerçek bir gerekçe koyana kadar kapı
  düşmeye devam eder.
- **Dedektörler kendilerini test eder.** Her desen kuralı, eşleşen ve eşleşmeyen birer örnekle gelir;
  bir kural kendi kötü örneğini yakalamayı bırakırsa veya iyi örneği yakalamaya başlarsa koşu düşer.
  Sessizce işlevsizleşmiş bir kural, hiç kural olmamasından kötüdür; çünkü kapsam gibi okunur.
- **Baseline'lar dosyada durur, onları okuyan script'in içinde değil.** Kontrol script'ine gömülü bir
  envanter sessizce bayatlar. Depoya işlenmiş bir dosyada ise her istisna diff'e düşer ve birinin
  onaylaması gerekir.

---

## 4. Çalıştıran değil, yakalayan testler

Kapsam (coverage) hangi satırların koştuğunu ölçer; süitin düşüp düşmeyeceğini ölçmez. Kapsam
çöküşe karşı bir taban olarak kalır; güvence dört başka şeyden gelir.

**Harness sadakati.** Küresel ara katmana bağlı olan her şey — kimlik doğrulama, kiracı çözümleme,
CSRF, gövde ayrıştırma, hız sınırlama — gerçek uygulama kompozisyonu üzerinden test edilir; asla çıplak
bir framework örneğine iliştirilmiş bir handler üzerinden değil. Bu ayrım teorik değil: üretime ulaşan
iki kusur, kolaycı test kurulumlarında görünmezken testler gerçek kompozisyonu ayağa kaldırdığı anda
apaçık hâle geldi. Mevcut kısayollar bir baseline'da dondurulur, yenileri düşer.

**Önce kırmızı veren, doğru nedenle kırmızı veren regresyon testleri.** Önemsiz olmayan bir test,
kusurun sınıfını, belirtisini ve önceki katmanın onu neden kaçırdığını söyleyerek açılır. En güçlü
hâli bunu kanıtlar: test, düzeltme öncesi uygulamayı kendi içine alır ve o uygulamanın sınanan kuralı
ihlal ettiğini iddia eder. Böylece dosya, eski kodda düşeceğini iddia etmekle kalmaz, gösterilebilir
biçimde düşer.

**Bağımsız oracle'lı property testleri.** Bağımsız olması, referans uygulamanın sınanan kodla hiçbir
aritmetik paylaşmaması demektir; paylaşırsa yakalamak için var olduğu kusuru miras alır. Para
yollarında bu, beklenen değeri yapısal olarak farklı bir yoldan hesaplamak anlamına gelir. Örnek
tabanlı testler bilinen zor noktaları sabitler; property testi ise o noktaların birer örneği olduğu
kuralı ifade eder.

**Karşılığını verdiği yerde mutasyon testi.** Para işleyen her modül için tek bir dosyayı mutasyona
sokan ve yalnızca o modülün testlerini koşan dar bir konfigürasyon. Eşikler, kanıtlanabilir biçimde
eşdeğer mutantlar bir yorumda hesaba katılarak ölçülmüş koşulardan gelir; böylece kırılma değeri
"*yeni* hayatta kalan her mutant koşuyu düşürür" anlamına gelir. Eşikler kapsam iyileştikçe yükselir.
Bir koşuyu geçirmek için asla düşmez.

Bunların altında üç alışkanlık var:

- **Determinizm umut edilmez, kurulur.** Rastgele uyku yok; asenkron iddialar bir koşulu bekler.
  Zamana bağlı mantık, mock'lanmak yerine saati parametre olarak alır — bu aynı zamanda onu mutasyona
  sokmayı ucuzlatır. İddialar açık UTC zaman damgalarıyla yazılır.
- **Hiçbir şey ölçmemiş bir prob, başarısızlıktır.** Bir izolasyon testi sınır ötesi hiç deneme
  yapmadıysa ya da kontrol probu kendi tarafında hiç başarılı olmadıysa, koşu temiz sonuç bildirmek
  yerine boş ölçüm olarak düşer. Bu, [güvenlik metodolojisindeki](METHODOLOGY.tr.md) negatif
  kontrolün teslim tarafındaki ikizidir.
- **Flake araştırılır, yeniden denenmez.** Özellikle erişilebilirlik hataları: bunlar gürültü değil,
  hukuki boyutu olan kusurlardır. Doğası gereği kırılgan bir süitte flake'in kaynağı ortadan
  kaldırılır — animasyon kapatılır, font yüklenmesi beklenir — gerçek bir regresyonu gizleyecek bir
  retry'a sarılmaz.

Doğruluğun ötesinde, haftalık bir fonksiyonel olmayan katman sistemin baskı altında sağlıklı kalıp
kalmadığını sorar: bir yük smoke'u, uzun bir soak ve hataların yokluğunu değil **hatanın şeklini**
sınayan bir stres süiti. Çekişmeli bir randevu slotu tam olarak bir kazanan üretmelidir. Düşmanca
girdi, süreci devirmeden reddedilmelidir. Aynı anda yarışan kiracılar birbirinin verisini
okumamalıdır. Bilinçli backpressure kalkanın çalıştığı sayılır; başka bir şey sayılmaz. Yük eşikleri
kulağa rahat geldiği için değil, ölçülmüş bir platodan kalibre edilir.

---

## 5. Sözleşmeler ve sınırlar

API şartnamesi sözleşmedir; sonradan yazılan dokümantasyon değil. Kesişen davranışı her operasyonda
tekrar etmek yerine bir kez söyler ve yeni bir rota orada görünmeden push edilemez.

Kapsam iki yönden ve iki kez ölçülür. Kaynak üzerinde metin taraması yalnızca bir rota metoduna
doğrudan verilen düz yolları görebilir; bir önek altına mount edilmiş router'ları, yolu değişken
olarak alan kayıtları veya bir yol dizisi üzerinde dönen döngüleri göremez. Bu yüzden ikinci ölçüm
uygulamayı ayağa kaldırır, canlı yönlendirme tablosunu gezer ve yol şekline göre karşılaştırır; bozuk
bir gezginin sessizce geçmemesi için bulunan rota sayısına da bir sağlık iddiası koyar. Dürüst olan
sayı çalışma zamanınınkidir ve ikisinin ayrışması beklenir. Kapsamın göremediğini üç kardeş kontrol
korur: çözülemeyen referanslar — incelemede iyi görünürken belgeyi her katı tüketici için geçersiz
kılar; eski lehçeden kalma anahtar kelimeler — güncel bir doğrulayıcı onları reddetmez, yok sayar,
yani sessiz anlam kaybıdır; ve güvenlik tanımı olmayan operasyonlar — her entegratör ve kod üreteci
için public okunur.

Modül sınırları iyi niyetle değil kontrollerle korunur. Sunucu kodu tarayıcı kodunu import etmez.
Modül grafiğinde döngü yoktur; bu, ayrıştırılmış bir import grafiği üzerinde, çalışma zamanında yok
olan tip-yalnızca kenarlar dışarıda bırakılarak tespit edilir. Her iki izin listesi de sıfırdadır, ki
bu onları ratchet olmaktan çıkarıp değişmez kurala dönüştürür. Tarayıcıdan API'ye giden tüm trafik;
kimlik bilgilerini, başlıkları, zaman aşımlarını ve devre kesiciyi sahiplenen tek bir istemciden
geçer. Onu atlayan her şeyin bir baseline'da yazılı gerekçesi olmak zorundadır.

Tip kontrolü düz tek bir geçiş yerine proje grafiği üzerinde build modunda koşar; çünkü projelerin
kütüphane ve hedef ayarları farklıdır ve hepsini tek geçişe indirmek sunucu kodunu tarayıcı
global'lerine karşı kontrol etmek anlamına gelir.

---

## 6. Veri, göç ve kurtarma

Göçler dosyadır, sırayla uygulanır ve içerik özetiyle kaydedilir. İşlenmiş bir göç dosyası asla
düzenlenmez; bu bir inceleme geleneği değildir: bir sonraki açılış özeti yeniden hesaplar, başlamayı
reddeder ve bunun yerine ne yapılması gerektiğini söyler.

Yürütme yalnızca lider süreçte, süreçler arası kilit altında ve dosya başına atomik yapılır. Kilit ilk
şema yazımından önce alınır; böylece aynı anda başlayan birkaç süreç taze bir veritabanında aynı
tabloları oluşturmak için yarışamaz. Çökme sonrası kurtarma, kilidi yalnızca kanıtlanabilir biçimde
ölmüş bir süreçten geri alır ve canlılık belirlenemediğinde dosya yaşına bakan bayatlık kontrolüne
düşer — çünkü senkron bir göç olay döngüsünü bloke eder, uzun süren bir index derlemesi hayattayken
kendi zaman damgasını tazeleyemez ve yalnızca yaşa bakan bir kural, açılmakta olan bir eşin kilidi
altından çekmesine izin verirdi. Bu, mock'larla değil, aynı dosya üzerinde çekişen gerçek süreçlerle
doğrulanır.

Geri alma göçü yoktur. Rollback, bir anlık görüntüden geri yüklemedir. Müşteri başına tek yığın
çalışan bir dağıtımda dürüst cevap budur ve bunu bir karar olarak yazmak, bir olay sırasında keşfetmeye
yeğdir.

Operasyonel prosedürler hatırlanmaz, script'lenir: saklama ve budama içeren zamanlanmış yedekler,
uyarı ve kritik kademeli boyut izleme, yol geçişine karşı doğrulama yapan bir geri yükleme ve
varsayılan olarak kuru koşan bir temizleme komutu. Kurtarma hedefleri ve depolama modelinin dayattığı
sıra, bir sonraki mimari kararı tetikleyen sayıların yanında, bir runbook'ta durur.

---

## 7. Güvenlik duruşu

Her savunma ilkesi kendi modülünde yaşar ve kapattığı saldırıyı veya olayı adlandıran bir yorumla
açılır. Bu, her birini tek başına incelenebilir tutar ve gerekçeyi refactor'lar boyunca kodun yanında
tutar.

Para hareket ettiren geri çağrılar düşmanca girdi kabul edilir: önce imza doğrulanır, dönen token
sabit zamanlı karşılaştırmayla niyet kaydındaki token'a bağlanır, yetkili kayıt sağlayıcıdan çekilir,
tahsil edilen tutar beklenenle karşılaştırılır ve ancak ondan sonra durum değişir. Tutarlar kayan
noktada çarpılmak yerine rakam dizisinden ayrıştırılır; çünkü kayan nokta yolu tutarsız yuvarlar ve
doğru bir ödemeyi eksik okuyabilir. Durum geçişleri korumasını SQL koşulunun içinde tekrarlar, böylece
eşzamanlı bir geri çağrı oku-sonra-yaz yarışını kazanamaz; nihai durumlar nihaidir ve idempotency bir
uygulama kontrolü değil veritabanı kısıtıdır.

Bir kontrolün birbiriyle uyuşması gereken iki yarısı varsa — örneğin gövde ayrıştırmadan muaf bir yol
ile aynı yolun CSRF muafiyeti — yapısal bir test ikisini birden sınar ve eksik girdi kadar bayat
girdide de düşer; böylece bir sonraki ekleme tek tarafı bağlanmış hâlde yayına giremez.

Yetki katmanları tartışılmaz, ölçülür. "Kaç uç nokta olması gerekenden düşük korunuyor" sorusu iki ayrı
günde iki ayrı cevap üretince, çözüm üçüncü bir görüş değil, aynı sayımı her seferinde aynı şekilde
üreten bir script oldu: hem sayı hem liste donduruldu, böylece bir girdiyi başkasıyla değiştirmek
yenisini gizleyemez. Davranışsal bir test bunu destekler; çünkü bağımlılık enjeksiyonunun korumayı
gizlediği her yerde metin taraması bayatlar.

Secret taraması iki derinlikte yapılır: çalışma ağacında ve işlenmiş geçmişte — böylece bir zamanlar
commit'lenip sonra silinmiş bir kimlik bilgisi hâlâ push'u engeller. Tedarik zinciri kod olarak
politikadır: sabitlenmiş lockfile biçimi, yalnızca registry üzerinden çözümleme, kurulum script'i
çalıştırmasına izin verilen paketler için bir izin listesi, tam commit özetine sabitlenmiş üçüncü taraf
CI aksiyonları, her workflow'da açık izin tanımı ve güvenilmeyen girdinin kabuk komutlarına
enterpolasyonunun yasak olması.

Bulgular kabul edilmez veya düşürülmez, triyaj edilir. İnceleme turları önceki bulguları yeniden
derecelendirir, her birinin birincil atfını koda karşı kontrol eder ve çürütülen bulguları silmek
yerine karşı kanıtıyla birlikte düzeltme olarak yazar. İnceleme bütçesi biten bir alan "yapılmadı"
diye kaydedilir, asla "temiz" diye anlatılmaz.

---

## 8. Sürüm ve dağıtım

Sürüm artefaktı, dışlama listesiyle değil açık bir izin listesiyle derlenir, bir hazırlık dizinine
alınır ve aynı dışlamaları yeniden uygulamak için ikinci kez gezilir. Çıktıya bir checksum ve içine
neyin girdiğini, hangi kuralların uygulandığını kaydeden bir manifest eşlik eder.

Doğrulama, çalışma ağacını değil **çıkarılmış kopyayı** yeniden derleyip yeniden test eder. Doğrulayıcı
özeti kontrol eder, mutlak yolları ve dizin geçişini reddeden bir okuyucuyla açar ve ardından kurulum,
politika tarayıcıları, lint, build ve test süitlerini çalışma dizini çıkarılmış kopyanın içindeyken
koşar. Engellenmiş bir alt süreç, ortam engeli olarak raporlanır ve CI'da ölümcüldür; böylece kontrol
sessizce bir dosya listelemesine indirgenemez.

Dağıtım, halihazırda yayımlanmış bir artefaktı terfi ettirir; asla yenisini derlemez. Uzak script
checksum'ı doğrular, sürüme özel bir dizine açar, var olanın üzerine yazmayı reddeder, önce veriyi
yedekler, host üzerinde kurulumu yapar, çıkan sürümü kaydeder, canlı işaretçiyi çevirir, servisi
yeniden başlatır, sağlık uçlarını yoklar ve hata hâlinde otomatik geri alır. Hazırlık ucu gerçek bir
bağımlılık probudur — gerçek bir sorgu ve gerçek dosya sistemi kontrolleri — çünkü koşulsuz "sağlıklı"
dönen bir uç, bozuk bir örneği rotasyonda tutar.

Sürüm dokümantasyonu, yeşil bir test koşusunun üretim onayı ile aynı şey olmadığını açıkça söyler ve
onay için gerekenleri sayar: gerçek bir sağlayıcıya karşı canlı bir ödeme ve iade, yeniden üretilmiş
secret'lar ve yalnızca yapılandırılmış değil **geri yüklendiği kanıtlanmış** host dışı bir yedek.

---

## 9. Karanlıkta yayın ve ön koşul olarak uyum

Önemli özellikler kapalı yayınlanır. Operatörlere onları listeleyen tek bir küratörlü katalog vardır ve
bu kataloğun her bayrağa bakışı, tüketen kodun kendi semantiğini yansıtmak zorundadır — girdi başına o
kod işaret edilerek — aynı kontrolün daha gevşek bir kopyasını yeniden yazmak yerine.

Durum sözlüğünün üç değeri bilinçlidir. *Açık*, bir ön koşul sonradan bozulmuş olsa bile gerçekte neyin
çalıştığını doğru söyler. *Kapalı*, karanlık ve hazır demektir. *Engellendi*, karanlık ve karşılanmamış
bir ön koşul var demektir.

İşin ilginç yanı, neyin ön koşul sayıldığıdır. Makinece kontrol edilebilir olguların — bir anahtar
mevcut, bir sağlayıcı yapılandırılmış — yanında insani olanlar durur: bir aydınlatma metninin
onaylanıp yayımlanmış olması ya da bir deneyin ön kayda alınmış olması gibi. Bunlar, kontrolün makine
tarafından okunabilir kalması için aynı bayrak mekanizmasıyla beyan edilir. Sonuç şudur: hukuki veya
yöntemsel bir yükümlülük, yanındaki bir kontrol listesinde değil, **aktivasyon yolunun üzerinde**
durur. Bir kontrol ile iyi bir niyet arasındaki fark budur.

Kademeli yayın yüzdeleri, bayrak ve varlık üzerinden kararlı bir özetle kovalanır; böylece kısmi bir
yayın her değerlendirmede aynı varlıkları içerir, istek başına yeniden karılmaz. Her değerlendirme,
kararı veren kuralı adlandıran makine tarafından okunabilir bir gerekçe döner.

Dışa giden entegrasyonlar dayanıklı bir outbox ve bir worker üzerinden yürür; böylece kullanıcıya bakan
bir istek hiçbir zaman üçüncü tarafı beklemez. Idempotency, mantıksal olay üzerinde bir tekil
indekstir. Yeniden denemeler tavanlı geri çekilmeyle yapılır ve tükenmiş işler kaybolmak yerine
operatöre görünür açık bir "ölü" duruma geçer. Düzenleyici yükümlülük taşıyan entegrasyonlar kapalı
tarafa düşer ve birincil kaynağını modül başlığında belirtir: onay onaylar, ret **veya hiçbir kaydın
bulunmaması** engeller; çünkü kayıt yoksa eylem hukuka uygun değildir. Önbellekleri kesin cevap için
uzun, hata için kısa bir ömür kullanır; böylece bir kesinti izin verici tarafa değil,
engellendi-ama-hızlı-toparlanır tarafına bozulur.

---

## 10. Kanıt olarak dokümantasyon

Birinin üzerine iş yapabileceği belgeler her iddiayı ya doğrulanmış — onu üreten komutla birlikte — ya
da açık olarak işaretler. Üçüncü bir durum yoktur ve işaretsiz olan doğrulanmamış sayılır.

Ölçüm içeren her belge, ölçümün alındığı commit'i ve tarihi kaydeder ve sayıların bayatladığını söyler.
Bayat sayı taşıyan bir belge, okuyucuyu içindeki diğer her şeyi kontrol etmeye davet eder; ki bu,
belgenin yazılma amacının tam tersidir.

Karar kayıtları sabit bir şekle sahiptir: tarih, durum ve kararı tetikleyen bulguya geri bağlantı
içeren bir başlık; her gözlemin somut bir dosyayı veya ayarı işaret ettiği gözlem-kanıt tablosu
biçiminde bağlam; tek cümlelik karar; ardından işin "şimdi yapılacak" — her maddesi onu tutacak
kontrole bağlanmış — ve "adlandırılmış sayısal tetik geldiğinde yapılacak" diye ikiye ayrılması. Kapanış,
koddan türetilemeyen tek girdiyi adlandırıp onun için karar istemektir.

Denetim bulguları sabit kimlikler alır ve sonra dolaşır: aynı kimlik karar kaydında, düzeltmeyi zorlayan
kontrolde ve takip işinde görünür. Bir denetim ayrıca hangi kontrollerin gerçekten koşturulduğunu
kaydeder ve neyi kapsamadığını açıkça söyler.

Nedensellik iddiası taşıyan her şey, veri var olmadan önce ön kayda alınır — birincil metrik ve hipotez,
dışlamalar, durdurma kuralı ve hangi ikincil metriklerin manşet iddiada kullanılamayacağı — ve tasarım,
ön kayda alınan her kuralı onu zorlayan teste bağlayan bir tablo taşır. Simülasyon işleri, kapısı
"asla kullanılabilir bir sonuç üretmemek" olan bir boş kolun yanında, geçene kadar ayarlanmış değil
analitik olarak türetilmiş bir toleransa karşı kontrol edilen bilinen-gerçek kolunu koşar.

---

## 11. Çalışma disiplini

**Push ve merge ayrı yetkilerdir.** Yeşil bir kapı push'a yetki verir, merge'e değil. Değişiklikler
pull request olarak gelir ve kimlik doğrulama, yetkilendirme, kiracı izolasyonu, ödeme mantığı, imza
doğrulama veya göçlere dokunan diff'ler, onları yazmakta rol almamış biri tarafından incelenir.

**Kimse yazmadığı işi yeniden yazmaz.** Başkasına ait commit'lenmemiş iş olduğu gibi bırakılır; yerini
almış bir dal, toparlanmak yerine sahibinin kararını bekler.

**Başarısızlığın tanımlı bir durma noktası vardır.** Aynı alanda arka arkaya iki başarısız düzeltmeden
sonra düzenlemeyi bırak: hatayı yeniden üret, varsayımları ve tüm çağrı zincirini gözden geçir, doğru
nedenle düşen bir test yaz ve ancak ondan sonra kök nedeni gider. O düzeltme de tutmazsa üçüncü bir
yamaya kalkışma — düşen testi ve çalışma ağacını olduğu gibi bırak, iki denemeyi, hipotezi ve neden
tutmadığını yaz ve bunu bir karar olarak yukarı taşı. Yeşile doğru zorlamak, sonunda hangi düzeltmenin
gerçek olduğunu kimsenin bilmediği bir kod tabanı üretir.

**Geliştirme yalnızca yerel ortamlara ve CI'ya karşı yapılır.** Üretim veritabanlarına, host'larına veya
secret'larına bağlanılmaz ve aciliyeti ne olursa olsun üretime karşı serbest sorgu çalıştırılmaz.
Gerçek müşteri verisi hata ayıklamada asla kullanılmaz; üretimden bildirilen bir kusur, rapora benzer
şekilde üretilmiş sentetik veriyle yeniden üretilir. Gerçekten üretim erişimi gerektiren adımlar
hazırlanır ve devredilir, çalıştırılmaz.

**Geliştirme ortamı katlanılan değil, mühendisliği yapılan bir yüzeydir.** Build ve başlatma öncesinde
koşan bir ön kontrol script'i gerekli dosya ve dizinleri denetler ve doğal bağımlılıkları yüklendiğine
güvenmek yerine gerçekten çalıştırır. Bilinen platform arızaları kabile bilgisi yerine depoya işlenmiş
script'lerle karşılanır. Ağır işler üst üste binmez ve biri başlamadan önce mevcut boşluk kontrol
edilir.

---

## 12. Bu yöntemin vermediği şeyler

**Ratchet regresyonu durdurur, borcu ödemez.** Hiçbir kapı sana borcun fazla olduğunu söylemez;
yalnızca büyüdüğünü söyler. Azaltma bilinçli olarak planlanmalıdır ve planlanmadıysa olmaz.

**Bir kapı bir özelliği kanıtlar, sorunların yokluğunu değil.** Buradaki her kontrolün tanımlı bir
kapsamı vardır ve birçoğu kendi kör noktasını kendi dosyasında yazar. Yeşil bir koşu, ölçülen şeylerin
kötüleşmediği anlamına gelir.

**Beyan edilen yönetişim, uygulanan yönetişim değildir.** Zorunlu kontrolleri ve incelemeleri
tanımlayan bir manifest, hiçbiri barındırma platformunda zorlanmıyorken kendi içinde tutarlı
doğrulanabilir. İkisini zihinde ayrı tutmakta fayda var.

**Süreç, ikinci bir çift gözün yerine geçmez.** Hassas bir değişikliğin bağımsız incelemesi, bir şey
onu fiilen zorlamadığı sürece bir mekanizma değil bir taahhüttür. Küçük bir ekipte bu boşluk gerçektir
ve üstünü örtmek yerine adını koymak gerekir.

**Bazı tercihler yalnızca bu ölçekte doğrudur.** Metrik yığını işletmek yerine operasyonel görünürlüğü
sorgu zamanında hesaplamak, müşteri başına tek örnek için makul, elli örnek için kötü bir takastır.
Buradaki her mimari seçimin, doğru olmaktan çıktığı bir büyüklük vardır; işe yarayan kısım, oraya
vardığını sana hangi sayısal tetiğin söyleyeceğini bilmektir.
