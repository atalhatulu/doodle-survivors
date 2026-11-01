# Doodle Survivors — Kapsamlı Proje Denetimi ve Uzun Soluklu Yol Haritası

**Tarih:** 31 Ekim 2026  
**Motor:** Godot Engine 4.7  
**Tür:** 2D Top-Down Roguelite Horde Survival  
**Hedef Kapsam:** Kapsamlı teknik denetim, mevcut 14 silahın anatomisi, tür içi farklılaşma stratejisi ve uzun soluklu ana plan  

---

## BÖLÜM 1: GENEL SİSTEM DENETİMİ (AUDIT TEST SONUÇLARI)

Yapılan otomatik statik analiz ve çalışma zamanı simülasyonları neticesinde elde edilen sistem verileri:

* **Script Derleme Sağlığı:** 37 GDScript dosyasının tamamı Godot 4.7 statik tip denetleyicisinden 0 hata ve 0 uyarı ile geçmiştir.
* **Sahne Bütünlüğü:** Projedeki 57 sahnenin (.tscn) tamamı belleğe yüklenmiş ve örneklenebilirliği doğrulanmıştır.
* **Kayıtlı Silah Envanteri:** 14 adet silah sahnesi ve ilgili mermi/efekt dosyaları eksiksiz bağlıdır.
* **Pasif Eşya Havuzu:** 19 adet pasif eşyanın tümü `level_up_menu.gd` ve `player.gd` üzerinde istatistik formüllerine bağlanmıştır.
* **Karakter Sistemi:** 4 karakter (Sürgün Şövalye, Karanlık Büyücü, Orman Korucusu, Kızıl Simyager) başlangıç silahları ve portreleriyle sorunsuz çalışmaktadır.
* **Düşman & Dalga Sistemi:** 12 düşman tipi, 4 ara/final bossu (5., 10., 15., 20. dakika) ve dakika bazlı elit canavar döngüleri aktiftir.

---

## BÖLÜM 2: MEVCUT 14 SİLAHIN DETAYLI İNCELEMESİ VE GELİŞTİRME FIRSATLARI

