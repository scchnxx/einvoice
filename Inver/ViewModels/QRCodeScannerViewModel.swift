import Foundation
import AVFoundation
import RxSwift
import RxCocoa

enum CameraError: Error {
    case initialCameraFailed
    case initialSessionFailed
}

extension QRCodeScannerViewModel {
    
    struct InternalInput {
        fileprivate var detectedObject: AnyObserver<[AVMetadataMachineReadableCodeObject]>
    }
    
    struct Input {
        var focus: AnyObserver<CGPoint>
    }
    
    struct Output {
        var session: Observable<AVCaptureSession>
        var detectedObjects: Driver<[AVMetadataMachineReadableCodeObject]>
        var focusedPoint: Driver<CGPoint>
    }
    
}

class QRCodeScannerViewModel: NSObject, ViewModel {
    
    private var internalInput: InternalInput
    
    var input: Input
    var output: Output
    var disposeBag = DisposeBag()
    
    override init() {
        let rxSession = AsyncSubject<AVCaptureSession>()
        let rxFocusPoint = PublishSubject<CGPoint>()
        let rxFocus = PublishSubject<CGPoint>()
        let rxDetectedObject = PublishSubject<[AVMetadataMachineReadableCodeObject]>()
        
        internalInput = InternalInput(detectedObject: rxDetectedObject.asObserver())
        input = Input(focus: rxFocus.asObserver())
        output = Output(session: rxSession.asObserver(),
                        detectedObjects: rxDetectedObject.asDriver(onErrorJustReturn: []),
                        focusedPoint: rxFocusPoint.asDriver(onErrorJustReturn: .zero))
        
        super.init()
        
        do {
            guard let device = AVCaptureDevice.default(for: .video) else { throw CameraError.initialCameraFailed }
            
            rxSession.onNext(try setupCamera(device: device))
            rxSession.onCompleted()
            
            rxFocus
                .subscribe(onNext: { focusPoint in
                    do {
                        try self.focus(at: focusPoint, for: device)
                        rxFocusPoint.onNext(focusPoint)
                    } catch { }
                })
                .disposed(by: disposeBag)
        } catch {
            rxSession.onError(error)
        }
    }
    
    private func setupCamera(device: AVCaptureDevice) throws -> AVCaptureSession {
        guard let device = AVCaptureDevice.default(for: .video) else { throw CameraError.initialSessionFailed }
        
        let session = AVCaptureSession()
        let deviceInput = try AVCaptureDeviceInput(device: device)
        let photoOutput = AVCapturePhotoOutput()
        let metadataOutput = AVCaptureMetadataOutput()
        
        guard session.canAddInput(deviceInput),
            session.canAddOutput(photoOutput),
            session.canAddOutput(metadataOutput) else { throw CameraError.initialSessionFailed }
        
        session.addInput(deviceInput)
        session.addOutput(photoOutput)
        session.addOutput(metadataOutput)
        
        photoOutput.isHighResolutionCaptureEnabled = true
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        metadataOutput.metadataObjectTypes = [.qr]
        
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }
        
        session.startRunning()
        
        return session
    }
    
    private func focus(at focusPoint: CGPoint, for device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer {
            device.unlockForConfiguration()
        }
        
        device.focusPointOfInterest = focusPoint
        device.focusMode = .autoFocus
        device.exposurePointOfInterest = focusPoint
        device.exposureMode = .continuousAutoExposure
    }
    
}

extension QRCodeScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let readableCodeObjects = metadataObjects.compactMap { $0 as? AVMetadataMachineReadableCodeObject }
        
        internalInput.detectedObject.onNext(readableCodeObjects)
    }
    
}
