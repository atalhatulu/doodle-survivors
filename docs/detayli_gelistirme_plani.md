# Doodle Survivors — Detaylı Geliştirme ve Mimari Planlama Raporu

Bu belge, temel hata onarımları tamamlanan projenin bir sonraki aşamaya (tam kapsamlı karanlık fantezi hayatta kalma deneyimine) taşınması için hazırlanan teknik ve mekanik uygulama planıdır.

---

## 0. Mimari Eleştiri, Risk Analizi ve Alternatif Çözüm

Planı uygulamaya koymadan önce mevcut yapıda tespit edilen **3 kritik tasarım riski** ve bunların çözüm mimarisi:

### Risk 1: Silah Yuvası (`WeaponSlots`) Temsil Sorunu
- **Zayıf Nokta:** Mevcut sistemde tüm silahlar `Player/WeaponSlots` altındaki 6 adet sabit `Marker2D` noktasından birine yerleşiyor ve orada bir silah ikonu gösteriyor. Kılıç, Yay veya Asa için bu mantıklıdır; ancak **Kutsal Aura**, **Yıldırım Çağrısı**, **Hiçlik Girdabı** veya **Ruhani Kurt** gibi silahların karakterin sağ üst omzunda asılı bir ikon olarak durması görsel olarak hatalıdır.
- **Mimari Çözüm:** Silahları sahne davranışına göre 3 sınıfa ayıracağız:
  1. **Odaklı Silahlar (Slot Weapons):** Karakterin etrafındaki yuvalarda durup nişan alanlar (Balta, Hançer, Yay, Asa, Kılıç, Bumerang).
  2. **Merkez Silahları (Center Weapons):** Yuva hakkı harcayan ancak görsel ve fiziksel olarak `player.global_position` merkezine kilitlenenler (Büyü Kitabı, Kutsal Aura, Ejderha Nefesi, Savaş Narası).
  3. **Saha / Çağrı Silahları (World / Summon Weapons):** Karakterin üzerinde hiçbir sabit ikon göstermeyen, doğrudan harita üzerinde etki veya yoldaş doğuranlar (Simya İksiri, Yıldırım Çağrısı, Hiçlik Girdabı, Ruhani Kurt).

### Risk 2: Eşya Havuzu Şişmesi (Pool Dilution)
- **Zayıf Nokta:** 8 mevcut silah + 6 yeni silah + 19 pasif eşya = **33 farklı yükseltme**. Mevcut "tek kart gör -> geç -> mecbur al" sistemiyle 33 eşya arasından istediğin dizilimi (build) kurmak imkansızlaşır.
- **Mimari Çözüm:** Yeni silahlarla birlikte seviye atlama ekranı **3 kartın yan yana göründüğü** yapıya geçirilmeli ve oyuncuya **Yeniden Çekme (Reroll)** ile **Eşya Engelleme / Pas Geçme (Banish / Skip)** imkanı tanınmalıdır.

### Risk 3: Alan Hasarı (DoT) ve Fizik Performansı
- **Zayıf Nokta:** Aura, Alev Konisi ve Kara Delik gibi sürekli alan silahları her fizik karesinde (`60 FPS`) hasar hesaplaması ve kayan hasar yazısı (Damage Number) üretirse, ekranda 250 düşman varken kare hızı çöker.
- **Mimari Çözüm:** Tüm alan silahları sabit **Vuruş Periyodu (Tick Rate: 0.25sn – 0.40sn)** kullanacak ve çekim/itme kuvvetleri sinyal yerine doğrudan vektör matematiğiyle uygulanacaktır.

---

## Faz 1: Mermi Fırlatmayan 6 Yeni Karanlık Fantezi Silahı

Mevcut silahların "mermi fırlatma" tekdüzeliğini kırmak ve 16 karakter istatistiğinin tamamını anlamlı kılmak için eklenecek 6 yeni silah:

