import UIKit
import AVFoundation
import RxSwift
import RxCocoa

class QRCodeScannerViewController: UIViewController {
    
    let viewModel = QRCodeScannerViewModel()
    var disposeBag = DisposeBag()
    var focusFieldTimer: Timer?
    
    var qrCodeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor(red: 1, green: 1, blue: 0, alpha: 0.3).cgColor
        layer.strokeColor = UIColor.yellow.cgColor
        layer.lineWidth = 3
        return layer
    }()
    var focusFieldLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        let rect = CGRect(origin: .zero, size: CGSize(width: 80, height: 80))
        layer.strokeColor = UIColor.yellow.cgColor
        layer.borderColor = UIColor.yellow.cgColor
        layer.borderWidth = 1
        layer.opacity = 0
        layer.path = {
            let path = CGMutablePath()
            let len = CGFloat(8)
            path.addLines(between: [CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.midX, y: rect.minY + len)])
            path.addLines(between: [CGPoint(x: rect.midX, y: rect.maxY), CGPoint(x: rect.midX, y: rect.maxY - len)])
            path.addLines(between: [CGPoint(x: rect.minX, y: rect.midY), CGPoint(x: rect.minX + len, y: rect.midY)])
            path.addLines(between: [CGPoint(x: rect.maxX, y: rect.midY), CGPoint(x: rect.maxX - len, y: rect.midY)])
            return path
        }()
        layer.frame = rect
        return layer
    }()
    var previewLayer: AVCaptureVideoPreviewLayer!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.output.session
            .subscribe(onNext: { session in
                session.startRunning()
                self.setupPreviewView(with: session)
                self.setupDetectedObjectBindings()
                self.errorLabel.isHidden = true
            }, onError: { error in
                self.disposeBag = DisposeBag()
                self.errorLabel.isHidden = false
            }).disposed(by: disposeBag)
    }
    
    private func setupPreviewView(with session: AVCaptureSession) {
        // Preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.layer.bounds
        previewView.layer.addSublayer(previewLayer)
        // QR code layer
        qrCodeLayer.frame = previewView.layer.bounds
        previewView.layer.addSublayer(qrCodeLayer)
        // Set layer delegate
        previewView.layer.delegate = self
        // Focus field view
        previewView.layer.addSublayer(focusFieldLayer)
    }
    
    private func setupDetectedObjectBindings() {
        viewModel.output.detectedObjects
            .drive(onNext: { objects in
                self.qrCodeLayer.path = objects.reduce(CGMutablePath()) { path, object in
                    self.drawQRCodeField(object: object, in: path)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.output.focusedPoint
            .drive(onNext: showFocusField)
            .disposed(by: disposeBag)
    }
    
    private func drawQRCodeField(object: AVMetadataMachineReadableCodeObject, in path: CGMutablePath) -> CGMutablePath {
        if !object.corners.isEmpty {
            let transformedObject = previewLayer.transformedMetadataObject(for: object) as! AVMetadataMachineReadableCodeObject
            let corners = transformedObject.corners
            
            path.move(to: corners[0])
            
            (0..<corners.count)
                .map { ($0 + 1) % corners.count }
                .forEach { path.addLine(to: corners[$0]) }
            
            path.closeSubpath()
        }
        return path
    }
    
    private func showFocusField(at focusPoint: CGPoint) {
        focusFieldTimer?.invalidate()
        
        CATransaction.begin()
        defer { CATransaction.commit() }
        CATransaction.setDisableActions(true)
        
        let fieldSize = focusFieldLayer.frame.size
        let origin = previewLayer.layerPointConverted(fromCaptureDevicePoint: focusPoint)
            .applying(CGAffineTransform.identity.translatedBy(x: -fieldSize.width / 2, y: -fieldSize.height / 2))
        
        focusFieldLayer.frame.origin = origin
        focusFieldLayer.opacity = 1
        focusFieldTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
            self.focusFieldLayer.opacity = 0
        })
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard var location = touches.first?.location(in: previewView) else { return }
        location = previewLayer.captureDevicePointConverted(fromLayerPoint: location)
        viewModel.input.focus.onNext(location)
    }
    
}

extension QRCodeScannerViewController: CALayerDelegate {
    
    func layoutSublayers(of layer: CALayer) {
        previewLayer.frame = layer.bounds
        qrCodeLayer.frame = layer.bounds
    }
    
}
