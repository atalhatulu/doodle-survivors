# Kadim Pakt ve Eşya Dengeleme Raporu

**Tarih:** 31 Ekim 2026  
**Durum:** Tamamlandı  
**Doğrulama:** 15/15 Headless Test Başarılı  

---

## 1. Kadim Pakt (Pact Shrine) Nedir ve Nasıl Çalışır?

Kadim Pakt, haritada rastgele aralıklarla beliren veya belirli dalgalarda ortaya çıkan, oyuncuya **yüksek risk / yüksek ödül** sunan karanlık bir sunaktır.

### Sunduğu 3 Faustian Pakt:
1. **Kan Paktı (Blood Pact):**
   - **Bedel:** Maksimum Can kalıcı olarak -25 azalır.
   - **Kazanım:** Kritik vuruş şansı +%15 ve Kritik vuruş hasarı +%35 artar.
2. **Açgözlülük Paktı (Greed Pact):**
   - **Bedel:** Lanet (Curse) seviyesi %15 artar (Düşmanlar daha hızlı ve kalabalık gelir).
   - **Kazanım:** Anında +100 Altın ve kalıcı olarak +%50 Altın Çarpanı.
3. **Ruh Paktı (Soul Pact):**
   - **Bedel:** Hareket hızı kalıcı olarak -%10 yavaşlar.
   - **Kazanım:** +1 Ekstra Dirilme hakkı (Revive) ve anında tam can yenileme.

### E Tuşunun Çalışmama Nedeni ve Çözümü:
- **Sorun:** Godot'ta arayüz etkileşimleri için kullanılan `"ui_accept"` aksiyonu varsayılan olarak yalnızca `Enter` ve `Space` tuşlarına bağlıydı. Ekranda `[ E ] KADİM PAKT` yazmasına rağmen motor `E` tuşuna basıldığında bu sinyali yakalamıyordu.
- **Çözüm:** `scripts/pact_shrine.gd` içine doğrudan `InputEventKey` kontrolü eklenerek `KEY_E` tuş kodu doğrudan yakalandı. Artık oyuncu sunağa yaklaşıp `E` tuşuna bastığı anda pakt seçim arayüzü açılmaktadır.

---

## 2. Pasif ve Aktif Eşyaların Denge İncelemesi

### A. Silahların Mermi Saçılması Sorunu ve Dengelemesi
- **Eski Durum:** Silahlar seviye atladıkça (örneğin Lv.3 ve Lv.5'te) fazladan mermi saçıyordu. Bu durum mermi kirliliğine, performans düşüşüne ve pasif eşyaların değerini yitirmesine yol açıyordu.
- **Yeni Denge:**
  - Taban silahlardaki doğal mermi artışları kaldırıldı. Silah seviye atlamaları artık **taban hasar (+%35)** ve **saldırı hızı/cooldown (+%10)** artırmaktadır.
  - Ekstra mermi fırlatma özelliği sadece **Çoğaltıcı Mühür (passive_carbon_paper / extra_projectiles)** pasif eşyasına devredildi. Bu eşya seviye başına +1 mermi verir ve maksimum 2 seviyedir (+2 mermi sınırı).

### B. Yakın Düşman Hedefleme Önceliği
- Silahlar artık oyuncunun 120 piksel yarıçapındaki acil temas tehditlerini (`STRONGEST` veya `SECTOR` hedeflerinden bağımsız olarak) mutlak öncelikle vurmaktadır.
- Ölen düşmanlar ölüm animasyonu bitmeden derhal hedefleme grubundan çıkarılmaktadır.

### C. Pasif Eşya Denge Skalası
Tüm 19 pasif eşya matematiksel olarak gözden geçirilmiş ve kademeli artışları dengelenmiştir:
- **Kuvvet Tılsımı:** %20 Hasar artışı (lineer ölçekleme).
- **Zaman Mührü:** Saldırı bekleme süresini %15 azaltır (aşırı spami önlemek için çarpan tabanlı düşürülür).
- **Rüzgar Çizmeleri:** %15 Hareket hızı artışı.
- **Şövalye Zırhı:** %15 Hasar indirimi.
- **Yaşam Sargısı:** Saniyede +0.3 Can yenilenmesi.
- **Taş Maske:** Altın çarpanı %20.
- **Torrona'nın Kutusu:** 1-4. seviyelerde tüm istatistiklere +%5, 5. seviyede %25 lanet ve %25 XP çarpanı.
