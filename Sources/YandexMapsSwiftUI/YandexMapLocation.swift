import YandexMapsMobile

public struct YandexMapLocation {
  public let latitude: Double
  public let longitude: Double

  public init(latitude: Double, longitude: Double) {
    self.latitude = latitude
    self.longitude = longitude
  }
}

extension YandexMapLocation: Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    areDoublesEqual(lhs.latitude, rhs.latitude) &&
      areDoublesEqual(lhs.longitude, rhs.longitude)
  }

  private static func areDoublesEqual(_ a: Double, _ b: Double) -> Bool {
    fabs(a - b) < 0.000001
  }
}

internal extension YandexMapLocation {
  func toYMKPoint() -> YMKPoint {
    .init(latitude: latitude, longitude: longitude)
  }

  static func fromYMKPoint(_ point: YMKPoint) -> Self {
    .init(
      latitude: point.latitude,
      longitude: point.longitude
    )
  }
}
