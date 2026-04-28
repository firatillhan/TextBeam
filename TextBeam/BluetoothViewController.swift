//
//  ViewController.swift
//  TextBeam
//
//  Created by Fırat İlhan on 28.04.2026.
//

import UIKit
import CoreBluetooth



class BluetoothViewController: UIViewController {



    // MARK: - Properties
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var writeCharacteristic: CBCharacteristic?

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

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
        return view
    }()

    private let connectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Bağlanıyor..."
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
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
        label.letterSpacing(0.5)
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

    private let lcdTextLabel: UILabel = {
        let label = UILabel()
        label.text = "BEKLIYOR..."
        label.font = UIFont(name: "Courier-Bold", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor(red: 0.1, green: 0.23, blue: 0.36, alpha: 1)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
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
        tf.font = UIFont(name: "Courier", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .regular)
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
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, connectionBadge, lcdContainerCard, inputCard].forEach {
            contentView.addSubview($0)
        }

        connectionBadge.addSubview(connectionDot)
        connectionBadge.addSubview(connectionLabel)

        lcdContainerCard.addSubview(lcdSectionLabel)
        lcdContainerCard.addSubview(lcdOuterView)
        lcdOuterView.addSubview(lcdScreenView)
        lcdScreenView.addSubview(lcdTextLabel)

        inputCard.addSubview(inputSectionLabel)
        inputCard.addSubview(messageTextField)
        inputCard.addSubview(sendButton)
    }

    private func setupConstraints() {
        [scrollView, contentView, titleLabel, connectionBadge, connectionDot,
         connectionLabel, lcdContainerCard, lcdSectionLabel, lcdOuterView,
         lcdScreenView, lcdTextLabel, inputCard, inputSectionLabel,
         messageTextField, sendButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let padding: CGFloat = 20
        // 84:48 oranı → ekran genişliği - 2*padding - 2*cardPadding = net lcd genişliği
        let lcdWidth = UIScreen.main.bounds.width - (padding * 2) - 32
        let lcdHeight = lcdWidth * (48.0 / 84.0)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            // Badge
            connectionBadge.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            connectionBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            connectionBadge.heightAnchor.constraint(equalToConstant: 28),

            connectionDot.centerYAnchor.constraint(equalTo: connectionBadge.centerYAnchor),
            connectionDot.leadingAnchor.constraint(equalTo: connectionBadge.leadingAnchor, constant: 10),
            connectionDot.widthAnchor.constraint(equalToConstant: 8),
            connectionDot.heightAnchor.constraint(equalToConstant: 8),

            connectionLabel.centerYAnchor.constraint(equalTo: connectionBadge.centerYAnchor),
            connectionLabel.leadingAnchor.constraint(equalTo: connectionDot.trailingAnchor, constant: 6),
            connectionLabel.trailingAnchor.constraint(equalTo: connectionBadge.trailingAnchor, constant: -10),

            // LCD Card
            lcdContainerCard.topAnchor.constraint(equalTo: connectionBadge.bottomAnchor, constant: 20),
            lcdContainerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            lcdContainerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

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

            lcdTextLabel.centerXAnchor.constraint(equalTo: lcdScreenView.centerXAnchor),
            lcdTextLabel.centerYAnchor.constraint(equalTo: lcdScreenView.centerYAnchor),
            lcdTextLabel.leadingAnchor.constraint(equalTo: lcdScreenView.leadingAnchor, constant: 8),
            lcdTextLabel.trailingAnchor.constraint(equalTo: lcdScreenView.trailingAnchor, constant: -8),

            // Input Card
            inputCard.topAnchor.constraint(equalTo: lcdContainerCard.bottomAnchor, constant: 14),
            inputCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            inputCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            inputCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

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

    // MARK: - Actions
    @objc private func sendMessage() {
        guard let text = messageTextField.text, !text.isEmpty else { return }
        let uppercased = text.uppercased()
        lcdTextLabel.text = uppercased
        sendViaBluetooth(text: uppercased)
        messageTextField.text = ""
    }

    private func sendViaBluetooth(text: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let data = text.data(using: .utf8) else { return }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

    private func updateConnectionStatus(connected: Bool) {
        DispatchQueue.main.async {
            self.connectionLabel.text = connected ? "Bağlandı" : "Bağlanıyor..."
            let alpha: CGFloat = connected ? 1.0 : 0.5
            self.connectionDot.alpha = alpha
            self.connectionLabel.alpha = alpha
        }
    }
}

// MARK: - UITextField Extension (letter spacing)
extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        guard let text = self.text else { return }
        let attributed = NSAttributedString(string: text, attributes: [.kern: spacing])
        self.attributedText = attributed
    }
}

// MARK: - UITextFieldDelegate
extension BluetoothViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name, name.contains("HC-06") || name.contains("HC-05") else { return }
        connectedPeripheral = peripheral
        central.stopScan()
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        updateConnectionStatus(connected: true)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        updateConnectionStatus(connected: false)
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach { characteristic in
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                writeCharacteristic = characteristic
            }
        }
    }
}