| Silah Adı | Çalışma Mantığı | Güçlü Yönü | Zayıf Yönü / Eleştiri | Önerilen Farklılaşma Dokunuşu |
| :--- | :--- | :--- | :--- | :--- |
| **Avcı Yayı** (`weapon_bow`) | Düz hatlı delici ok atışı | Güvenilir uzun menzil | Diğer düz mermilerden farksız kalıyor | **Çivileme (Impale):** Kritik vuruşta düşmanı arkasındaki düşmana sabitleyip sersemletme |
| **Büyü Asası** (`weapon_staff`) | En yakındaki hedefe enerji küresi | Yüksek tekil hasar | Klasik Magic Wand kopyası | **Mana Rezonansı:** Çarptığı hedeften 2 yakındaki düşmana enerji sıçraması (mini ark) |
| **Şövalye Kılıcı** (`weapon_sword`) | Hareket yönünde kavisli savurma | Harika ön alan temizliği ve itme | Dururken yönlendirme hantal | **3'lü Ritimli Kombo:** Sol savurma -> Sağ savurma -> 3. vuruşta 360 derece döner kesiş |
| **Savaş Baltası** (`weapon_axe`) | Yerçekimli kavisli tepe atışı | Kalabalıklara yukarıdan yüksek hasar | Oyuncunun hemen yanındaki düşmanları kaçırıyor | **Zemin Yarma:** Baltanın düştüğü yerde 0.6 sn çatlak bırakarak yavaşlatma |
| **Fırlatma Hançeri** (`weapon_dagger`) | En yakın düşmana seri atış | Muazzam tekil hedef DPS'i | Yoğun dalgalarda yetersiz kalıyor | **Kanama İstifi (Bleed):** Aynı hedefe 3 hançer isabetinde patlayan kanama hasarı |
| **Büyü Kitabı** (`weapon_spellbook`) | Karakter çevresinde dönen kitaplar | Mükemmel yakın koruma kalkanı | King's Bible ile birebir aynı | **Sayfa Patlaması:** Her 5 saniyede bir sayfalarını 2 kat menzile fırlatıp geri toplama |
| **Simyager İksiri** (`weapon_potion`) | Yere atılan ve zehir göleti bırakan iksir | Yüksek alan kontrolü ve DoT | Hedef seçimi bazen rastgele hissettiriyor | **Uçucu Buhar:** Gölet biterken duman bulutuna dönüşüp oyuncunun ardında sis perdesi bırakması |
| **Bumerang** (`weapon_boomerang`) | İleri gidip geri dönen delici kavis | Gidiş ve dönüşte çifte hasar | Oyuncu hızla koşarken dönüş ıskalayabiliyor | **Yakalama Patlaması:** Oyuncu dönen bumerangı yakaladığında çevresine rüzgar şoku yayması |
| **Yıldırım Asası** (`weapon_lightning`) | Gökten rastgele düşmanlara şimşek | Ekranda görsel şölen, sınırsız menzil | Aşırı kalabalıklarda temizleme hızı yetersiz | **Statik Zincirleme:** Çarptığı düşmandan en yakın 2 hedefe zincirleme elektrik sıçraması |
| **Kutsal Aura** (`weapon_aura`) | Zemin seviyesinde dönen kutsal mühür | Karakteri örtmüyor, zemin netliği yüksek | Tamamen pasif, oyuncu girdisi sıfır | **Kutsanmış Zemin:** Çemberde ölen düşmanların %10 ihtimalle can yenileyen ışık özü bırakması |
| **Deprem Asası** (`weapon_earthquake`) | Yere vurulan sismik şok dalgası | Devasa savurma ve sersemletme | Atış aralığı uzun | **Artçı Sarsıntı (Aftershock):** Ana darbeden 0.3 sn sonra daha geniş 2. zayıf dalga |
| **Ruh Kurdu** (`weapon_spirit_wolf`) | Sahada bağımsız avlanan kurt yoldaş | Tek çağırma silahı, canlılık hissi | Görseli şu an sadece mavi taş rün karesi | **Özel Kurt Çıkartması & Uluma:** Kurt çıkartma görseli ve kritik anlarda düşmanları kaçıran uluma |
| **Ejderha Nefesi** (`weapon_dragon_breath`) | Yöne doğru sürekli püsküren alev konisi | Muhteşem sürekli DoT hasarı | Oyuncu hızla dönünce alev parçaları kopuk kalıyor | **Köz Kalıntısı:** Alevin yaladığı zeminin 1 saniye kor kalarak düşmanları yakmaya devam etmesi |
| **Boşluk Girdabı** (`weapon_void_vortex`) | Düşmanları çekip patlayan kara delik | Eşsiz gravitasyonel çekim | Patlama hasarı çekilen düşmandan bağımsız | **Kozmik Çöküş:** İçine çektiği düşman sayısı arttıkça final patlamasının hasar ve çapının katlanması |

---

## BÖLÜM 3: BENZERİ OYUNLARDAN (VAMPIRE SURVIVORS, BROTATO) FARKLILAŞMA STRATEJİSİ

Doodle Survivors'ı türün diğer oyunlarından net şekilde ayıracak 4 Temel Özgün Sütun:

### 1. Element Rezonansı ve Füzyon Sistemi (Status Synergy)
* **Problem:** Çoğu survival oyununda silahlar birbirinden habersiz bağımsız ateş eder.
* **Farkımız:** Mermiler düşmanlara element durumları bırakır ve bu durumlar birbiriyle fiziksel reaksiyona girer:
  * *Ateş (Ejderha Nefesi) + Zehir (Simyager İksiri)* = **Toksik Patlama (Chemical Blast)** — Geniş alanda anlık patlama.
  * *Boşluk Girdabı + Yıldırım* = **Süper İletken Girdap** — Girdabın içindeki tüm düşmanlara aynı anda yıldırım hasarı aktarımı.
  * *Deprem + Kutsal Aura* = **Kutsal Kırılma** — Depremin ittiği düşmanlar auraya çarptığında %200 ekstra hasar alır.

