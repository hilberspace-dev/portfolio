[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](METHODOLOGY.md)

# Güvenlik İncelemesi ve Kavram Kanıtı (PoC) Metodolojisi

Bu belge, bir kod tabanını denetlerken, kusuru kanıtlarken ve raporu inceleyen kişinin ek soru sormadan
harekete geçebileceği bir kanıt paketi hazırlarken kullandığım standardı tanımlar. Standart protokolden
bağımsızdır; bu yöntemi ortaya çıkaran ilk kapsamlı uygulama bir ERC-4337 EntryPoint incelemesiydi.

Bu belge bilinçli olarak genel teslim sürecimden daha dardır: saldırgan bakış açılı incelemeyi,
kusurun kanıtlanmasını ve değerlendirmeye hazır paketlenmesini anlatır. Bir değişikliğin production'a
nasıl çıktığı — gate merdiveni, ratchet'lenmiş debt baseline'ları, çalıştıran değil yakalayan
testler, release verification ve rollback — için
[Teslim ve Quality Gate Metodolojisi](DELIVERY-METHODOLOGY.tr.md) belgesine bakın.

**Temel ilke: iddiadan önce kanıt.** Bir bulgu, ancak çalışan bir kanıt saldırganın kontrol ettiği
girdiyi dürüst bir taraf üzerinde ölçülmüş etkisi olan ihlal edilmiş bir invariant'a bağlıyorsa, kök
neden kapsam içindeyse ve bulgu mükerrer değilse raporlanmaya değerdir.

---

## 0. Değişmez kurallar

1. **Çıktısını okumadığın bir komutun başarılı olduğunu asla söyleme.** Komutu saran aracın exit
   code'unun 0 olması, alttaki aracın gerçekten başarılı olduğu anlamına gelmez. stdout/stderr'i ve gerçek
   exit code'unu oku. Gerçek bir örnekte test komutu 0 döndüğü hâlde test runner hiç başlamamıştı.
2. **Bulgu üretmeye çalışma.** Yoğun biçimde denetlenmiş bir kod tabanında doğru ve beklenen sonuç,
   hiçbir gerçek bulgunun çıkmaması olabilir. Sıfır gerçek bulgu, kulağa makul gelen yirmi yanlış
   bulgudan iyidir.
3. **Kendi abartılı iddianı açıkça düzelt.** Sonraki analiz önceki iddiayı zayıflatıyorsa, bunu
   raporu inceleyen kişi fark etmeden önce söyle ve iddiayı daralt.
4. **Göndermeden önce ifşa etme.** Herkese açık issue açma, public remote'a push yapma veya kanıt
   dosyalarını yayımlama. Bulgular doğru bildirim kanalından gönderilene kadar yerelde kalır.
5. **Tekrar üretilebilirlik de kanıtlanması gereken bir iddiadır.** Commit'i, toolchain'i ve harici
   istemcileri değişmez kimlikleriyle sabitle; örneğin değişken tag yerine image digest kullan.
   Kendin tekrar üretemiyorsan bu iddiayı kurma.

## 1. Ortam ve başlangıç durumu

Kapsam commit'ini sabitle ve `git rev-parse HEAD` çıktısının onunla eşleştiğini doğrula. Projenin CI
toolchain'ini kullan: CI ayarlarında sabitlenen runtime'ı bul, aynı ortamı yerelde kur ve gerçekte
hangi sürümlerin çözüldüğünü kontrol et (`node --version`, `which node`, derleyici sürümü ve
konfigürasyondaki EVM hedefi). Bağımlılıkları kur, derle ve **çıktıyı oku**: “N dosya başarıyla
derlendi” mesajını ve derleme çıktılarının gerçekten oluştuğunu doğrula.

Başlangıç test sonucunu değiştirmeden kaydet: tam komut, toplam/geçen/başarısız/atlanmış test sayıları ve
exit code. **Her hatayı şu üç sınıftan birine yerleştir ve sınıflandırmayı kanıtla:** (a) gerçek kusur,
(b) host/işletim sistemi kaynaklı sorun veya (c) eksik bağımlılık. Yeni eklenen testin geçmesinin
anlamlı olabilmesi için yeterince temiz bir başlangıç sonucu gerekir.

