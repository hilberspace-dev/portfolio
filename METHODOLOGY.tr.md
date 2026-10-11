[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](METHODOLOGY.md)

# Güvenlik incelemesi ve kavram kanıtı (PoC) metodolojisi

Bir kod tabanını denetlerken, bir kusuru kanıtlarken ve bulguyu, inceleyen kişinin ek soru sormadan
işleme alabileceği bir pakete dönüştürürken uyduğum kanıt standardı budur. Yöntem bir ERC-4337
EntryPoint incelemesinden çıktı, ama içinde o protokole özgü bir şey yok.

Kapsam, genel teslim sürecimden daha dar: saldırgan gözüyle inceleme, kusuru kanıtlama ve raporu
değerlendirmeye hazır hâle getirme. Bir değişikliğin production'a nasıl çıktığını (gate
merdiveni, ratchet'lenmiş debt baseline'ları, ne yakaladıklarına göre değerlendirilen testler, release
verification ve rollback) [teslim ve quality gate metodolojisi](DELIVERY-METHODOLOGY.tr.md) anlatıyor.

Hepsinin altındaki kural şu: önce kanıt, sonra iddia. Bir bulguyu ancak çalışan bir kanıt,
saldırganın kontrol ettiği bir girdiyi dürüst bir taraf üzerindeki etkisi ölçülmüş bir invariant
ihlaline bağlıyorsa raporlarım. Kök nedenin kapsam içinde olması ve bulgunun mükerrer olmaması da
şarttır.

## 0. Temel kurallar

1. Bir komutun başarılı olduğuna, çıktısı okunmadan karar verilmez. Komutu saran aracın 0 exit
   code'u döndürmesi, alttaki aracın geçtiğini göstermez; stdout, stderr ve gerçek exit code okunur.
   Bu gerçekten yaşandı: bir test komutu 0 döndürdü, oysa test runner hiç başlamamıştı.
2. Bulgu uydurulmaz. Yoğun biçimde denetlenmiş bir kod tabanında boş sonuç, doğru ve beklenen
   sonuçtur. Sıfır gerçek bulgu, kulağa makul gelen ama yanlış olan yirmi bulgudan iyidir.
3. Abartılı bir iddia açıkça düzeltilir. Sonraki analiz önceki bir iddiayı zayıflatıyorsa iddia
   gönderimden önce daraltılır ve bu değişiklik yazılır; bunu raporu inceleyen kişi bulmamalı.
4. Göndermeden önce hiçbir şey ifşa edilmez. Herkese açık issue açılmaz, public remote'a push
   yapılmaz, kanıt dosyası yayımlanmaz. Bulgular doğru kanaldan gönderilene kadar yerelde kalır.
5. Tekrar üretilebilirlik de bir iddiadır ve kanıt ister. Commit, toolchain ve harici istemciler
   değişmez kimlikleriyle sabitlenir (istemci image'ı için bu kimlik digest'tir; tag değişebilir).
   Tekrar üretilemeyen bir şey iddia edilmez.

## 1. Önce ortamı ve başlangıç durumunu hazırla

Kapsam commit'ini sabitle ve `git rev-parse HEAD` çıktısının onunla eşleştiğini kontrol et. Projenin
CI'da kullandığı toolchain'i kullan: CI ayarlarında sabitlenmiş runtime'ı bul, yerelde aynısını kur ve
gerçekte hangi sürümlerin çözüldüğüne bak (`node --version`, `which node`, derleyici sürümü ve
konfigürasyondaki EVM hedefi). Sonra bağımlılıkları kur, derle ve çıktıyı oku. Çıktıda "N dosya
başarıyla derlendi" mesajı olmalı, derleme çıktıları da gerçekten oluşmuş olmalı.

Başlangıç test sonucunu olduğu gibi kaydet: tam komut, toplam/geçen/başarısız/atlanmış test sayıları
ve exit code. Her hatayı üç gruptan birine koy ve hangisine ait olduğunu kanıtla: (a) gerçek kusur,
(b) host ya da işletim sistemi kaynaklı sorun, (c) eksik bağımlılık. Başlangıç sonucu yeterince temiz
değilse yeni bir testin geçmesi hiçbir şey ifade etmez.

