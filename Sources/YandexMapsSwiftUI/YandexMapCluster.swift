import YandexMapsMobile

public struct YandexMapCluster<Placemark: YandexMapPlacemark> {
  public let size: UInt
  public let location: YandexMapLocation
  private let placemarkObjects: [YMKPlacemarkMapObject]

  internal init(
    size: UInt,
    location: YandexMapLocation,
    placemarkObjects: [YMKPlacemarkMapObject]
  ) {
    self.size = size
    self.location = location
    self.placemarkObjects = placemarkObjects
  }

  public lazy var placemarks: [Placemark] = placemarkObjects
    .compactMap { placemarkObject in
      placemarkObject.userData as? Placemark
    }
}
