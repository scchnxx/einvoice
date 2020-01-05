import Foundation
import RxSwift
import RxCocoa

extension InvoiceDetailViewModel {
    
    struct Input {
        var invoice: AnyObserver<Invoice?>
    }
    
    struct Output {
        var sellerName: Observable<String>
        var invoiceNumber: Observable<String>
        var randomNumber: Observable<String>
        var total: Observable<String>
    }
    
}

class InvoiceDetailViewModel: ViewModel {
    
    var input: Input
    var output: Output
    var disposeBag = DisposeBag()
    
    init() {
        let rxSellerName = BehaviorRelay(value: "")
        let rxInvoiceNumber = BehaviorRelay(value: "")
        let rxRandomNumber = BehaviorRelay(value: "")
        let rxTotal = BehaviorRelay(value: "")
        let rxInvoice = BehaviorSubject<Invoice?>(value: nil)
        
        input = Input(invoice: rxInvoice.asObserver())
        output = Output(sellerName: rxSellerName.asObservable(),
                        invoiceNumber: rxInvoiceNumber.asObservable(),
                        randomNumber: rxRandomNumber.asObservable(),
                        total: rxTotal.asObservable())
        
        rxInvoice
            .subscribe(onNext: { invoice in
                guard let invoice = invoice else { return }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd"
                
                _ = URLSession.shared.rx
                    .invQuery(InvHeader.self, parameters: [
                        .type: "QRCode",
                        .invNum: invoice.invoiceInfo.number,
                        .generation: "V2",
                        .invDate: formatter.string(from: invoice.invoiceInfo.date),
                    ])
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { header in
                        rxSellerName.accept(header.sellerName)
                    })
                rxInvoiceNumber.accept(invoice.invoiceInfo.number)
                rxRandomNumber.accept(invoice.invoiceInfo.random)
                rxTotal.accept("\(invoice.invoiceInfo.totalSales)")
            })
            .disposed(by: disposeBag)
    }
    
}