Çalıştırma ortamının sınırını bil. Yerel simülatörler çoğu zaman eski bir hardfork'ta kalır ve yeni
semantiği çalıştıramaz. Bu sınırı en başta yaz ki kanıtın ortasında karşına çıkmasın.

## 2. Önce bilinen/mükerrer bulgu duvarını kur

Reponun denetim PDF'lerinde geçmeyen bir bulgu yine de biliniyor olabilir. Bilinen konular listesini
şu kaynakların hepsinden çıkar: bütün denetim raporları, bilinçli tasarım kararlarını anlatan kod
yorumları, mevcut testler (bir davranışı assert eden test, o davranışın kasıtlı olduğunu gösterir),
upstream issue'lar *ve* pull request'ler, sürüm notları, protokol şartnamesi ve herkese açık ifşalar.

İki ayrı liste tut. Birincisi *bilinen ve hâlâ duran konular*. Yeni gibi görünüp yeni olmadıkları için
mükerrerlik riski en yüksek olanlar bunlardır. İkincisi *hata gibi görünen tasarım kararları*; yanlış
pozitifler buradan çıkar. Sonraki her analize iki liste de girer.

Yenilik ifadesi her zaman şöyledir: *"Herkese açık kaynaklarda aynı bulguya veya önceki çalışmaya
rastlanmadı. Özel raporlar gözlemlenemiyor."* Bir bulgunun mükerrer olmadığını kesin bir dille söyleme.

## 3. Doğru cevabın ölçütü invariant şartnamesidir

Kapsamdaki her dosyayı baştan sona oku, sonra güvenlik invariant'larını yaz: saldırganın varlık çalmak
ya da sistemi işlemez hâle getirmek için bozması gereken koşullar. Sık görülen sınıflar şunlar: ödeme
gücü ve varlıkların korunumu, ödeme tutarlarının korunumu, tekrar oynatma/benzersizlik, kaynak
muhasebesi, işlemler arası yalıtım, elle yazılmış assembly'de bellek güvenliği, doğrulama ile
çalıştırmanın ayrılması ve reentrancy kapsamı.

Her invariant için bir kimlik, biçimsel koşul, onu uygulayan kodun tam `dosya:satır` konumu,
varsayımlar ve tehdit modeli altında kırılabileceği en olası yol kaydedilir. Bu kırılma hipotezleri
avın hedefidir. Bu adım atlanırsa geriye yönsüz bir kod okuması kalır.

## 4. Saldırgan gözüyle inceleme

İnceleme her seferinde tek bir saldırı yüzeyine bakar; tehdit modeli, invariant şartnamesi ve
bilinen konular listesi el altındadır. Kod parçalarıyla yetinilmez, gerçek kaynak dosyalar okunur.
Assembly kelime kelime simüle edilir, gas/değer/offset hesapları somut sayılarla yapılır ve
`unchecked` aritmetiği taşırabilecek erişilebilir girdi aranır. Hiçbir şey çıkmayan bir yüzey de
geçerli bir sonuçtur.

Buradan çıkan her aday ardından üç şüpheci açıdan sınanır:

- Çürütülebilir mi? Kontrol akışı kaynaktan yeniden çıkarılır; adayı engelleyen guard, tür sınırı
  veya daha erken bir revert aranır.
- Zaten biliniyor mu, ya da kasıtlı mı? Aday bilinen konular listesiyle, kod yorumlarıyla, testlerle
  ve şartnameyle karşılaştırılır.
- Etkisi ne? Gerçekte kimin parası ya da erişilebilirliği etkileniyor, ne kadar? Saldırgan yalnızca
  kendine mi zarar veriyor? Mağdurun zaten bozuk olması mı gerekiyor?

Hâlâ şüpheli olan aday çürütülmüş sayılır. Bu sınamalardan geçmek tek başına hiçbir şey kanıtlamaz;
bunu ancak kök nedeni kapsam içinde olan ve etkisi ölçülmüş çalışan bir kanıt yapar. Her tur kapsama
bir kez daha bakılarak biter: hangi saldırı yüzeyi, invariant ya da saldırgan rolü yeterince
incelenmedi? Sonraki tur oradan başlar.

