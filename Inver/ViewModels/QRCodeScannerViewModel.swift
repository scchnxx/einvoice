import Foundation
import AVFoundation
import RxSwift
import RxCocoa

enum CameraError: Error {
    case initialCameraFailed
    case initialSessionFailed
}

extension QRCodeScannerViewModel {
    
    struct Input {
        fileprivate var detectedObject: AnyObserver<[AVMetadataMachineReadableCodeObject]>
        fileprivate var invoice: AnyObserver<Invoice>
        var focus: AnyObserver<CGPoint>
        var active: AnyObserver<Bool>
    }
    
    struct Output {
        var session: Observable<AVCaptureSession>
        var detectedObjects: Driver<[AVMetadataMachineReadableCodeObject]>
        var invoice: Observable<Invoice>
        var focusedPoint: Driver<CGPoint>
    }
    
}

class QRCodeScannerViewModel: NSObject, ViewModel {
    
    var input: Input
    var output: Output
    var disposeBag = DisposeBag()
    
    override init() {
        let rxSession = AsyncSubject<AVCaptureSession>()
        let rxFocusPoint = PublishSubject<CGPoint>()
        let rxFocus = PublishSubject<CGPoint>()
        let rxDetectedObject = PublishSubject<[AVMetadataMachineReadableCodeObject]>()
        let rxInvoice = PublishSubject<Invoice>()
        let rxActive = BehaviorSubject(value: true)
        
        input = Input(detectedObject: rxDetectedObject.asObserver(),
                      invoice: rxInvoice.asObserver(),
                      focus: rxFocus.asObserver(),
                      active: rxActive.asObserver())
        output = Output(session: rxSession.asObserver(),
                        detectedObjects: rxDetectedObject.asDriver(onErrorJustReturn: []),
                        invoice: rxInvoice.asObservable(),
                        focusedPoint: rxFocusPoint.asDriver(onErrorJustReturn: .zero))
        
        super.init()
        
        do {
            guard let device = AVCaptureDevice.default(for: .video) else { throw CameraError.initialCameraFailed }
            
            let session = try setupCamera(device: device)
            
            rxSession.onNext(session)
            rxSession.onCompleted()
            
            rxFocus
                .subscribe(onNext: { focusPoint in
                    do {
                        try self.focus(at: focusPoint, for: device)
                        rxFocusPoint.onNext(focusPoint)
                    } catch { }
                })
                .disposed(by: disposeBag)
            
            rxActive
                .distinctUntilChanged()
                .subscribe(onNext: { isActive in
                    if isActive {
                        self.input.detectedObject.onNext([])
                        session.startRunning()
                    } else {
                        session.stopRunning()
                    }
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
        
        if let object1 = readableCodeObjects.first, let object2 = readableCodeObjects.last, readableCodeObjects.count == 2 {
            if let invoice = Invoice(object1: object1, object2: object2) {
                input.invoice.onNext(invoice)
            }
        }
        
        input.detectedObject.onNext(readableCodeObjects)
    }
    
}
