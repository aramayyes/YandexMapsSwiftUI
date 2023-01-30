import YandexMapsMobile

public struct YandexMapCameraPosition {
  public let center: YandexMapLocation
  public let zoom: Float
  public let azimuth: Float
  public let tilt: Float

  public init(
    center: YandexMapLocation,
    zoom: Float,
    azimuth: Float,
    tilt: Float
  ) {
    self.center = center
    self.zoom = zoom
    self.azimuth = azimuth
    self.tilt = tilt
  }
}

extension YandexMapCameraPosition: Equatable {}

internal extension YandexMapCameraPosition {
  func toYMKCameraPosition() -> YMKCameraPosition {
    .init(
      target: center.toYMKPoint(),
      zoom: zoom,
      azimuth: azimuth,
      tilt: tilt
    )
  }

  static func fromYMKCameraPosition(_ position: YMKCameraPosition) -> Self {
    .init(
      center: .fromYMKPoint(position.target),
      zoom: position.zoom,
      azimuth: position.azimuth,
      tilt: position.tilt
    )
  }
}
