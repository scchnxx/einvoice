import UIKit
import AVFoundation
import RxSwift
import RxCocoa

class MainViewController: UIViewController {
    
    var disposeBag = DisposeBag()
    var detectedObjects: Disposable?
    
    var qrCodeScannerVC: QRCodeScannerViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func didDetectedQRCode(object1: AVMetadataMachineReadableCodeObject, object2: AVMetadataMachineReadableCodeObject) {
        if let paper = Invoice(object1: object1, object2: object2) {
            print(paper.invoiceInfo.number)
            for detail in paper.productDetails {
                print("\tName: \(detail.name), Quantity: \(detail.quantity), Price: \(detail.price)")
            }
            return
        } else {
            print("err")
        }
    }
    
    func startDetection() {
        detectedObjects?.dispose()
        detectedObjects = qrCodeScannerVC?.viewModel.output.detectedObjects
            .filter({ $0.count == 2 })
            .drive(onNext: { objects in
                self.didDetectedQRCode(object1: objects[0], object2: objects[1])
            })
        detectedObjects?.disposed(by: disposeBag)
    }
    
    func stopDetection() {
        detectedObjects?.dispose()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let qrCodeScannerVC as QRCodeScannerViewController:
            self.qrCodeScannerVC = qrCodeScannerVC
            startDetection()
            
        default:
            break
        }
    }

}

