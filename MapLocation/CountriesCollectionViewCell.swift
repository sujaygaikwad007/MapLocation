import UIKit
import MapKit

protocol showCountryBtnDelegate{
    func buttonTapped(cell: CountriesCollectionViewCell)
}

class CountriesCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var CountriesUiView: UIView!
    
    @IBOutlet weak var lblCountryName: UILabel!
    
    @IBOutlet weak var FlagImg: UIImageView!
    
    @IBOutlet weak var showLocationBtn: UIButton!
    
    var delegate: showCountryBtnDelegate!
    
    
    
    @IBAction func showLocationBtn(_ sender: UIButton) {
        delegate?.buttonTapped(cell: self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
