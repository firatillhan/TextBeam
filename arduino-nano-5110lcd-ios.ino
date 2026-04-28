// Sadece yazı yazdıran kod
#include <SoftwareSerial.h>
#include <LCD5110_Basic.h>


// HC-05 veya HC-06 Bluetooth modülü için pin tanımlamaları
SoftwareSerial BT(2, 3); 

// Nokia 5110 LCD pinleri: (SCK, DIN, DC, CS, RST)
LCD5110 myGLCD(A1,A2,A3,A4,A5);

extern uint8_t SmallFont[];

// Her satır için bir string dizisi oluştur
// Toplam 6 satır için
String lines[6];
int lineIndex = 0; // Hangi satırda olduğumuzu takip etmek için

void setup() {
  // LCD ekranı başlat
  myGLCD.InitLCD();
  myGLCD.setFont(SmallFont);
  // Seri iletişimi başlat (Hata ayıklama için)
  Serial.begin(9600);
  
  // Bluetooth seri iletişimini başlat
  BT.begin(9600);

  Serial.println("Arduino ve Bluetooth baglantisi hazir.");
  
  // Başlangıçta ekran boş olacak
  myGLCD.clrScr();
    myGLCD.print("Waiting text...", CENTER, 0); // Merkeze yakın bir konuma yaz

}

// LCD ekranındaki tüm satırları çizmek için yardımcı fonksiyon
void drawLines() {
  myGLCD.clrScr(); // Önce ekranı temizle
  for (int i = 0; i < 6; i++) {
    // String'den char* tipine dönüştürme ve ekrana yazma
    myGLCD.print(lines[i].c_str(), CENTER, i * 8); // Her satır için 8 piksel aralık bırak
  }
}

void loop() {
  // Bluetooth'tan yeni veri gelip gelmediğini kontrol et
  if (BT.available()) {
    // Bluetooth'tan gelen veriyi bir satır olarak oku
    String incomingText = BT.readStringUntil('\n'); 
    
    // Satır sonu karakterlerini ve gereksiz boşlukları temizle
    incomingText.trim(); 

    // Gelen metni Serial Monitörde göster
    Serial.print("Gelen metin: ");
    Serial.println(incomingText);

    if (lineIndex < 6) {
      // Ekran dolmadıysa, yeni satıra ekle
      lines[lineIndex] = incomingText;
      lineIndex++;
    } else {
      // Ekran dolduysa (6. satırdaysa)
      // En üstteki satırı sil (dizideki ilk elemanı) ve diğerlerini kaydır
      for (int i = 0; i < 5; i++) {
        lines[i] = lines[i+1];
      }
      // Yeni metni en alt satıra (6. satır) yerleştir
      lines[5] = incomingText;
    }
    
    // Güncellenmiş satırları ekrana çiz
    drawLines();
  }
}