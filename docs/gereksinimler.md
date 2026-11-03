# NOVA BAT – Uygulama Gereksinimleri (taslak v2)

Tarih: 3 Kasım 2026 · Hazırlayan: Claude, OZGUR'un isteğine göre

Uygulama: Android, iPhone, tablet ve bilgisayarda çalışan kurulabilir web uygulaması (PWA). Örnek alınan programlar: Coupa (satın alma / bon de commande akışı) ve Lisa (şantiye takibi, puantaj).

---

## 1. Sizin istedikleriniz

### 1.1 Müşteriler ve ürünler (temel kayıtlar)
- Müşteri kartı: firma adı, SIRET/TVA no, adres, **birden fazla e-posta adresi** (ör. muhasebe, şantiye şefi, satın alma).
- Ürün/hizmet kataloğu: ad, birim (adet, m², m³, saat, gün…), birim fiyat, TVA oranı.

### 1.2 Hızlı bon de commande
1. Müşteri seç → ürünleri ekle → miktarları yaz (birim fiyat ve toplamlar otomatik).
2. Müşterinin kayıtlı e-postalarından birini (veya birkaçını) seç.
3. "Gönder" → bon de commande **PDF** olarak oluşturulur ve e-postayla gider, kopyası uygulamada saklanır.
- PDF şablonu: örneği sonra birlikte hazırlayacağız (logo, şirket bilgileri, şartlar).

### 1.3 Fatura
- Bon de commande'dan tek tıkla faturaya dönüştürme.
- Fatura numarası otomatik ve sıralı (Fransız mevzuatına uygun, boşluksuz).
- **E-fatura hesabına bağlantı**: faturalar şirketin e-fatura platformuna gönderilecek (aşağıda 3. bölüm).

### 1.4 Şantiyeler
- Her yeni şantiye için **isim + numara** (ör. CH-2026-001, otomatik artan).
- Her şantiyede ayrı bölümler:
  - **İşçiler** (puantaj)
  - **Kiralamalar** (makine, ekipman)
  - **Satın almalar** (malzeme)
- Kategoriler (işçi tipleri, kiralık ekipman türleri, malzeme kategorileri) **ayarlardan önceden tanımlanır**, şantiyede bir açılır listeden seçilip eklenir.

### 1.5 Puantaj (pointage)
- Günlük/haftalık tablo: işçi × gün → saat (normal, fazla mesai, hava nedeniyle durma "intempéries", devamsızlık).
- Şantiyeye bağlı; haftalık/aylık özet ve maaş için dışa aktarma (Excel/PDF).

### 1.6 Çoklu dil
- Her kullanıcı kendi dilini seçer (profilden, bayrak + dil adıyla), uygulama o dilde açılır.
- İlk sürüm dilleri (14): **Fransızca, Türkçe, Portekizce, Arapça, Çince, Kürtçe (Kurmancî), Almanca, İspanyolca, Lehçe, Romence, Bulgarca, Peştuca ve Darice (Afganistan), Urduca (Pakistan)**.
- Sonraki aşama: **İngilizce, Wolof, Bambara, Soninke, Lingala, Berberice (Tamazight)**.
- **Arapça, Peştuca, Darice, Urduca sağdan sola (RTL)**: tüm ekran düzeni otomatik ayna görüntüsüne döner.
- Bon de commande ve fatura PDF'leri **her zaman Fransızca** (yasal belge); arayüz dili ise kullanıcıya göre.
- Çeviriler tek bir dosyada tutulur, yeni dil eklemek kod değiştirmeden yapılabilir.

### 1.7 Okuma yazması az olanlar için çok basit arayüz
- Her buton **büyük simge + kısa kelime** (ör. 🕒 "Puantaj"); metin okumadan da anlaşılır.
- Her ekranda **en fazla 3–4 ana işlem**, tek adımlık akışlar, büyük "Kaydet ✓" ve "Geri ←" butonları.
- **Sesli okuma**: her başlığın yanında 🔊 düğmesi, metni seçili dilde sesli okur.
- **Sesle giriş**: not ve miktarları mikrofonla söyleyerek yazma.
- Rakamlar ve saatler için **büyük sayı tuşları**, takvim yerine "Bugün / Dün" butonları.
- Renk kodu: yeşil = tamam, turuncu = bekliyor, kırmızı = sorun.
- İşçi kartlarında **fotoğraf**, isimle aramak yerine yüzden seçme.
- Rol bazlı sade görünüm: işçi / şantiye şefi sadece kendi işini görür (puantaj, fotoğraf, malzeme talebi); muhasebe ve yönetim ekranları gizli.
- İlk açılışta resimli kısa tanıtım (3 ekran).

---

## 2. Önerdiğim ek fikirler

**Satış tarafı**
- **Devis (teklif) → Bon de commande → Fatura** zinciri: teklif kabul edilince tek tıkla dönüşür.
- **Situations de travaux** (hakediş/ara fatura): şantiye ilerleme yüzdesine göre fatura, BTP'de çok yaygın.
- **Retenue de garantie** (%5 teminat kesintisi) ve **autoliquidation de TVA** (alt yüklenicilik) desteği.
- Bon de commande'ı müşterinin **ekrandan imzalaması** (telefonda parmakla imza).
- Ödeme takibi: ödenmemiş faturalar, vade hatırlatma e-postası.

