# TextBeam

An iOS application that sends text via Bluetooth LE (BLE) to an Arduino Nano, which displays the received text on a Nokia 5110 LCD screen.

Nokia 5110 LCD ekranına Arduino Nano üzerinden Bluetooth LE (BLE) ile metin gönderen iOS uygulaması.

---

## Features / Özellikler

- **BLE Communication** — Connects to HM-10 module via CoreBluetooth (FFE0/FFE1 UUID)
- **Real-time LCD Simulation** — iOS screen mirrors the Nokia 5110 display (84×48 aspect ratio)
- **6-line scroll** — When the screen is full, lines shift upward just like the physical LCD
- **14-character limit** — Matches the Nokia 5110's character capacity per line
- **Connection status** — Live badge showing Connected / Scanning / Disconnected

---

- **BLE İletişimi** — CoreBluetooth ile HM-10 modülüne bağlanır (FFE0/FFE1 UUID)
- **Gerçek Zamanlı LCD Simülasyonu** — iOS ekranı Nokia 5110 ekranını yansıtır (84×48 oranı)
- **6 satır kaydırma** — Ekran dolunca satırlar yukarı kayar, tıpkı fiziksel LCD gibi
- **14 karakter limiti** — Nokia 5110'un satır başına karakter kapasitesiyle eşleşir
- **Bağlantı durumu** — Bağlandı / Bağlanıyor / Bağlantı Yok rozeti

---

## Hardware / Donanım

| Component | Details |
|-----------|---------|
| Microcontroller | Arduino Nano |
| Bluetooth Module | HM-10 (BLE) |
| Display | Nokia 5110 LCD (PCD8544, 84×48px) |

### Wiring / Bağlantı Şeması

**Nokia 5110 → Arduino Nano**

| 5110 Pin | Arduino Nano |
|----------|-------------|
| GND | GND |
| BL | 3.3V |
| VCC | 3.3V |
| CLK | A1 |
| DIN | A2 |
| DC | A3 |
| CE | A4 |
| RST | A5 |

**HM-10 → Arduino Nano**

| HM-10 Pin | Arduino Nano |
|-----------|-------------|
| TX | D2 |
| RX | D3 |
| VCC | 5V |
| GND | GND |

---

## Software / Yazılım

### iOS Requirements / iOS Gereksinimleri

- iOS 14+
- Xcode 15+
- Swift 5
- CoreBluetooth framework
- `NSBluetoothAlwaysUsageDescription` key in `Info.plist`

### Arduino Libraries / Arduino Kütüphaneleri

- `LCD5110_Basic`
- `SoftwareSerial`

---

## How It Works / Nasıl Çalışır

1. iOS app scans for BLE devices with service UUID `FFE0`
2. Connects to HM-10 module automatically
3. User types text (max 14 characters) and sends
4. Arduino receives text via `SoftwareSerial` and prints to Nokia 5110
5. iOS app mirrors the same text in the LCD simulation view

---

1. iOS uygulaması `FFE0` servis UUID'si ile BLE cihazlarını tarar
2. HM-10 modülüne otomatik bağlanır
3. Kullanıcı metin yazar (max 14 karakter) ve gönderir
4. Arduino `SoftwareSerial` ile metni alır ve Nokia 5110'a yazar
5. iOS uygulaması aynı metni LCD simülasyon görünümüne yansıtır

---

## Project Structure / Proje Yapısı

```
TextBeam/
├── iOS/
│   └── BluetoothViewController.swift
└── Arduino/
    └── TextBeam.ino
```

---

## License

MIT License — feel free to use, modify and distribute.

---

*Built with UIKit · CoreBluetooth · Arduino · Nokia 5110*