Notlar ve ara sonuçlar inceleme boyunca dosyalara yazılır.

## 5. Beş halkalı kanıt zinciri

Bir aday ancak beş halkanın beşi de sağlanıyorsa raporlanır. Biri bile eksikse aday elenir.

1. Saldırganın kontrol ettiği girdi, tam olarak: saldırganın belirlediği byte'lar, alanlar veya
   değerler.
2. Erişilebilir bir yol, yani her adım için `dosya:satır` verilmiş somut çağrı zinciri ve daha önceki
   hiçbir require/revert'in bu yolu neden kapatmadığı.
3. İhlal edilen invariant; şartnamedeki kimliğine bağlanmış kesin bir koşul olarak yazılır.
4. Sayıyla ölçülmüş etki: çalınan değer, kaybedilen gas, yetkisiz çalıştırma sayısı veya
   doğrulanabilir bir DoS maliyeti. "Kötü olabilir" yetmez.
5. Tekrar üretilebilir kanıt, yani kapsam commit'indeki gerçek sözleşmelere karşı çalışan bir test.

Şunlar doğrudan reddedilir: gas/stil optimizasyonları, merkeziyetçilik veya yönetici riski, somut
exploit olmadan "sıfır adres kontrolü eksik" iddiası, erişilemeyen teorik overflow ve mağdurun zaten
kötü niyetli ya da bozuk olmasını gerektiren her durum.

## 6. Güvenilmeyen bileşenler için kapsam kapısı

Birçok protokolde bazı bileşenler güven sınırının dışında durur. Saldırganın bu türden kötü niyetli
bir sözleşmeyi kendisinin deploy etmesi geçerli bir saldırı aracıdır ve bu tek başına bulguyu kapsam
dışına çıkarmaz. Kusur, kapsam içindeki çekirdek kodun bu güvenilmeyen davranışı *yanlış ele
almasında* olmalıdır.

Adayı yalnızca şu durumlarda reddet: kök neden tamamen o bileşenin kendi kodundaysa; saldırı *dürüst*
bir karşı tarafın standarda aykırı davranmasını gerektiriyorsa; standarda uygun bir simülasyon işlemi
zaten reddedecekse; saldırgan yalnızca kendine zarar veriyorsa; ya da dürüst hiçbir işlem, yatırılmış
varlık, invariant veya erişilebilirlik özelliği etkilenmiyorsa.

Aşamaları ayrı tut. Doğrulama aşamasının kuralları execution ve callback aşamalarına uygulanmaz;
execution aşamasındaki bir saldırıyı doğrulama kurallarına uymuyor diye otomatik olarak eleme.

## 7. Proof-of-concept kuralları

- Kök neden kapsam içinde olmalı. Hangi klasörlerin kapsamda olduğunu kesinleştir. Arayüz ve
  dokümantasyon dosyalarına *referans* verilebilir, ama bunlar "yalnızca referans, kapsam dışı" diye
  işaretlenir.
- Gerçek akışı kolaylaştıran bir mock kullanılmaz. Saldırganın sözleşmesi özel yazılmış olabilir, ama
  test gerçek entry point'ten, gerçek muhasebeden ve gerçek revert/callback davranışından geçmelidir.
  Durum enjekte eden bir yardımcı *yalnızca* saldırganın kontrol ettiği state'i yerleştirmek veya
  kapsam içindeki dala ulaşmak için kullanılabilir (çekirdeğin kendi mantığını kısaltmak için asla) ve
  test dosyasının başında açıkça belirtilir.
- Negatif kontrol zorunludur. Saldırgan girdisi kaldırılınca etkinin de kaybolduğunu assert et;
  böylece etkinin test düzeneğinden gelmediği, iddia edilen kök nedenden geldiği kanıtlanır.
- Invariant'ı somut değerlerle doğrula (önce/sonra bakiyeleri, çalıştırma sayıları, hatalı alanın tam
  değeri). Test düzeltilmiş kodda düşmeli, zafiyetli kodda geçmelidir.
