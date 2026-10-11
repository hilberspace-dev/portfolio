# Serhat Atılgan | Backend geliştirme

[English](README.md) · [GitHub](https://github.com/hilberspace-dev)

E-ticaret ve fintek ekipleri için Go, PostgreSQL ve TypeScript ile backend geliştiriyorum. İşlerimin
çoğu ödeme mutabakatı ve API entegrasyonu; mevcut uygulamaların bakımını da üstleniyorum. Türkiye'de
yaşıyorum, Türkçe ve İngilizce çalışıyorum.

## Ana proje: ReconPilot

ReconPilot, PSP raporlarını, banka ekstrelerini ve pazaryeri hakedişlerini içeri alan bir
Go/PostgreSQL uygulaması. Kesin, toleranslı ve grup eşleştirmesi yapıyor, geriye kalan kayıtları da
sınıflandırıyor. Bir girdiyi hesap dışında bırakan ya da aynı işlemi birden fazla eşleşme grubuna
koyan bir sonuç, çalışma anındaki kontrollerden geçemiyor.

Açık depoda komut satırı aracı, HTTP servisi, HTML raporu, testler ve seed'li sentetik benchmark var.
Benchmark, eşleşmeleri veri üreticisinin amaçladığı gruplarla karşılaştırıyor; aşağıdaki doğrulama
paneli seed 1 için, yaklaşık 49 bin işlemlik koşunun sonucu:

[![ReconPilot doğrulama paneli: enjekte edilen 7 uyuşmazlık tipinin 7'si tespit edildi, 0 yanlış eşleşme, amaçlanan eşleşme ve gruplarda 0 kayıp](https://raw.githubusercontent.com/hilberspace-dev/reconpilot/main/docs/verification-panel-top.png)](https://github.com/hilberspace-dev/reconpilot)

Benchmark müşteri verisiyle hiç çalıştırılmadığı için oradaki doğruluk hakkında bir şey söylemiyor.
CI her push'ta aynı koşuyu GitHub'ın kendi makinelerinde tekrarlıyor. İddiayı hiçbir şey kurmadan siz
de kontrol edebilirsiniz: depo Codespaces'te benchmark çalışır hâlde açılıyor.

[Kaynak kod ve çalıştırma talimatları](https://github.com/hilberspace-dev/reconpilot) ·
[Vaka çalışması](projects/03-reconpilot-payment-reconciliation/README.tr.md)

## Destekleyici çalışmalar

Aşağıdaki iki alanı hizmet olarak satmıyorum. Burada olmalarının nedeni, yöntemin backend işlerimde
kullandığımla aynı olması: sabitlenmiş bir ortam ve yazılı bir iddia, bir de hayır diyebilen,
çalıştırılabilir bir kontrol.

### Güvenlik incelemeleri (Solidity)

- [ERC-4337 EntryPoint](projects/02-erc4337-entrypoint-review/README.tr.md):
  kendi değerlendirmemde düşük önem derecesi verdiğim bir doğruluk bulgusu; hem yerel ortamda hem
  ayrı bir istemcide tekrar üretim kayıtları var. Bakımcılarla 11 Ekim 2026'da iletişime geçildi
  ([issue #632](https://github.com/eth-infinitism/account-abstraction/issues/632)) ve tam rapor
  orada paylaşılacak; mekanizma ve kanıt kodları o zamana kadar kapalı. Henüz bağımsız bir teyit
  yok, bulgu ödül programına da gönderilmedi.
- [Akıllı sözleşme araştırması](projects/01-smart-contract-security-audit/README.tr.md):
  bir hipotezi sabit bloktaki yerel bir fork üzerinde sınadım ve reddettim, çünkü operatör gözlenen
  durumdan kurtulabiliyordu. Bulgu gönderilmedi. Açık kod kesiti testin nasıl kurulduğunu gösteriyor
  ama tekrar üretim için çalıştırılamaz.

### AURA (araştırma prototipi)

AURA benim kendi araştırma prototipim. Tarayıcıda yüz ölçümü ve cerrahi önizlemeyi klinik iş
akışlarıyla birleştiriyor; web uygulamasında, API'de ve araştırma kodunda teknik tasarımı ve inceleme
sürecini ben yönetiyorum. Şu ana kadar kullanıcısı ya da geliri olmadı ve canlı yüzlerde bağımsız
olarak doğrulanmadı. Önizlemenin gösterdiği, önerilen bir plan; ameliyatın sonucunu tahmin etmez.

Vaka çalışması, 27 Eylül 2026 tarihli ön kayıtlı karşılaştırmayı ölçüldüğü çıtalarla birlikte
grafik olarak gösteriyor. Bir KBB cerrahının destek notunu ve Birmingham'dan bir profesörün
yanıtını da aktarıyor; ikisinin de neyi iddia etmediğini yazıyor.

[Projenin kapsamı ve mevcut sınırları](projects/04-aura-photoreal-3d-clinic-platform/README.tr.md)

## Birlikte çalışma

Sabit kapsamlı işler alıyorum; ilk görüşme ve ön değerlendirme ücretsiz. Önce araştırılması gereken
bir sorunda işe ücretli bir ön analizle başlıyorum; bu aşama, uygulamaya geçmeden önce bir teşhis ve
kapsam önerisiyle biter (teslimatlar, kabul kriterleri, takvim). Ödeme teslim aşamalarına göre
yapılır; ilk aşama kararlaştırılan kriterleri karşılamazsa o aşamayı faturalamıyorum.

Devirde kaynak kodla birlikte testleri ve işletme talimatlarını veriyorum; kararlaştırdıysak
ekibinizle bir devir oturumu da yapıyoruz. Müşteri işleri gizlilik koşullarıyla yürütülür; müşteri
kodu ve verisi bu portföyde yer almaz.

[Teslim süreci](DELIVERY-METHODOLOGY.tr.md) ·
[Güvenlik inceleme yöntemi](METHODOLOGY.tr.md)

## İletişim

[hilberspace@gmail.com](mailto:hilberspace@gmail.com) ·
[WhatsApp](https://wa.me/905431064025) · [+90 543 106 40 25](tel:+905431064025)

Sorunu ve kullandığınız teknolojileri yazın. Neyi ne zamana beklediğinizi ve varsa erişim
kısıtlarını da ekleyin. İlk veri incelemesi için anonimleştirilmiş örnekler kullanın.