Çalıştırma ortamının sınırını bil. Yerel simülatörler çoğu zaman daha eski bir hardfork'ta kalır ve
yeni semantiği çalıştıramaz. Bu sınırı kanıtın ortasında keşfetmek yerine baştan kaydet.

## 2. Önce bilinen/mükerrer bulgu duvarını kur

“Reponun denetim PDF'lerinde yok” demek, bulgunun yeni olduğunu kanıtlamaz. Bilinen konuları şu
kaynakların tamamından çıkar: bütün denetim raporları, bilinçli tasarım kararlarını anlatan kod
yorumları, mevcut testler (bir davranışı özellikle doğrulayan test, o davranışın amaçlandığını
gösterir), upstream issue ve pull request'ler, sürüm notları, protokol şartnamesi ve herkese açık
ifşalar.

İki ayrı liste tut: **bilinen ve hâlâ mevcut konular** (mükerrerlik riski en yüksek olanlar; yeni
görünürler ama değildirler) ve **hata gibi görünen tasarım kararları** (yanlış pozitif üreten
durumlar). Sonraki her analizde iki listeyi de kullan.

Yenilik iddiasını daima şu sınırla kur: *“Herkese açık kaynaklarda aynı bulguya veya önceki çalışmaya
rastlanmadı. Özel raporlar gözlemlenemiyor.”* Bir bulgunun kesinlikle mükerrer olmadığını söyleme.

## 3. Doğru cevabın ölçütü invariant şartnamesidir

Kapsamdaki her dosyayı bütünüyle oku, ardından güvenlik invariant'larını yaz: saldırganın varlık çalmak
veya sistemi çalışamaz hâle getirmek için bozması gereken koşullar. Sık rastlanan sınıflar şunlardır:
ödeme gücü ve varlıkların korunumu, ödeme tutarlarının korunumu, tekrar oynatma/benzersizlik, kaynak
muhasebesi, işlemler arası yalıtım, elle yazılmış assembly'de bellek güvenliği, doğrulama ile
çalıştırmanın ayrılması ve reentrancy kapsamı.

Her invariant için bir kimlik, biçimsel koşul, koşulu uygulayan tam `dosya:satır` konumu, varsayımlar
ve tehdit modeli altında kırılabileceği en olası yolu kaydet. Bu kırılma hipotezleri, incelemenin
hedefidir; bu adım olmadan yapılan kod okuması yönsüzdür.

## 4. Saldırgan bakış açılı inceleme

Her seferinde tek bir saldırı yüzeyine odaklan; tehdit modelini, invariant şartnamesini ve bilinen
konular listesini önünde tut. Kod parçaları yerine gerçek kaynak dosyaları oku, assembly'yi kelime
kelime simüle et, gas/değer/offset hesaplarını somut sayılarla yap ve `unchecked` aritmetiği
taşırabilecek erişilebilir girdiyi bul. Bir turdan sonuç çıkmaması geçerli bir sonuçtur.

Ayakta kalan her adayı, birbirinden bağımsız en az üç şüpheci açıdan sorgula ve çoğunluğa dayanmadan,
yalnızca kanıtla doğrulananları koru:

- **Çürütme:** Kontrol akışını kaynaktan yeniden çıkar; hipotezi engelleyen guard'ı, tür sınırını
  veya daha erken revert'i bul.
- **Mükerrerlik / niyet:** Adayı bilinen konular listesiyle, kod yorumlarıyla, testlerle ve
  şartnameyle karşılaştır.
- **Etki:** Gerçekte kimin parası veya erişilebilirliği etkileniyor ve ne kadar? Sonuç yalnızca
  saldırganın kendisine zarar vermesi mi? Mağdurun zaten bozuk veya kötü niyetli olması mı gerekiyor?

Belirsiz durumda varsayılan karar “çürütüldü” olmalıdır. Oy sayısı tek başına hiçbir şeyi kanıtlamaz;
yalnızca kapsam içindeki kök nedeni ve ölçülmüş etkiyi gösteren çalışan kanıt değerlidir. Turun
sonunda kapsam eleştirisi yap: hangi saldırı yüzeyi, invariant veya saldırgan rolü yeterince
incelenmedi? Sonraki tur buradan başlar.

