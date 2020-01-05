import UIKit
import RxSwift
import RxCocoa

class InvoiceDetailViewController: UIViewController {
    
    let viewModel = InvoiceDetailViewModel()
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var sellerNameLabel: UILabel!
    @IBOutlet weak var invoiceNumberLabel: UILabel!
    @IBOutlet weak var randomNumberLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        
        Observable
            .combineLatest(viewModel.output.sellerName,
                           viewModel.output.invoiceNumber,
                           viewModel.output.randomNumber,
                           viewModel.output.total) { ($0, $1, $2, $3) }
            .subscribe(onNext: { (sellerName, number, randomNum, total) in
                self.sellerNameLabel.text = sellerName
                self.invoiceNumberLabel.text = number
                self.randomNumberLabel.text = randomNum
                self.totalLabel.text = total
            })
            .disposed(by: disposeBag)
    }
    
}