### 2. Taktiksel Tek Tuş: Karakter Atılma / Savunma Yeteneği (Active Dash / Mobility)
* **Problem:** Vampire Survivors sadece yürümekten ibarettir; Brotato'da kaçınma zordur.
* **Farkımız:** Her karaktere özel `Space` tuşuyla çalışan 4-6 saniye bekleme süreli taktiksel yetenek:
  * *Şövalye:* **Kalkanla Hücum (Shield Rush)** — İleri atılarak düşmanları ezer ve sersemletir.
  * *Korucu:* **Gölge Taklası (Shadow Roll)** — Dokunulmazlık taklası atar ve arkasında yavaşlatıcı tuzaklar bırakır.
  * *Büyücü:* **Boyut Sıçraması (Arcane Blink)** — Kısa mesafe ışınlanır, kalktığı yerde enerji patlaması bırakır.
  * *Simyager:* **Zehir Sisi (Smoke Bomb)** — Olduğu yerde duman bırakıp 1.5 saniye görünmez/dokunulmaz olur.

### 3. Çıkartma Dünyası ve Çevre Etkileşimi (Sticker Physics)
* Haritada sadece görsel dekor değil, silahlardan etkilenen zemin yırtıkları (chasms/chasms).
* Boşluk Girdabı veya Deprem silahıyla düşmanları haritadaki zemin çatlaklarından aşağı iterek tek vuruşta öldürme (Ring-Out mekaniği).

### 4. Kadim Sunaklar ve Lanet Paktları (Risk-Reward Shrines)
* Haritada beliren gizemli sunaklar:
  * "Canını yarıya indir, 90 saniye boyunca tüm vuruşların %100 kritik olsun."
  * "Düşman sayısını ikiye katla, düşen altınlar 3 katına çıksın."
  * Oyuncuya kendi kaderini çizme özgürlüğü verir.

---

## BÖLÜM 4: UZUN SOLUKLU MASTER PLAN (YAPILACAK / EKLENECEK / İYİLEŞTİRİLECEK)

```
                                  UZUN SOLUKLU MASTER PLAN
  
   [FAZ 1: TEMEL MEKANİK & CİLA]       [FAZ 2: DERİNLİK & FARK]        [FAZ 3: OYUN SONU & İÇERİK]
   • Dash / Yetenek Sistemi             • Element Rezonansları          • Yeni Karakterler & Silahlar
   • Görsel İyileştirmeler (Kurt)       • Kadim Sunaklar (Pacts)        • Başarım & Görev Sistemi
   • Hasar & Denge Ayarları             • Çevre Yırtıkları (Ring-out)   • Farklı Harita/Biyomlar
   • Ayarlar & Ses Menüsü               • Silah Evrimleri (Evolutions)  • Boss Fazları & Telegraflar
```

### Kategori A: EKLENECEK (Yeni Sistemler)

1. **Öncelik 1: Karakter Aktif Yetenek Sistemi (Dash / Active Skill):**
   * `Space` tuşuna bağlı sınıf atılma yeteneği. HUD üzerine küçük, şık dolma süresi göstergesi.
2. **Öncelik 2: Element Rezonans Motoru:**
   * Düşmanlara `burn`, `poison`, `shock` durum değişkenleri eklenip element birleşim patlamalarının kodlanması.
3. **Öncelik 3: Kadim Sunaklar (Pact Shrines):**
   * Haritada belirli dakikalarda beliren, oyuncuya risk-ödül teklifleri sunan etkileşimli yapılar.
4. **Öncelik 4: Silah Evrim Sistemi (Weapon Evolutions / Fusions):**
   * Maksimum seviye silah + ilgili maksimum pasif eşya ile sandıktan çıkan Efsanevi Evrimler (Örn: *Kutsal Aura + Zırh = İlahi Güneş Mabedi*).
