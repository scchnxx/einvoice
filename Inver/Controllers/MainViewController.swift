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
            _ = qrCodeScannerVC
            
        default:
            break
        }
    }

}