- Projenin kendi test yardımcılarını kullan. Önce mevcut testleri incele, aynılarını yeniden yazma.
- Kanıtı önce tek başına, sonra mevcut test paketiyle birlikte çalıştır. Böylece önceden var olan
  hataların arkasına saklanamaz.

## 8. Çalıştırma semantiğinde titizlik

Yerel simülatörde geçen bir test, gerçek bir istemcinin nasıl davrandığının kanıtı değildir. Belirli
bir hardfork'un execution semantiğine ya da tek bir istemciye özgü davranışa dayanan her şey, doğru
hardfork'taki gerçek bir istemcide tekrar üretilmelidir. Yerel ağ özelliği çalıştıramıyorsa kontrol
akışındaki kusuru gösteren bir *yaklaşık kanıt* kabul edilebilir. Yalnız bunun yaklaşık olduğu açıkça
yazılır ve gerçek bir istemcide ikinci bir kanıt hazırlanır.

Harici istemcileri digest ile sabitle, çünkü tag değişebilir. Image adını, digest'i, istemci sürümünü
ve commit'i, chain konfigürasyonunu ve tam çalıştırma komutunu kaydet. Bazı testler istemciye
erişemeyince kendini atlar ve atlanmış bir sonuç kanıt değildir. Başarılı bir tekrar üretim, beklenen
sayıda testin geçtiğini göstermelidir.

## 9. Rapor paketi

Rapor şu bölümlerden, bu sırayla oluşur: Başlık; Özet; Şiddet; Etkilenen commit ve kapsam içindeki
dosyalar (destek dosyaları açıkça kapsam dışı işaretli); Hatalı kod ve varsa doğru paralel yol ile kök
neden; Beklenen ve gerçekleşen davranış; Gözlenebilir kusur; Protokol düzeyinde etki (birincil etki
kapsam içindeki doğruluk veya varlık kusurudur; ikincil etkiler "-ebilir" diliyle yazılır, kesin bir
dille ileri sürülmez); Erişilebilirlik ve dürüst sınırlamalar; Ortam sabitleme; Üretim kodunda
değişiklik olmadığının kanıtı; Doğru dosya konumlarıyla tekrar üretme adımları; Tam komutlar ve
değiştirilmemiş çıktı; Negatif kontrol; Kaynaklar; Mükerrer bulgu araması; Somut düzeltme önerisi.

Üretim kodu diff kanıtında PoC yalnızca test dosyası ekler. Kapsam içindeki klasörlerde `git diff`
çıktısının boş olduğunu göster ve her dosyanın SHA-256 değerini kaydet. Her düzenlemeden sonra bütün
hash'leri yeniden hesapla; eski bir hash ciddi bir güven sorunudur.

Şiddet, testin geçip geçmemesinden ayrı değerlendirilir. Geçen bir test yalnızca davranışın var
olduğunu kanıtlar, fazlasını değil. High şiddet için ayrıca şunlar gösterilmelidir: dürüst bir mağdur,
gerçek ekonomik kayıp veya yetkisiz çalıştırma, saldırganın maliyeti, ölçeklenebilirlik, mevcut
önlemler ve etkinin tek bir işlemle mi sınırlı kaldığı, yoksa tekrarlanabilir mi olduğu. Savunulabilir
bir Low, tartışmalı bir Medium'dan iyidir.

## 10. Paketleme disiplini

Sağlam bir bulguyu, daha büyüğü çıkar diye bekletme; hazır olduğunda gönder. Sonraki çalışmaları
mevcut başlığa ek olarak gönder, aynı konuda ikinci bir rapor açma. Arşivde reponun dizin yapısını
aynen koru. Dosyaları düzleştirirsen relative import'lar bozulur ve inceleyen kişi aslında olmayan
derleme hataları görür. Tüm repoyu, bağımlılık klasörlerini, sürüm kontrolü metadata'sını,
anahtarları, token'ları veya gizli seed değerlerini pakete koyma. Rapor tek başına anlaşılır olmalı;
arşiv eksiksiz kanıtı taşır, ama açık bir anlatımın yerini tutmaz.