5. **Öncelik 5: Yeni Karakter Arketipleri:**
   * *Gölge Çağırıcı (Necromancer):* Ölen düşmanlardan minik iskelet sticker ordusu kuran sınıf.
   * *Fırtına Şamanı (Storm Caller):* Rüzgar ve şimşek rezonansında uzmanlaşmış sınıf.

### Kategori B: YAPILACAK (Teknik Altyapı ve Mimari)

1. **Öncelik 1: Ruh Kurdu İçin Özel Sticker Çizimi:**
   * `proj_rune.png` yerine gerçek bir ruh kurdu çizimi/sprite'ının sahneye entegre edilmesi.
2. **Öncelik 2: Oyun Ayarları Menüsü (Settings Menu):**
   * Ana Menü ve Oyun İçi Menüye: Ekran sarsıntısı şiddeti ayarı (Screen Shake Slider), Hasar sayıları aç/kapat, Ses (Master, SFX, Müzik) seviye barları.
3. **Öncelik 3: Silah Kontrolcü Mimarisi (WeaponController Refactor):**
   * Silahları `Marker2D` hiyerarşisinden kurtarıp, oyuncu gövdesinde dinamik bir bileşen yöneticisi haline getirmek.
4. **Öncelik 4: Kalıcı İlerleme (Meta Progression) Sayfasının Genişletilmesi:**
   * Yeni statlar: Yeniden Doğma (Revive), Pasif Çekiliş Hakkı (Rerolls), Atılma Bekleme Süresi (Dash Cooldown).

### Kategori C: İYİLEŞTİRİLECEK (Denge, Performans ve Cila)

1. **Öncelik 1: Silah Dengeleme ve Vuruş Hissi:**
   * Fırlatma Hançeri ve Büyü Asası için daha net vuruş etkisi (impact shake).
   * Şövalye Kılıcının 3 vuruşluk kombo animasyonu ile zenginleştirilmesi.
2. **Öncelik 2: Düşman Sürü Fiziği (Soft Collisions / Flocking):**
   * 200+ düşman toplandığında üst üste tek nokta gibi yığılmak yerine birbirlerini hafifçe iterek organik bir akın oluşturması.
3. **Öncelik 3: Oyun Sonu İstatistik Sayfası (Run Summary):**
   * Zafer veya yenilgi ekranında: Toplam öldürme, dakika bazlı grafik, hangi silahın ne kadar toplam hasar vurduğunu gösteren DPS dağılım çubuğu.
4. **Öncelik 4: Boss Saldırı Telegrafları:**
   * 5., 10., 15. ve 20. dakika bosslarının güçlü alan vuruşları öncesinde zemin üzerinde beliren kırmızı uyarı halkaları/çizgileri.

---

## BÖLÜM 5: ELEŞTİRİ PROTOKOLÜ VE RİSK ANALİZİ

1. **Risk: Aşırı Tuş Kalabalığı ve Odak Dağılması:**
   * *Tehlike:* Oyuna Dash, 1. Yetenek, 2. Yetenek, İksir Tuşu gibi çok sayıda aktif kontrol eklemek, hayatta kalma türünün meditatif "akış modu" (flow state) hissini yok eder.
   * *Karar:* Sadece ve sadece **TEK BİR AKTİF TUŞ** (`Space` - Atılma/Dash) eklenmelidir. Diğer tüm ateşleme ve rezonanslar otomatik olarak gerçekleşmelidir.
2. **Risk: Element Füzyonlarının Performansı Düşürmesi:**
   * *Tehlike:* Yüzlerce merminin sahnede birbirini arayıp reaksiyona girmesi işlemciyi tıkayabilir.
   * *Karar:* Mermiler birbirini değil, doğrudan hedefin üzerindeki durum etiketlerini (`is_burning`, `is_poisoned`) kontrol edecek; böylece rezonans $O(1)$ sabit zamanlı çalışacaktır.