| # | Silah Adı | Arketip / Mekanik | Öne Çıkan İstatistik Sinerjisi | Seviye 1 -> Seviye 7 Gelişimi |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Kutsal Aura** (`weapon_aura`) | Karakterin ayakları altında sürekli aktif olan kadim rün çemberi. İçine giren düşmanlara periyodik hasar verir ve hafifçe geri iter. | **Alan (`area_mult`)**, **Yenilenme (`hp_regen`)**, **Maks. Can (`max_health`)** | Çember yarıçapı büyür, vuruş sıklığı `0.45sn -> 0.25sn` olur. Lv.7'de oyuncunun Can Yenilenmesi değerinin 10 katını taban hasara ekler ve düşmanları %25 yavaşlatır. |
| **2** | **Yıldırım Çağrısı** (`weapon_lightning`) | Mermi uçuşu yoktur. Gökyüzünden doğrudan düşmanların tepesine yıldırım düşürür ve düştüğü noktada şok halkası yaratır. | **Miktar (`extra_projectiles`)**, **Alan (`area_mult`)**, **Şans (`crit_chance`)** | Başlangıçta 1 yıldırım düşer; seviye ve Miktar pasifiyle aynı anda 6-8 düşmanın tepesine ardışık yıldırımlar iner. Lv.7'de düştüğü yerde elektrikli alan bırakır. |
| **3** | **Ejderha Nefesi** (`weapon_dragon_breath`) | Karakterin baktığı/yürüdüğü yöne doğru belirli aralıklarla kesintisiz alev püskürten konik büyü. Oyuncu dönerek sürüyü süpürebilir. | **Etki Süresi (`duration_mult`)**, **Hareket Hızı (`move_speed`)**, **Hasar Gücü (`might`)** | Püskürtme süresi `1.2sn -> 2.5sn` uzar, koni açısı genişler. Lv.7'de mavi cehennem alevine dönüşerek zırh deler ve sürekli yakar. |
| **4** | **Hiçlik Girdabı** (`weapon_void_vortex`) | Düşmanların yoğun olduğu noktada bir kara delik açar. Süre boyunca düşmanları merkeze vakumlar, ezer ve kapanırken patlar. | **Etki Süresi (`duration_mult`)**, **Alan (`area_mult`)**, **Bekleme Süresi (`cooldown_mult`)** | Çekim gücü ve yarıçapı artar. Simya İksiri ve Balta ile ölümcül kombo yapar. Lv.7'de kapanış patlaması tüm ekranı sarsan dev bir kritiğe dönüşür. |
| **5** | **Ruhani Kurt** (`weapon_spirit_wolf`) | Sahada bağımsız koşan, en yakın düşmanların üzerine atılıp parçalayan çağrı (Minion) büyüsü. | **Mermi Hızı (`projectile_speed_mult`)**, **Miktar (`extra_projectiles`)**, **Etki Süresi (`duration_mult`)** | Mermi hızı kurdun koşu ve ısırma hızını artırır. Miktar pasifi ve silah seviyesiyle sahadaki kurt sayısı 1'den 4'e çıkar. Lv.7'de Alfa Kurt formuna geçer. |
| **6** | **Savaş Narası / Deprem** (`weapon_earthquake`) | Karakterin etrafında 360 derece yayılan sismik şok dalgası. Düşmanları uzağa savurur ve sersemletir. | **Zırh (`armor`)**, **Maks. Can (`max_health`)**, **Alan (`area_mult`)** | Hasarı doğrudan karakterin **Zırh** ve **Maks. Can** değerleriyle çarpanlı artar. Oyuncu darbe aldığında bekleme süresini sıfırlayıp anında ücretsiz misilleme depremi vurur. |

### Faz 1 Uygulama Adımları:
1. Bu 6 silah ve efektleri (yıldırım çakması, alev konisi, kara delik girdabı, rün çemberi, ruhani kurt, deprem çatlağı) için **tek bir toplu AI görsel üretim promptu** hazırlanması.
2. Görsellerin `assets/sprites/weapons/` dizinine eklenmesi.
3. 6 silahın script ve `.tscn` sahnelerinin kodlanıp `level_up_menu.gd` ile `inventory_menu.gd` içine entegre edilmesi.

---

## Faz 2: Seviye Atlama Ekranı Yenilemesi (3 Kart Yan Yana + Reroll)

### Mevcut Sorun:
Tekli kart ("1. Şans -> Geç -> 2. Şans") yapısı, oyuncunun 2. ve 3. kartta ne olduğunu görmeden karar vermesine neden oluyor.

### Yapılacaklar:
1. **3 Kart Yan Yana Düzen (`level_up_menu.tscn` & `level_up_menu.gd`):**
   - Ekranın ortasında 3 adet parşömen/çıkartma kartı yan yana açılacak (`1`, `2`, `3` klavye kısayolları veya fare tıklamasıyla anında seçim).
   - Kart üzerinde eşyanın ikonu, adı, etiketi (`[YENİ SİLAH]`, `[Lv.3 -> Lv.4]`), açıklaması ve ilgili istatistik artışı net olarak görünecek.
2. **Yeniden Çekme (Reroll) ve Pas Geçme (Skip) Butonları:**
   - Oyuncuya her oyunda **2 adet Yeniden Çekme (Reroll)** hakkı verilecek.
   - İstenmeyen kartlar geldiğinde **Pas Geç (+%25 XP İadesi)** seçeneğiyle tur atlanabilecek.

---

## Faz 3: Harita Etkileşimi, Kırılabilir Nesneler ve Özel Kuşatmalar