Uzun bir incelemenin baştan yapılmak yerine kaldığı yerden sürdürülebilmesi için ara sonuçları
düzenli olarak diske kaydet.

## 5. Beş halkalı zorunlu kanıt zinciri

Bir adayı yalnızca aşağıdaki beş koşulun tamamı sağlanıyorsa raporla. Halkalardan biri eksikse adayı
ele.

1. **Saldırganın kontrol ettiği girdi:** Saldırganın belirlediği tam byte'lar, alanlar veya değerler.
2. **Erişilebilir yol:** Her adım için `dosya:satır` verilen somut çağrı zinciri ve hiçbir önceki
   require/revert'in yolu neden kapatmadığı.
3. **İhlal edilen invariant:** Şartnamedeki kimliğine bağlanan kesin koşul.
4. **Ölçülmüş etki:** Çalınan değer, kaybedilen gas, yetkisiz çalıştırma sayısı veya doğrulanabilir
   DoS maliyeti. “Kötü olabilir” yeterli değildir.
5. **Tekrar üretilebilir kanıt:** Kapsam commit'indeki gerçek sözleşmelere karşı çalışan test.

Şunlar açıkça reddedilir: gas/stil optimizasyonları, merkeziyetçilik veya yönetici riski, somut
exploit olmadan “sıfır adres kontrolü eksik” iddiası, erişilemeyen teorik overflow ve mağdurun zaten
kötü niyetli ya da bozuk olmasını gerektiren her durum.

## 6. Güvenilmeyen bileşenler için kapsam kapısı

Birçok protokolde bazı bileşenler güven sınırının dışında kalır. **Saldırganın bu tür kötü niyetli
bir sözleşmeyi kendisinin deploy etmesi geçerli bir saldırı aracıdır**; bu durum tek başına bulguyu
kapsam dışına çıkarmaz. Kusur, kapsam içindeki çekirdek kodun bu güvenilmeyen davranışı yanlış ele
almasından kaynaklanmalıdır.

Yalnızca şu durumlarda adayı reddet: kök neden bütünüyle harici bileşenin kendi kodundaysa; saldırı
dürüst bir karşı tarafın standarda aykırı davranmasını gerektiriyorsa; standartlara uygun bir simülasyon
zaten işlemi reddedecekse; sonuç yalnızca saldırganın kendisine zarar veriyorsa veya dürüst bir
işlem, yatırılmış varlık, invariant ya da erişilebilirlik özelliği etkilenmiyorsa.

**Aşamaları karıştırma:** Doğrulama aşamasının kuralları, execution veya callback aşamalarına
otomatik olarak uygulanmaz. Execution aşamasındaki saldırıyı doğrulama kurallarına uymadığı
gerekçesiyle doğrudan eleme.

## 7. Proof-of-concept kuralları

- **Kök neden kapsam içinde olmalı.** Hangi klasörlerin kapsamda olduğunu kesinleştir. Arayüz ve
  dokümantasyon dosyaları referans olarak kullanılabilir ancak “yalnızca referans, kapsam dışı” diye
  işaretlenir.
- **Gerçek akışı kolaylaştıran mock kullanma.** Saldırgan sözleşmesi özel olabilir ancak test gerçek
  entry point'i, gerçek muhasebeyi ve gerçek revert/callback davranışını çalıştırmalıdır. Durum
  enjekte eden yardımcılar yalnızca saldırganın kontrol ettiği state'i yerleştirmek veya kapsam
  içindeki dala ulaşmak için kullanılabilir; çekirdeğin kendi mantığını kısaltmak için kullanılamaz.
  Böyle bir yardımcı kullanılıyorsa test dosyasının başında açıkça belirtilmelidir.
- **Negatif kontrol zorunludur.** Saldırgan girdisi kaldırıldığında etkinin de kaybolduğunu doğrula;
  böylece sonucun test düzeneğinden değil, iddia edilen kök nedenden geldiğini göster.
