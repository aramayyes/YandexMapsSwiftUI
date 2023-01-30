import Foundation
import YandexMapsMobile

public struct YandexMapIconStyle {
  public let anchorX: Double?
  public let anchorY: Double?
  public let scale: Double?
  public let zIndex: Int?
  public let isVisible: Bool?
  public let isFlat: Bool?

  public init(
    anchorX: Double? = nil,
    anchorY: Double? = nil,
    scale: Double? = nil,
    zIndex: Int? = nil,
    isVisible: Bool? = nil,
    isFlat: Bool? = nil
  ) {
    self.anchorX = anchorX
    self.anchorY = anchorY
    self.scale = scale
    self.zIndex = zIndex
    self.isVisible = isVisible
    self.isFlat = isFlat
  }
}

extension YandexMapIconStyle: Hashable {}

internal extension YandexMapIconStyle {
  func toYMKIconStyle() -> YMKIconStyle {
    var anchor: CGPoint?
    if let x = anchorX, let y = anchorY {
      anchor = CGPoint(x: x, y: y)
    }

    return .init(
      anchor: anchor == nil ? nil : NSValue(cgPoint: anchor!),
      rotationType: nil,
      zIndex: zIndex as? NSNumber,
      flat: isFlat == nil ? nil : isFlat! as NSNumber,
      visible: isVisible == nil ? nil : isVisible! as NSNumber,
      scale: scale as? NSNumber,
      tappableArea: nil
    )
  }
}