**Şantiye tarafı**
- **Bütçe vs gerçekleşen**: her şantiyede işçilik + kiralama + satın alma maliyeti otomatik toplanır, teklif tutarıyla karşılaştırılır (kâr/zarar anlık görünür).
- Kiralamalarda **iade tarihi uyarısı** (gereksiz kira günü ödememek için).
- Şantiye **fotoğrafları ve notlar** (günlük rapor / "journal de chantier").
- Puantajı **şantiye şefi telefondan** girer, internet yokken de çalışır, bağlantı gelince senkronize olur.
- Tedarikçi kartları ve satın alma siparişleri (Coupa mantığı: talep → onay → sipariş → teslim → fatura eşleştirme).

**Genel**
- **Şirket logosu** (ayarlardan yüklenir; uygulama üst çubuğunda, PDF bon de commande ve faturalarda görünür).
- **Kullanıcı profil fotoğrafı** (menüde, puantaj ve görev atamalarında görünür; yoksa baş harfler).
- Arayüz: sade, modern, ferah. Açık/koyu tema, büyük dokunmatik butonlar (şantiyede eldivenle kullanılabilir), telefonda alt menü, bilgisayarda yan menü.
- Kullanıcı rolleri: yönetici, şantiye şefi (sadece kendi şantiyeleri ve puantaj), muhasebe.
- Gösterge paneli: aktif şantiyeler, bu ayın cirosu, bekleyen faturalar, yaklaşan kira iadeleri.
- Çoklu dil: aşağıda 1.6 bölümüne bakın.

---

## 3. Bağlantılar (connector / servisler)

| İhtiyaç | Önerim | Durum |
|---|---|---|
| Veritabanı + kullanıcı girişi | **Supabase** | Claude hesabınızda bağlı görünüyor |
| Uygulamayı yayınlama (link ile açılır) | **Vercel** | Bağlı görünüyor |
| Kod deposu | **GitHub** | Siz kuruyorsunuz, hazır olunca bağlarım |
| Uygulamadan e-posta + PDF gönderme | Resend veya şirket e-postanız (SMTP / Gmail) | Hangi e-posta adresinden gideceği belirlenmeli |
| E-fatura | Şirketinizin kullandığı **plateforme agréée (PA/PDP)** API'si; kamu müşterileri için **Chorus Pro** | Hangi platformu kullandığınızı öğrenmem gerekiyor |
| Muhasebe (isteğe bağlı) | Muhasebecinizin programına dışa aktarım (FEC / Excel) | Sonra |

Not: Fransa'da e-fatura reformunda Eylül 2026'dan itibaren tüm şirketler e-fatura **almak** zorunda, KOBİ'ler için **gönderme** zorunluluğu Eylül 2027. Bu yüzden faturayı doğrudan platformunuza gönderecek şekilde kuracağız.

---

## 4. İleride satılabilir uygulama (SaaS) hazırlığı

Uygulama baştan **çok şirketli** tasarlanacak, böylece ileride başka firmalara aylık abonelikle satılabilir:
- Her veri (müşteri, şantiye, fatura…) bir **şirket hesabına** bağlı; şirketler birbirinin verisini asla göremez (veritabanı seviyesinde satır güvenliği).
- Şirket ayarları: logo, SIRET, TVA, fatura numarası öneki, PDF şablonu, e-fatura bağlantısı her şirkete ayrı.
- Kullanıcı davet sistemi ve roller şirket bazında.
- İlk sürümde tek şirket (NOVA BAT) kullanır; satışa geçince kayıt sayfası ve abonelik ödemesi (ör. Stripe) eklenir, yeniden yazmaya gerek kalmaz.
- **Kurulum sihirbazı (ilk açılışta):** şirket bilgileri → e-fatura platformu seçimi ve bağlantısı (API anahtarı veya "platformla giriş yap") → bon de commande e-postasının bağlanması (Gmail / Outlook ile giriş veya SMTP) → kullanıcı davetleri. Her şirket bağlantıyı kendisi yapar, bize iş düşmez. Bu adımlar için yapay zekâ gerekmez.
- **Kullanıcılar:** şirket admini birden fazla kişiyi davet eder, rol ve yetki verir.
- **Paketler:** kullanıcı sayısına göre fiyatlandırma (ör. 1-3, 4-10, 10+ kullanıcı).
- Yapay zekâ ileride isteğe bağlı ek olabilir: tedarikçi faturasını fotoğraftan okuma, sesle puantaj girme, şantiye maliyet özeti.
- Satış için ileride: deneme süresi, plan seviyeleri (kullanıcı/şantiye sayısına göre), mağaza sürümü, CGV/RGPD metinleri.

## 5. Sizden beklenenler
1. E-fatura için hangi platformu kullanıyorsunuz (ör. Pennylane, Sage, Cegid, Docoon, bankanızın platformu…)?
2. Bon de commande e-postaları hangi adresten gitsin?
3. Uygulamayı kaç kişi kullanacak, şantiye şefleri de girecek mi?
4. Bon de commande ve fatura için örnek bir belge (eski bir PDF yeterli).
