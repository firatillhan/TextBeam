//
//  ViewController.swift
//  TextBeam
//
//  Created by Fırat İlhan on 28.04.2026.
//

import UIKit
import CoreBluetooth

private enum ConnectionState {
    case connected, scanning, bluetoothOff
}

class BluetoothViewController: UIViewController {

    // MARK: - Properties
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?

    private let HM10_SERVICE_UUID = CBUUID(string: "FFE0")
    private let HM10_CHARACTERISTIC_UUID = CBUUID(string: "FFE1")
    private let maxCharacters = 14
    private let maxLines = 6
    private var lines: [String] = []

    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Bluetooth Kontrolcü"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let connectionBadge: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 0.13)
        view.layer.cornerRadius = 14
        return view
    }()

    private let connectionDot: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
        view.layer.cornerRadius = 4
        view.alpha = 0.5
        return view
    }()

    private let connectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Bağlanıyor..."
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
        label.alpha = 0.5
        return label
    }()

    private let lcdContainerCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.11, alpha: 1)
        view.layer.cornerRadius = 20
        return view
    }()

    private let lcdSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "NOKIA 5110"
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor(white: 0.55, alpha: 1)
        return label
    }()

    private let lcdOuterView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.1, alpha: 1)
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(white: 0.2, alpha: 1).cgColor
        return view
    }()

    private let lcdScreenView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.66, green: 0.79, blue: 0.91, alpha: 1)
        view.layer.cornerRadius = 4
        return view
    }()

    // 6 satır için 6 ayrı label
    private var lcdLineLabels: [UILabel] = {
        return (0..<6).map { _ in
            let label = UILabel()
            label.font = UIFont(name: "Courier-Bold", size: 30) ?? .monospacedSystemFont(ofSize: 30, weight: .bold)
            label.textColor = UIColor(red: 0.1, green: 0.23, blue: 0.36, alpha: 1)
            label.textAlignment = .center
            return label
        }
    }()

    private let inputCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.11, alpha: 1)
        view.layer.cornerRadius = 20
        return view
    }()

    private let inputSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Gönderilecek yazı"
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(white: 0.55, alpha: 1)
        return label
    }()

    private let messageTextField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = UIColor(white: 0.17, alpha: 1)
        tf.layer.cornerRadius = 12
        tf.textColor = .white
        tf.font = UIFont(name: "Courier-Bold", size: 20) ?? .monospacedSystemFont(ofSize: 20, weight: .bold)
        tf.attributedPlaceholder = NSAttributedString(
            string: "Komut yaz...",
            attributes: [.foregroundColor: UIColor(white: 0.28, alpha: 1)]
        )
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .allCharacters
        tf.returnKeyType = .send
        return tf
    }()

    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1)
        btn.layer.cornerRadius = 12
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let image = UIImage(systemName: "arrow.right", withConfiguration: config)
        btn.setImage(image, for: .normal)
        btn.tintColor = .white
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
        setupUI()
        setupConstraints()
        setupActions()
        centralManager = CBCentralManager(delegate: self, queue: nil)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)

        // Başlangıç metni — Arduino ile aynı
        lcdLineLabels[0].text = "Waiting text.."
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let screenHeight = lcdScreenView.bounds.height
        let screenWidth = lcdScreenView.bounds.width
        guard screenHeight > 0 else { return }
        let lineHeight = screenHeight / 6
        for (i, label) in lcdLineLabels.enumerated() {
            label.frame = CGRect(
                x: 0,
                y: CGFloat(i) * lineHeight,
                width: screenWidth,
                height: lineHeight
            )
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        [titleLabel, connectionBadge, lcdContainerCard, inputCard].forEach {
            view.addSubview($0)
        }
        connectionBadge.addSubview(connectionDot)
        connectionBadge.addSubview(connectionLabel)
        lcdContainerCard.addSubview(lcdSectionLabel)
        lcdContainerCard.addSubview(lcdOuterView)
        lcdOuterView.addSubview(lcdScreenView)
        lcdLineLabels.forEach { lcdScreenView.addSubview($0) }
        inputCard.addSubview(inputSectionLabel)
        inputCard.addSubview(messageTextField)
        inputCard.addSubview(sendButton)
    }

    private func setupConstraints() {
        [titleLabel, connectionBadge, connectionDot, connectionLabel,
         lcdContainerCard, lcdSectionLabel, lcdOuterView, lcdScreenView,
         inputCard, inputSectionLabel, messageTextField, sendButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let padding: CGFloat = 20
        let lcdWidth = UIScreen.main.bounds.width - (padding * 2) - 32
        let lcdHeight = lcdWidth * (48.0 / 84.0)
        let lineHeight = lcdHeight / 6 // ekran iç alanını 6'ya böl

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),

            connectionBadge.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            connectionBadge.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            connectionBadge.heightAnchor.constraint(equalToConstant: 28),

            connectionDot.centerYAnchor.constraint(equalTo: connectionBadge.centerYAnchor),
            connectionDot.leadingAnchor.constraint(equalTo: connectionBadge.leadingAnchor, constant: 10),
            connectionDot.widthAnchor.constraint(equalToConstant: 8),
            connectionDot.heightAnchor.constraint(equalToConstant: 8),

            connectionLabel.centerYAnchor.constraint(equalTo: connectionBadge.centerYAnchor),
            connectionLabel.leadingAnchor.constraint(equalTo: connectionDot.trailingAnchor, constant: 6),
            connectionLabel.trailingAnchor.constraint(equalTo: connectionBadge.trailingAnchor, constant: -10),

            lcdContainerCard.topAnchor.constraint(equalTo: connectionBadge.bottomAnchor, constant: 20),
            lcdContainerCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            lcdContainerCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            lcdSectionLabel.topAnchor.constraint(equalTo: lcdContainerCard.topAnchor, constant: 16),
            lcdSectionLabel.leadingAnchor.constraint(equalTo: lcdContainerCard.leadingAnchor, constant: 16),

            lcdOuterView.topAnchor.constraint(equalTo: lcdSectionLabel.bottomAnchor, constant: 10),
            lcdOuterView.centerXAnchor.constraint(equalTo: lcdContainerCard.centerXAnchor),
            lcdOuterView.widthAnchor.constraint(equalToConstant: lcdWidth),
            lcdOuterView.heightAnchor.constraint(equalToConstant: lcdHeight),
            lcdOuterView.bottomAnchor.constraint(equalTo: lcdContainerCard.bottomAnchor, constant: -16),

            lcdScreenView.topAnchor.constraint(equalTo: lcdOuterView.topAnchor, constant: 8),
            lcdScreenView.leadingAnchor.constraint(equalTo: lcdOuterView.leadingAnchor, constant: 8),
            lcdScreenView.trailingAnchor.constraint(equalTo: lcdOuterView.trailingAnchor, constant: -8),
            lcdScreenView.bottomAnchor.constraint(equalTo: lcdOuterView.bottomAnchor, constant: -8),

            inputCard.topAnchor.constraint(equalTo: lcdContainerCard.bottomAnchor, constant: 14),
            inputCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            inputCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            inputSectionLabel.topAnchor.constraint(equalTo: inputCard.topAnchor, constant: 16),
            inputSectionLabel.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor, constant: 16),

            messageTextField.topAnchor.constraint(equalTo: inputSectionLabel.bottomAnchor, constant: 8),
            messageTextField.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor, constant: 16),
            messageTextField.heightAnchor.constraint(equalToConstant: 44),
            messageTextField.bottomAnchor.constraint(equalTo: inputCard.bottomAnchor, constant: -16),

            sendButton.centerYAnchor.constraint(equalTo: messageTextField.centerYAnchor),
            sendButton.leadingAnchor.constraint(equalTo: messageTextField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputCard.trailingAnchor, constant: -16),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
        ])

    }

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        messageTextField.delegate = self
    }

    // MARK: - LCD Güncelleme
    private func updateLCDDisplay(with text: String) {
        if lines.count < maxLines {
            lines.append(text)
        } else {
            lines.removeFirst()
            lines.append(text)
        }
        // Label'ları güncelle
        for (i, label) in lcdLineLabels.enumerated() {
            label.text = i < lines.count ? lines[i] : ""
        }
    }

    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func sendMessage() {
        guard let text = messageTextField.text, !text.isEmpty else { return }
        let trimmed = String(text.prefix(maxCharacters))
        updateLCDDisplay(with: trimmed)
        sendData(trimmed + "\n")
        messageTextField.text = ""
    }

    private func sendData(_ text: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let data = text.data(using: .utf8) else {
            print("Hata: Bluetooth bağlantısı hazır değil.")
            return
        }
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        print("Gönderildi: \(text)")
    }

    private func updateConnectionStatus(_ state: ConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectionLabel.text = "Bağlandı"
                self.connectionDot.backgroundColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
                self.connectionDot.alpha = 1.0
                self.connectionLabel.alpha = 1.0
            case .scanning:
                self.connectionLabel.text = "Bağlanıyor..."
                self.connectionDot.backgroundColor = UIColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1)
                self.connectionDot.alpha = 1.0
                self.connectionLabel.alpha = 1.0
            case .bluetoothOff:
                self.connectionLabel.text = "Bağlantı Yok"
                self.connectionDot.backgroundColor = UIColor(red: 0.9, green: 0.27, blue: 0.27, alpha: 1)
                self.connectionDot.alpha = 1.0
                self.connectionLabel.alpha = 0.4
            }
        }
    }}

// MARK: - UITextFieldDelegate
extension BluetoothViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let current = textField.text ?? ""
        let newLength = current.count + string.count - range.length
        return newLength <= maxCharacters
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: [HM10_SERVICE_UUID], options: nil)
            updateConnectionStatus(.scanning)

        case .poweredOff:
            updateConnectionStatus(.bluetoothOff)
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([HM10_SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        updateConnectionStatus(.bluetoothOff)
        centralManager.scanForPeripherals(withServices: [HM10_SERVICE_UUID], options: nil)
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([HM10_CHARACTERISTIC_UUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == HM10_CHARACTERISTIC_UUID {
                writeCharacteristic = characteristic
                updateConnectionStatus(.connected)
                return
            }
        }
    }
}
