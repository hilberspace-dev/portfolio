# Serhat Atılgan | Backend geliştirme

[English](README.md) · [GitHub](https://github.com/hilberspace-dev)

Go, PostgreSQL ve TypeScript ile backend geliştiriyorum. İşlerimin çoğu ödeme
mutabakatı ve API entegrasyonu; mevcut uygulamaların bakımını da üstleniyorum.
Türkiye'de yaşıyorum, Türkçe ve İngilizce çalışıyorum.

## Projeler

### ReconPilot

PSP raporlarını, banka ekstrelerini ve pazaryeri hakedişlerini içeri alan bir
Go/PostgreSQL uygulaması. Kesin, toleranslı ve grup eşleştirmesinden sonra kalan
kayıtları sınıflandırır. Bir girdiyi sonuç dışında bırakan veya aynı işlemi
birden fazla gruba yerleştiren sonuçlar çalışma anındaki kontrollerden geçemez.

Açık depoda komut satırı aracı, HTTP servisi, HTML raporu, testler ve sentetik
benchmark bulunuyor. Benchmark, eşleşmeleri veri üreticisinin amaçladığı
gruplarla karşılaştırır. Müşteri verisiyle hiç çalıştırılmadı, dolayısıyla oradaki
doğruluk hakkında bir şey söylemiyor.

[Kaynak kod ve çalıştırma talimatları](https://github.com/hilberspace-dev/reconpilot) ·
[Vaka çalışması](projects/03-reconpilot-payment-reconciliation/README.tr.md)

### AURA

Tarayıcıda yüz ölçümü ve cerrahi önizlemeyi klinik iş akışlarıyla birleştiren
kendi araştırma prototipim. Web uygulaması, API ve araştırma kodunun teknik
tasarımını ve inceleme sürecini yönetiyorum. Henüz kullanıcısı ve geliri yok.
Canlı yüzlerde henüz bağımsız bir doğrulama yapılmadı. Önizleme önerilen bir
planı gösterir; ameliyat sonucunu tahmin etmez.

[Projenin kapsamı ve mevcut sınırları](projects/04-aura-photoreal-3d-clinic-platform/README.tr.md)

## Güvenlik incelemeleri

- [ERC-4337 EntryPoint](projects/02-erc4337-entrypoint-review/README.tr.md):
  kendi değerlendirmemde düşük önem derecesi verdiğim bir doğruluk bulgusu.
  Yerel ortamda ve ayrı bir istemcide tekrar üretim kayıtları var. Ödül programına
  gönderilmedi, bağımsız doğrulama almadı. Tam mekanizma ve kanıt kodları kapalı.
- [Akıllı sözleşme araştırması](projects/01-smart-contract-security-audit/README.tr.md):
  sabit bloktaki yerel fork üzerinde sınanan hipotez, operatörün gözlenen durumdan
  kurtulabilmesi nedeniyle reddedildi. Bulgu gönderilmedi. Açık kod kesiti testin
  nasıl kurulduğunu gösteriyor ama tekrar üretim için çalıştırılamaz.

## Birlikte çalışma

Sabit kapsamlı işler alıyorum. İlk görüşme ve ön değerlendirme ücretsiz.
Önce araştırılması gereken bir sorunda işe ücretli bir ön analizle başlıyorum;
bu aşama, uygulamaya geçmeden önce bir teşhis ve kapsam önerisiyle biter.
Kapsamda teslimatlar, kabul kriterleri ve takvim yer alır. Ödeme teslim
aşamalarına göre; ilk aşama kararlaştırılan kriterleri karşılamazsa o aşamayı
faturalamıyorum.

Devirde kaynak kod, testler, işletme talimatları ve kararlaştırılmışsa ekibinizle
devir oturumu bulunur. Müşteri işleri gizlilik koşullarıyla yürütülür; müşteri
kodu ve verisi bu portföyde yayımlanmaz.

[Teslim süreci](DELIVERY-METHODOLOGY.tr.md) ·
[Güvenlik inceleme yöntemi](METHODOLOGY.tr.md)

## İletişim

[hilberspace@gmail.com](mailto:hilberspace@gmail.com) ·
[WhatsApp](https://wa.me/905431064025) · [+90 543 106 40 25](tel:+905431064025)

Problemi, mevcut teknolojileri, beklenen teslimatı, zaman planını ve erişim
kısıtlarını yazabilirsiniz. İlk veri incelemesi için anonimleştirilmiş örnekler
kullanın.
