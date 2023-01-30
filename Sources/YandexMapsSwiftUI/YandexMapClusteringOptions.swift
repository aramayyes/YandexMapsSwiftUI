import UIKit

public struct YandexMapClusteringOptions<Placemark: YandexMapPlacemark> {
  public let radius: Double
  public let minZoom: UInt
  public let image: ((YandexMapCluster<Placemark>) -> UIImage)?
  public let tapAction: (YandexMapCluster<Placemark>) -> Bool

  public init(
    radius: Double,
    minZoom: UInt,
    image: ((YandexMapCluster<Placemark>) -> UIImage)? = nil,
    tapAction: @escaping (YandexMapCluster<Placemark>) -> Bool
  ) {
    self.radius = radius
    self.minZoom = minZoom
    self.image = image
    self.tapAction = tapAction
  }
}
