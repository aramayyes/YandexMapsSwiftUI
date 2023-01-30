import UIKit

public protocol YandexMapPlacemark: Hashable {
  var id: Int { get }
  var location: YandexMapLocation { get }
  var image: UIImage { get }
  var style: YandexMapIconStyle { get }
}
