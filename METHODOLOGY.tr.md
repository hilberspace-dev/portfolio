[![English version](https://img.shields.io/badge/Dil-English-1F6FEB?style=for-the-badge)](METHODOLOGY.md)

# Güvenlik incelemesi ve kavram kanıtı (PoC) metodolojisi

Saldırgan gözüyle inceleme yaparken uyduğum kanıt standardı bu: bir kod tabanını denetlediğimde, bir
kusuru kanıtladığımda ve bulguyu, inceleyen kişi ek soru sormadan işleme alabilsin diye
paketlediğimde. Yöntem bir ERC-4337 EntryPoint incelemesinden çıktı, ama içinde o protokole özgü bir
şey yok.

Kapsamı genel teslim sürecimden daha dar. Bir değişikliğin production'a nasıl çıktığını (gate
merdiveni, ratchet'lenmiş debt baseline'ları, ne yakaladıklarına göre değerlendirilen testler, release
verification ve rollback) [teslim ve quality gate metodolojisi](DELIVERY-METHODOLOGY.tr.md) anlatıyor.

Hepsinin altında tek bir kural var: önce kanıt, sonra iddia. Bir bulguyu ancak çalışan bir kanıt,
saldırganın kontrol ettiği bir girdiyi ihlal edilmiş bir invariant'a bağlıyorsa ve dürüst bir taraf
üzerindeki etkisi ölçülmüşse raporlarım. Kök neden de kapsam içinde olmalı; bulgu mükerrer olmamalı.

## 0. Temel kurallar

1. Bir komut ancak çıktısı başarılı olduğunu söylüyorsa başarılı sayılır. Komutu saran wrapper'ın 0
   exit code'u döndürmesi alttaki aracın ne yaptığını göstermez; stdout, stderr ve gerçek exit code
   okunur. Bu gerçekten yaşandı: bir test komutu 0 döndürdü, oysa test runner hiç başlamamıştı.
2. Bulgu uydurulmaz. Yoğun biçimde denetlenmiş bir kod tabanında boş sonuç doğrudur; beklenen de
   budur. Sıfır gerçek bulgu, kulağa makul gelen ama yanlış olan yirmi bulgudan iyidir.
3. Abartılı bir iddia açıkça düzeltilir. Sonraki analiz önceki bir iddiayı zayıflatırsa, iddiayı
   göndermeden önce daraltırım ve neyin değiştiğini yazarım. Bunu raporu inceleyen kişi bulmamalı.
4. Göndermeden önce hiçbir şey ifşa edilmez. Bulgular doğru kanaldan gönderilene kadar yerelde
   kalır. O zamana kadar ne herkese açık issue açılır ne de public remote'a push edilir. Kanıt
   dosyası yayımlamak da yasak.
5. Tekrar üretilebilirlik de bir iddiadır ve dayanak ister. Tam commit, toolchain ve harici
   istemciler değişmez kimlikleriyle sabitlenir. İstemci image'ı için bu kimlik digest'tir; tag
   değişebilir. Tekrar üretilemeyen bir şey iddia edilmez.

## 1. Önce ortamı ve başlangıç durumunu hazırla

Kapsam commit'ini sabitle ve `git rev-parse HEAD` çıktısının onunla eşleştiğini kontrol et. Sonra
projenin CI'da kullandığı toolchain'e geç: CI ayarlarında sabitlenmiş runtime'ı bulup yerelde
aynısını kur ve gerçekte neyin çözüldüğüne bak (`node --version`, `which node`, derleyici sürümü,
konfigürasyondaki EVM hedefi). Şimdi bağımlılıkları kurup derle ve çıktıyı oku. Çıktıda "N dosya
başarıyla derlendi" yazmalı, derleme çıktıları da gerçekten oluşmuş olmalı.

Başlangıç test sonucunu olduğu gibi kaydet: tam komut, toplam/geçen/başarısız/atlanmış test sayıları
ve exit code. Her hatayı üç gruptan birine koy ve hangisine ait olduğunu kanıtla: (a) gerçek kusur,
(b) host ya da işletim sistemi kaynaklı sorun, (c) eksik bağımlılık. Başlangıç sonucu yeterince
temiz değilse yeni bir testin geçmesi hiçbir şey ifade etmez.

Çalıştırma ortamının sınırını bil. Yerel simülatörler çoğu zaman eski bir hardfork'ta kalır ve yeni
semantiği çalıştıramaz. Bu sınırı en başta yaz ki kanıtın ortasında karşına çıkmasın.

## 2. Önce "zaten bilinenler" duvarını kur

Reponun denetim PDF'lerinde geçmeyen bir bulgu yine de biliniyor olabilir. Bilinen konular
listesine bütün denetim raporları ve bilinçli tasarım kararlarını anlatan kod yorumları girer.
Mevcut testler de girer (bir test bir davranışı assert ediyorsa o davranış kasıtlıdır); ardından
upstream issue'lar *ve* pull request'ler, sürüm notları, protokol şartnamesi ve herkese açık ifşalar
gelir.

İki ayrı liste tut. Birincisi *bilinen ve hâlâ duran konular*. Mükerrerlik riski en yüksek olanlar
bunlar: yeni gibi görünürler ama değildirler. İkincisi *hata gibi görünen tasarım kararları*; yanlış
pozitifler buradan çıkar. Sonraki her analize iki liste de girer.

Yenilik ifadesi her zaman şöyledir: *"Herkese açık kaynaklarda aynı bulguya veya önceki çalışmaya
rastlanmadı. Özel raporlar gözlemlenemiyor."* Bir bulgunun mükerrer olmadığını kesin bir dille söyleme.

## 3. Invariant şartnamesini yaz

Önce kapsamdaki her dosyayı baştan sona oku. Sonra güvenlik invariant'larını yaz: saldırganın varlık
çalmak ya da sistemi işlemez hâle getirmek için bozması gereken koşullar. Sık görülen sınıflar şunlar:
ödeme gücü ve varlıkların korunumu, ödeme tutarlarının korunumu, tekrar oynatma/benzersizlik, kaynak
muhasebesi, işlemler arası yalıtım, elle yazılmış assembly'de bellek güvenliği, doğrulama ile
çalıştırmanın ayrılması ve reentrancy kapsamı.

Her invariant'ın bir kimliği ve biçimsel koşulu olur. Onu uygulayan kodun tam `dosya:satır` konumu da
yazılır; varsayımları da, tehdit modeli altında kırılabileceği en olası yol da. Aradığın şey bu
kırılma hipotezleri. Onlar olmadan av, yönsüz bir kod okumasından ibaret kalır.

## 4. Saldırgan gözüyle inceleme

Her seferinde tek bir saldırı yüzeyine bakarım; tehdit modeli, invariant şartnamesi ve bilinen
konular listesi el altındadır. Kod parçalarıyla yetinmem, gerçek kaynak dosyaları okurum. Assembly
kelime kelime simüle edilir, gas, değer ve offset hesapları somut sayılarla yapılır; `unchecked`
aritmetiği taşırabilecek erişilebilir girdi de aranır. Hiçbir şey çıkmayan bir yüzey de geçerli bir
sonuçtur.

Buradan çıkan her aday ardından üç şüpheci soruyla sınanır:

- Çürütülebilir mi? Kontrol akışını kaynaktan yeniden çıkar; adayı engelleyen guard'ı, tür sınırını
  veya daha erken bir revert'i ara.
- Zaten biliniyor mu, ya da kasıtlı mı? Adayı bilinen konular listesiyle, kod yorumlarıyla,
  testlerle ve şartnameyle karşılaştır.
- Etkisi ne? Gerçekte kimin parası ya da erişilebilirliği etkileniyor, ne kadar? Saldırgan yalnızca
  kendine mi zarar veriyor? Mağdurun zaten bozuk olması mı gerekiyor?

Hâlâ şüpheli olan aday çürütülmüş sayılır. Bu sınamalardan geçmek de tek başına hiçbir şey
kanıtlamaz; bunu ancak kök nedeni kapsam içinde olan ve etkisi ölçülmüş, çalışan bir kanıt gösterir.
Her tur kapsama bir kez daha bakılarak biter. Hangi saldırı yüzeyi, invariant ya da saldırgan rolü
yeterince incelenmedi? Sonraki tur oradan başlar.

## 5. Beş halkalı kanıt zinciri

Bir aday ancak beş halkanın beşi de sağlanıyorsa raporlanır. Tek halka eksikse elenir.

1. Saldırganın kontrol ettiği girdi, tam olarak: saldırganın belirlediği byte'lar, alanlar veya
   değerler.
2. Erişilebilir bir yol: her adım için `dosya:satır` verilmiş somut çağrı zinciri ve daha önceki
   hiçbir require/revert'in bu yolu neden kapatmadığı.
3. İhlal edilen invariant; şartnamedeki kimliğine bağlanmış kesin bir koşul olarak yazılır.
4. Sayıyla ölçülmüş etki: çalınan değer, kaybedilen gas, yetkisiz çalıştırma sayısı veya
   doğrulanabilir bir DoS maliyeti. "Kötü olabilir" yetmez.
5. Tekrar üretilebilir kanıt, yani kapsam commit'indeki gerçek sözleşmelere karşı çalışan bir test.

Bazı şeyler doğrudan reddedilir: gas/stil optimizasyonları, merkeziyetçilik veya yönetici riski, somut
exploit olmadan "sıfır adres kontrolü eksik" iddiası, erişilemeyen teorik overflow. Mağdurun zaten
kötü niyetli ya da bozuk olmasını gerektiren her durum da öyle.

## 6. Güvenilmeyen bileşenler için kapsam kapısı

Birçok protokolde bazı bileşenler güven sınırının dışında durur. Diyelim ki saldırgan bu türden kötü
niyetli bir sözleşmeyi kendisi deploy etti: bu geçerli bir saldırı aracıdır ve tek başına bulguyu
kapsam dışına çıkarmaz. Ama kusur, kapsam içindeki çekirdek kodun bu güvenilmeyen davranışı *yanlış
ele almasında* olmalı.

Adayı yalnızca şu durumlardan birinde reddet:

- kök neden tamamen o bileşenin kendi kodundaysa;
- saldırı, *dürüst* bir karşı tarafın standarda aykırı davranmasını gerektiriyorsa;
- standarda uygun bir simülasyon işlemi zaten reddedecekse;
- saldırgan yalnızca kendine zarar veriyorsa;
- dürüst hiçbir işlem, yatırılmış varlık, invariant veya erişilebilirlik özelliği etkilenmiyorsa.

Aşamaları ayrı tut. Doğrulama aşamasının kuralları execution ve callback aşamalarına uygulanmaz.
Execution aşamasındaki bir saldırıyı, doğrulama kurallarına uymuyor diye otomatik olarak eleme.

## 7. Proof-of-concept kuralları

- Kök neden kapsam içinde olmalı; hangi klasörlerin kapsamda olduğunu kesinleştir. Arayüz ve
  dokümantasyon dosyalarına *referans* verilebilir, ama bunlar "yalnızca referans, kapsam dışı" diye
  işaretlenir.
- Gerçek akışı kolaylaştıran bir mock kullanılmaz. Saldırganın sözleşmesi özel yazılmış olabilir,
  ama testin içinden geçtiği her şey gerçek olmalı: entry point, muhasebe, revert/callback davranışı.
  Durum enjekte eden bir yardımcı *yalnızca* saldırganın kontrol ettiği state'i yerleştirmek ya da
  kapsam içindeki dala ulaşmak için kullanılabilir; çekirdeğin kendi mantığını kısaltmak için asla.
  Test dosyasının başı bunu açıkça belirtmeli.
- Negatif kontrol zorunlu. Saldırgan girdisini kaldır ve etkinin de kaybolduğunu assert et. Bu,
  etkinin iddia edilen kök nedenden geldiğini ve test düzeneğinden kaynaklanmadığını kanıtlar.
- Invariant'ı somut değerlerle doğrula: önce/sonra bakiyeleri, çalıştırma sayıları, hatalı alanın
  tam değeri. Test düzeltilmiş kodda düşmeli, zafiyetli kodda geçmeli.
- Projenin kendi test yardımcılarını kullan. Önce mevcut testleri incele, aynılarını yeniden yazma.
- Pakette zaten düşen testler yeni bir sonucu gölgeleyebilir. Kanıtı önce tek başına çalıştır,
  mevcut test paketiyle birlikte ancak ondan sonra.

## 8. Gerçek istemcide çalıştırma semantiği

Yerel simülatörde geçen bir test, gerçek bir istemcinin nasıl davrandığını kanıtlamaz. Sonuç belirli
bir hardfork'un execution semantiğine ya da tek bir istemciye özgü bir davranışa dayanıyorsa, doğru
hardfork'taki gerçek bir istemcide tekrar üret. Yerel ağ o özelliği hiç çalıştıramıyorsa, kontrol
akışındaki kusuru gösteren bir *yaklaşık kanıt* kabul edilebilir; yeter ki yaklaşık olduğu açıkça
yazılsın ve gerçek bir istemcide ikinci bir kanıt hazırlansın.

Harici istemcileri digest ile sabitle, çünkü tag değişebilir. Image adını, digest'i, istemci
sürümünü ve commit'i kaydet; chain konfigürasyonunu ve tam çalıştırma komutunu da. Bazı testler
istemciye erişemeyince kendini atlar. Atlanmış bir sonuç kanıt değildir. Başarılı bir tekrar üretim,
beklenen sayıda testin geçtiğini göstermeli.

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
olduğunu kanıtlar, o kadar. High şiddet iddiası bundan fazlasını göstermeli. Dürüst bir mağdur var
mı? Gerçek ekonomik kayıp ya da yetkisiz çalıştırma var mı? Saldırgana maliyeti ne, ölçekleniyor mu?
Hangi önlemler zaten var? Etki tek bir işlemle mi sınırlı, yoksa tekrarlanabilir mi? Savunulabilir
bir Low, tartışmalı bir Medium'dan iyidir.

## 10. Paketleme disiplini

Sağlam bir bulguyu, daha büyüğü çıkar diye bekletme; hazır olduğunda gönder. Sonraki çalışmalar
mevcut başlığa ek olarak gider, aynı konuda ikinci bir rapor açılmaz. Arşivde reponun dizin
yapısını aynen koru. Dosyaları düzleştirirsen relative import'lar bozulur ve inceleyen kişi aslında
olmayan derleme hataları görür. Tüm repoyu, bağımlılık klasörlerini, sürüm kontrolü metadata'sını,
anahtarları, token'ları veya gizli seed değerlerini pakete koyma. Rapor tek başına anlaşılır
olmalı; arşiv eksiksiz kanıtı taşır, ama açık bir anlatımın yerini tutmaz.