- **Invariant'ı somut biçimde doğrula:** testin düzeltilmiş kodda başarısız, zafiyetli kodda başarılı
  olacağı şekilde önce/sonra bakiyeleri, çalıştırma sayısını veya hatalı alanın tam değerini denetle.
- **Projenin kendi test yardımcılarını kullan.** Yenilerini yazmadan önce mevcut testleri incele.
- Kanıtı önce **tek başına**, ardından mevcut test paketiyle birlikte çalıştır; kanıtın önceden var olan
  hataların arkasına saklanmasına izin verme.

## 8. Çalıştırma semantiğinde titizlik

Yerel simülatörde geçen test, gerçek istemci davranışını tek başına kanıtlamaz. Belirli bir
hardfork'un execution semantiğine veya istemciye özgü davranışa bağlı her durum, doğru hardfork'taki
gerçek istemcide tekrar üretilmelidir. Yerel ağ, özelliği çalıştıramıyorsa kontrol akışındaki kusuru
gösteren bir *yaklaşım* kullanılabilir; ancak bunun yaklaşık kanıt olduğu açıkça yazılmalı ve gerçek
istemcide ikinci bir kanıt hazırlanmalıdır.

Harici istemcileri tag ile değil **digest ile** sabitle; image adını, digest'i, istemci sürümünü ve commit'i,
chain konfigürasyonunu ve tam çalıştırma komutunu kaydet. İstemciye erişilemediğinde test kendini
atlıyorsa, atlanmış sonuç **kanıt değildir**; başarılı tekrar üretim beklenen test sayısının geçtiğini
göstermelidir.

## 9. Rapor paketi

Sıralama şöyledir: Başlık; Özet; Şiddet; Etkilenen commit ve kapsam içindeki dosyalar (destek
dosyaları açıkça kapsam dışı işaretli); Hatalı kod ve varsa doğru paralel yol ile kök neden; Beklenen
ve gerçekleşen davranış; Gözlenebilir kusur; Protokol düzeyinde etki (birincil etki kapsam içindeki
doğruluk veya varlık kusurudur; ikincil etkiler kesinlik değil olasılık belirten dille yazılır);
Erişilebilirlik ve dürüst sınırlamalar; Ortam sabitleme; Üretim kodunda değişiklik olmadığının kanıtı;
Doğru dosya konumlarıyla tekrar üretme adımları; Tam komutlar ve değiştirilmemiş çıktı; Negatif
kontrol; Kaynaklar; Mükerrer bulgu araması; Somut düzeltme önerisi.

**Üretim kodu diff kanıtı:** PoC yalnızca test dosyaları eklemelidir. Kapsam içindeki klasörlerde
`git diff` çıktısının boş olduğunu göster ve her dosyanın SHA-256 değerini kaydet. **Her düzenlemeden
sonra hash'leri yeniden hesapla**; eski hash kullanmak ciddi bir güven sorunudur.

**Şiddet değerlendirmesi, testin geçip geçmemesinden ayrıdır.** Geçen test yalnızca davranışın var
olduğunu kanıtlar. High şiddet için ayrıca dürüst bir mağdurun varlığı, gerçek ekonomik kayıp
veya yetkisiz çalıştırma, saldırgan maliyeti, ölçeklenebilirlik, mevcut önlemler ve etkinin tek işlemle
sınırlı mı yoksa tekrarlanabilir mi olduğu gösterilmelidir. **Savunulabilir bir Low, tartışmalı bir Medium'dan
iyidir.**

## 10. Paketleme disiplini

Sağlam bir bulguyu daha büyük bir bulgu beklentisiyle elde tutma; sonraki çalışmaları yeni ve mükerrer raporlar
olarak değil, mevcut başlığa ek bilgi olarak gönder. Arşivde repo içindeki dizin yapısını aynen koru;
dosyaları düzleştirmek relative import'ları bozar ve inceleyen kişiye gerçekte olmayan derleme
hataları gösterir. Tüm repoyu, bağımlılık klasörlerini, sürüm kontrolü metadata'sını, anahtarları,
token'ları veya gizli seed değerlerini pakete koyma. Rapor tek başına okunabilir olmalı; arşiv, açık anlatımın
yerine geçen bir dosya yığını değil, eksiksiz kanıt paketidir.
