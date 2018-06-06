//
//  ViewController.swift
//  SudokuSolver
//
//  Created by Khang Lam on 5/14/18.
//  Copyright © 2018 Khang Lam. All rights reserved.
//

import UIKit
import AVFoundation
import TesseractOCR

class ViewController: UIViewController, G8TesseractDelegate{
    
    var captureSession = AVCaptureSession()
    var backCamera : AVCaptureDevice?
    var frontCamera : AVCaptureDevice?
    var currentCamera : AVCaptureDevice?
    
    var photoOutput : AVCapturePhotoOutput?
    
    var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    
    var image : UIImage?
    var rotatedImg : UIImage?
    
    let openCV = OpenCVWrapper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
    }
    
    func setupCaptureSession()
    {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice()
    {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        for device in devices {
            if device.position == AVCaptureDevice.Position.back
            {
                backCamera = device
            }
            else if device.position == AVCaptureDevice.Position.front
            {
                frontCamera = device
            }
            currentCamera = backCamera
        }
    }
    
    func setupInputOutput()
    {
        do{
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
        }
        catch{
            print(error)
        }
    }
    
    func setupPreviewLayer()
    {
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    }
    
    func startRunningCaptureSession()
    {
        captureSession.startRunning()
    }
    
/*    func startTesseract()
    {
        if let tesseract = G8Tesseract(language: "eng+fra")
        {
            tesseract.engineMode = .tesseractCubeCombined
            // 3
            tesseract.pageSegmentationMode = .auto
            // 4
            tesseract.image = image?.g8_blackAndWhite()
            // tesseract.image = UIImage(named: "Lenore_print_version")?.g8_blackAndWhite()
            tesseract.recognize()
            // 6
       //     DispatchQueue.main.async {
              //  self.identifierLabel.text = (tesseract.recognizedText)
                //   print(tesseract.recognizedText)
         //   }
            print(tesseract.recognizedText)
            // textView.text = tesseract.recognizedText
        }
    }*/

    
    @IBAction func cameraTapped(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self) // this for some reason needed the extension for ViewController : AVCapturePhotoCaptureDelegate
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPreview_Segue"
        {
            let previewVC = segue.destination as! PreviewViewController
            //self.image = openCV.uiImage(fromCVMat: openCV.cvMat(from: self.image))
            previewVC.image =  self.image
        }
    }
    
}
extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output:AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation()
        {
            image = UIImage(data: imageData)
      //      startTesseract()

            image = openCV.makeGray(image)
            performSegue(withIdentifier: "showPreview_Segue", sender: nil)
        }
    }
}


    




