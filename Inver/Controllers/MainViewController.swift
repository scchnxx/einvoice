import UIKit
import RxSwift
import RxCocoa

class MainViewController: UIViewController {
    
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let qrCodeScannerVC as QRCodeScannerViewController:
            qrCodeScannerVC.viewModel.output.detectedObjects
                .drive(onNext: { objects in
                    if objects.count == 2 {
                        if let paper = Invoice(object1: objects[0], object2: objects[1]) {
                            print(paper.invoiceInfo.number)
                            for detail in paper.productDetails {
                                print("\tName: \(detail.name), Quantity: \(detail.quantity), Price: \(detail.price)")
                            }
                            return
                        } else {
                            print("err")
                        }
                    }
                })
                .disposed(by: disposeBag)
            
        default:
            break
        }
    }

}

