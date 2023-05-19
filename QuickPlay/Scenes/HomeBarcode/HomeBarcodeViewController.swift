//
//  HomeBarcodeViewController.swift
//  QuickPlay
//
//  Created by Ertürk Alan on 17.05.2023.
//

import UIKit
import AVKit
import AVFoundation

final class HomeBarcodeViewController: UIViewController {
    
    //AVFoundation
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrcodeFrameView: UIView?
    
    var playerViewController = AVPlayerViewController()
    var playerView = AVPlayer()
    
    //UI
    private var scanButton: UIButton!
    private var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
    }
    
    private func configureUI() {
        view.backgroundColor = .systemYellow
        navigationItem.title = "QuickPlay"
        self.navigationController!.navigationBar.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 20, weight: .bold)]
        
        //Scan Button
        var configuration = UIButton.Configuration.gray()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 20, weight:.medium)
            return outgoing
        }
        scanButton = UIButton(configuration: configuration)
        scanButton.setTitle("Scan and play a video", for:.normal)
        scanButton.setTitleColor(.black, for: .normal)
        scanButton.layer.cornerRadius = 10
        
        scanButton.addTarget(self, action: #selector(scanButtonPressed), for: .touchUpInside)
        view.addSubview(scanButton)
        scanButton.anchorWithCenter(centerX: view.centerXAnchor, centerY: view.centerYAnchor)
    }
    
    @objc private func scanButtonPressed() {
        // Get the back facing camera
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            return
        }
        do{
            // Get an instance of the AVCaptureDeviceInput class using the previous device object
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            //Set the input device on the capture session
            if captureSession.inputs.isEmpty {
                self.captureSession.addInput(input)
            }
            
            //Initialize a AVCAptureMetadataOutput object and set it as the output device to the capture session
            let captureMetaDataOutput = AVCaptureMetadataOutput()
            if captureSession.outputs.isEmpty {
                captureSession.addOutput(captureMetaDataOutput)
                //Set delegate and use default dispatch queue to execute the callback
                captureMetaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                captureMetaDataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128]
            }
            
            //Initialize the vide preview layer and add it as a sublayer to the viewPreview view's layer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            //Start video capture
            self.captureSession.startRunning()
            
            //Initialize QR Code Frame
            qrcodeFrameView = UIView()
            if let qrcodeFrameView = qrcodeFrameView {
                qrcodeFrameView.layer.borderColor = UIColor.systemYellow.cgColor
                qrcodeFrameView.layer.borderWidth = 5
                view.addSubview(qrcodeFrameView)
                view.bringSubviewToFront(qrcodeFrameView)
            }
            
            //UI Close Button
            closeButton = UIButton()
            closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
            closeButton.setImage(closeButton.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
            closeButton.tintColor = .systemYellow
            closeButton.backgroundColor = nil
            closeButton.frame.size.height = 50
            closeButton.frame.size.width = 50
            closeButton.contentHorizontalAlignment = .fill
            closeButton.contentVerticalAlignment = .fill
            
            closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
            closeButton.center = CGPoint(x: view.frame.size.width/2, y: view.frame.size.height - 140)
            view.addSubview(closeButton)
            view.bringSubviewToFront(closeButton)
        } catch {
            print(error)
            return
        }
    }
    
    @objc private func closeButtonPressed() {
        if captureSession.isRunning {
            videoPreviewLayer?.removeFromSuperlayer()
            qrcodeFrameView?.removeFromSuperview()
            closeButton.removeFromSuperview()
            captureSession.stopRunning()
            }
    }
}


extension HomeBarcodeViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if metadataObjects.count == 0 {
            qrcodeFrameView?.frame = .zero
            print ("No code found")
            return
        }
        let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObject.type == .qr || metadataObject.type == .code128 {
            if let barcodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObject){
                qrcodeFrameView?.frame = barcodeObject.bounds
            }
            
            if let qrValue = metadataObject.stringValue {
                print ("Code value is = \(qrValue)")
               
                if captureSession.isRunning {
                    self.videoPreviewLayer?.removeFromSuperlayer()
                    self.qrcodeFrameView?.removeFromSuperview()
                    self.closeButton?.removeFromSuperview()
                    self.captureSession.stopRunning()
                    }
                let url: URL = URL(string: qrValue)!
                
                let videoAsset = AVAsset(url: url)

                let assetLength = Float(videoAsset.duration.value) / Float(videoAsset.duration.timescale)

                if assetLength > 0 {
                    if captureSession.isRunning {
                        captureSession.stopRunning()
                    }
                    playerView = AVPlayer(url: url as URL)
                    playerViewController.player = playerView
                    
                    self.present(playerViewController, animated: true) {
                        self.playerViewController.player?.play()
                    }
                } else {
                    let alert = UIAlertController(title: "Error", message: "Something Went Wrong", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { UIAlertAction in
                        alert.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alert, animated: true)
                }
                
            }
        }
    }
    
}