Haritayı boş bir zeminden yaşayan bir savaş alanına dönüştürecek mekanikler:

### 3.1. Kırılabilir Çevre Nesneleri (`destructible_prop.gd`)
- `chunk_manager.gd` her harita parçasında rastgele 2–4 adet kırılabilir **Ahşap Fıçı / Kadim Küp / Mezar Taşı** doğuracak.
- Oyuncunun silahlarıyla kırılan nesnelerden `luck_mult` (Şans) istatistiğine bağlı olarak şu 4 eşyadan biri düşecek:
  1. **Altın Kesesi:** Anında +15 Altın.
  2. **Şifa İksiri / Kızarmış Et:** Anında +30 HP yeniler.
  3. **Vakum Küresi (Mıknatıs):** Haritanın neresinde olursa olsun yerde bekleyen tüm XP kristallerini tek seferde oyuncuya doğru vakumlar.
  4. **Kıyamet Mühürü (Ekran Temizleyici):** Ekrandaki tüm normal düşmanları anında yok eder, elitlere ağır hasar verir.

### 3.2. Dakika Bazlı Özel Kuşatma Olayları (`enemy_spawner.gd`)
Normal düşman doğma döngüsüne ek olarak belirli dakikalarda tetiklenen özel dalgalar:
- **4. Dakika — Yarasa Sürüsü Baskını:** Ekranın bir kenarından diğerine doğru yüksek hızla uçan 40'lı yarasa grubu.
- **8. Dakika — Demir Çember Kuşatması:** Oyuncunun etrafında `900px` yarıçapında 360 derece tam bir daire şeklinde doğan ve merkeze doğru daralan ağır zırhlı düşman çemberi (oyuncuyu çemberde gedik açmaya zorlar).
- **14. Dakika — Gölge Akını:** Engellerin içinden geçen hayaletlerin yüksek sıklıkla saldırdığı 45 saniyelik baskın.

---

## Faz 4: Karakter Seçim Ekranı ve Atölye Genişletmesi

Oyuna başlamadan önce farklı oyun tarzları sunan **4 oynanabilir karakter**:

1. **Sürgün Şövalye (Tank / Misilleme):**
   - *Başlangıç Silahı:* Şövalye Kılıcı (`weapon_sword`) veya Savaş Baltası (`weapon_axe`)
   - *Özel Bonus:* `+%15 Zırh`, `+25 Maks. Can`, `+%10 Hasar Gücü`
2. **Karanlık Büyücü (Alan Kontrolü / Büyü):**
   - *Başlangıç Silahı:* Büyü Asası (`weapon_staff`)
   - *Özel Bonus:* `+%20 Alan`, `-%10 Bekleme Süresi`
3. **Orman Korucusu (Hız / Kritik / Delici Ok):**
   - *Başlangıç Silahı:* Avcı Yayı (`weapon_bow`)
   - *Özel Bonus:* `+%15 Hareket Hızı`, `+%20 Mermi Hızı`, `+%10 Şans`
4. **Kızıl Simyager (Süre / Alan Hasarı / DoT):**
   - *Başlangıç Silahı:* Simya İksiri (`weapon_potion`)
   - *Özel Bonus:* `+%25 Etki Süresi`, `+0.4 HP/sn Yenilenme`, `+%15 Büyüme (XP)`

---

## Faz 5: Silah Evrim (Evolution) Sistemi (Son Aşama)

Tüm düz silahlar, pasifler ve karakterler tamamlandıktan sonra devreye alınacak zirve mekaniği:
- Bir silah **Seviye 7 (Maksimum)** olduğunda ve onunla eşleşen **Pasif Eşya** oyuncunun envanterinde bulunduğunda, kesilen Elit veya Boss sandığından silahın **Evrimleşmiş Nihai Formu** çıkacak (ör. *Savaş Baltası + Güç Bombası -> Kıyamet Biçici*; *Büyü Kitabı + Kadim Kum Saati -> Sonsuzluk Kodeksi*).

---

## Önerilen Uygulama Sırası

1. **Adım 1 (Şimdi):** Faz 1'deki **6 Yeni Mermisiz Fantezi Silahı** için görsel üretim promptunu hazırlamak ve silahları oyuna kodlamak.
2. **Adım 2:** Faz 2'deki **3 Kart Yan Yana Seviye Atlama Ekranı + Reroll** sistemini kurmak.
3. **Adım 3:** Faz 3'teki **Kırılabilir Fıçılar, Vakum Küresi ve Özel Dakika Kuşatmalarını** eklemek.
4. **Adım 4:** Faz 4'teki **Karakter Seçim Ekranını** eklemek.
5. **Adım 5:** Faz 5'teki **Silah Evrimlerini** bağlamak.
