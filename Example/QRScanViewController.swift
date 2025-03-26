//
//  QRScanViewController.swift
//  Example
//
//  Created by indianrenters on 12/02/25.
//

import UIKit
import AVFoundation

class QRScanViewController: UIViewController {
    let session = AVCaptureSession()
    
    // MARK: - Constants

    private enum Constants {
      static let alertTitle = "Scanning is not supported"
      static let alertMessage = "Your device does not support scanning a code from an item. Please use a device with a camera."
      static let alertButtonTitle = "OK"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestCameraAccess { granted in
            if granted {
                // Start the QR code scanner
                self.setupCamera()
            } else {
                // Handle the case where permission is denied
                print("Camera access denied")
                
                    let alert = UIAlertController(title: "Camera Access Needed",
                                                  message: "Please enable camera access in Settings to scan QR codes.",
                                                  preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    })

                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

                    self.present(alert, animated: true)
            }
        }
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: - set up camera

    func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            let output = AVCaptureMetadataOutput()

            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            session.addInput(input)
            session.addOutput(output)
            
            output.metadataObjectTypes = [.qr]
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            
            view.layer.addSublayer(previewLayer)
            
            session.startRunning()
        } catch {

            showAlert()
            print(error)
        }
    }
    
    // MARK: - Alert

    func showAlert() {
            let alert = UIAlertController(title: Constants.alertTitle,
                                          message: Constants.alertMessage,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Constants.alertButtonTitle,
                                          style: .default))
            present(alert, animated: true)
    }
    
    func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .notDetermined:
            // Request permission if not determined yet
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .restricted, .denied:
            // If permission is restricted or denied, inform the user
            completion(false)
        case .authorized:
            // Permission granted
            completion(true)
        @unknown default:
            // Handle future cases
            completion(false)
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScanViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {

        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  metadataObject.type == .qr,
                  let stringValue = metadataObject.stringValue else { return }
        
        print(stringValue)
    }
}
