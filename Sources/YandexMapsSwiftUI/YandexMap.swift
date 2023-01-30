import MapKit
import SwiftUI
import UIKit
import YandexMapsMobile

public struct YandexMap<Placemark: YandexMapPlacemark>: UIViewRepresentable {
  private typealias PlacemarkAdder = (
    _: YMKPoint,
    _: UIImage,
    _: YMKIconStyle
  ) -> YMKPlacemarkMapObject

  private typealias PlacemarkRemover = (_: YMKMapObject) -> Void

  @Binding public var position: YandexMapCameraPosition
  public let placemarks: [Placemark]
  public let cameraAnimationDuration: Float
  public let clusteringOptions: YandexMapClusteringOptions<Placemark>?
  public let placemarkTapAction: (Placemark) -> Bool

  public init(
    position: Binding<YandexMapCameraPosition>,
    placemarks: [Placemark],
    cameraAnimationDuration: Float = 1.0,
    clusteringOptions: YandexMapClusteringOptions<Placemark>? = nil,
    placemarkTapAction: @escaping (Placemark) -> Bool
  ) {
    _position = position
    self.placemarks = placemarks
    self.cameraAnimationDuration = cameraAnimationDuration
    self.clusteringOptions = clusteringOptions
    self.placemarkTapAction = placemarkTapAction
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(view: self)
  }
}

// MARK: - Make UIView.

extension YandexMap {
  public func makeUIView(context: Context) -> YMKMapView {
    // Create a map view.
    let mapView = YMKMapView()
    mapView.mapWindow.map.addCameraListener(with: context.coordinator)

    // Setup the map view.
    makeUserLocationLayer(mapView: mapView, context: context)
    makeAnnotationItems(mapView: mapView, context: context)

    return mapView
  }

  private func makeUserLocationLayer(mapView: YMKMapView, context: Context) {
    let mapKit = YMKMapKit.sharedInstance()
    let userLocationLayer = mapKit.createUserLocationLayer(
      with: mapView.mapWindow
    )
    userLocationLayer.setVisibleWithOn(true)
    userLocationLayer.isHeadingEnabled = false

    userLocationLayer.setObjectListenerWith(context.coordinator)
  }

  private func makeAnnotationItems(mapView: YMKMapView, context: Context) {
    if let clusteringOptions {
      // Create a clusterized placemark collection.
      let collection = mapView.mapWindow.map.mapObjects
        .addClusterizedPlacemarkCollection(with: context.coordinator)

      // Add the placemarks to clusters.
      for placemark in placemarks {
        context.coordinator.placemarkObjects[placemark.id] = createPlacemark(
          placemark,
          placemarkAdder: collection.addPlacemark(with:image:style:),
          listener: context.coordinator
        )
      }

      collection.clusterPlacemarks(
        withClusterRadius: clusteringOptions.radius,
        minZoom: clusteringOptions.minZoom
      )

      // Save the clusterized placemark collection.
      context.coordinator.clusterizedPlacemarkCollection = collection
    } else {
      // Add the placemarks to the map without clustering.
      for placemark in placemarks {
        context.coordinator.placemarkObjects[placemark.id] = createPlacemark(
          placemark,
          placemarkAdder: mapView.mapWindow.map.mapObjects
            .addPlacemark(with:image:style:),
          listener: context.coordinator
        )
      }
    }
  }
}

// MARK: - Update UIView.

extension YandexMap {
  public func updateUIView(_ uiView: YMKMapView, context: Context) {
    updateCameraPosition(uiView: uiView)
    updatePlacemarks(uiView, context: context)

    // Save current view state.
    context.coordinator.view = self
  }

  private func updateCameraPosition(uiView: YMKMapView) {
    let currentCameraPosition = YandexMapCameraPosition.fromYMKCameraPosition(
      uiView.mapWindow.map.cameraPosition
    )

    // Update the map's camera position only if needed.
    if currentCameraPosition != position {
      uiView.mapWindow.map.move(
        with: position.toYMKCameraPosition(),
        animationType: YMKAnimation(
          type: YMKAnimationType.smooth,
          duration: cameraAnimationDuration
        )
      )
    }
  }

  private func updatePlacemarks(_ uiView: YMKMapView, context: Context) {
    if let clusteringOptions,
       context.coordinator.clusterizedPlacemarkCollection == nil
    {
      // The placemarks were without clusters but now should be with clusters.
      movePlacemarksFromMapToClusters(
        uiView: uiView,
        context: context,
        clusteringOptions: clusteringOptions
      )
    } else if clusteringOptions == nil, let collection = context.coordinator
      .clusterizedPlacemarkCollection
    {
      // The placemarks were with clusters but now should be without clusters.
      movePlacemarksFromClustersToMap(
        uiView: uiView,
        context: context,
        clusterizedPlacemarkCollection: collection
      )
    } else {
      // Clustering existence hasn't been changed so the placemarks either
      // were with clusters and should continue be with clusters
      // or were without clusters and should continue be without clusters.
      updatePlacemarksChanges(uiView: uiView, context: context)
    }
  }
}

// MARK: - Helpers.

extension YandexMap {
  private func createPlacemark(
    _ placemark: Placemark,
    placemarkAdder: PlacemarkAdder,
    listener: YMKMapObjectTapListener
  ) -> YMKPlacemarkMapObject {
    let object = placemarkAdder(
      placemark.location.toYMKPoint(),
      placemark.image,
      placemark.style.toYMKIconStyle()
    )

    object.userData = placemark
    object.addTapListener(with: listener)

    return object
  }

  private func movePlacemarksFromMapToClusters(
    uiView: YMKMapView,
    context: Context,
    clusteringOptions: YandexMapClusteringOptions<Placemark>
  ) {
    // Remove all placemarks from the map.
    for placemarkObject in context.coordinator.placemarkObjects.values {
      uiView.mapWindow.map.mapObjects.remove(with: placemarkObject)
    }
    context.coordinator.placemarkObjects.removeAll()

    // Create a clusterized placemark collection.
    let collection = uiView.mapWindow.map.mapObjects
      .addClusterizedPlacemarkCollection(with: context.coordinator)

    // Add the placemarks to clusters.
    for placemark in placemarks {
      context.coordinator.placemarkObjects[placemark.id] = createPlacemark(
        placemark,
        placemarkAdder: collection.addPlacemark(with:image:style:),
        listener: context.coordinator
      )
    }

    collection.clusterPlacemarks(
      withClusterRadius: clusteringOptions.radius,
      minZoom: clusteringOptions.minZoom
    )

    // Save the clusterized placemark collection.
    context.coordinator.clusterizedPlacemarkCollection = collection
  }

  private func movePlacemarksFromClustersToMap(
    uiView: YMKMapView,
    context: Context,
    clusterizedPlacemarkCollection: YMKClusterizedPlacemarkCollection
  ) {
    // Remove all placemarks and clusters from the map.
    uiView.mapWindow.map.mapObjects.remove(with: clusterizedPlacemarkCollection)
    context.coordinator.placemarkObjects.removeAll()

    // Remove the clusterized placemark collection.
    context.coordinator.clusterizedPlacemarkCollection = nil

    // Add the placemarks to the map.
    for placemark in placemarks {
      context.coordinator.placemarkObjects[placemark.id] = createPlacemark(
        placemark,
        placemarkAdder: uiView.mapWindow.map.mapObjects
          .addPlacemark(with:image:style:),
        listener: context.coordinator
      )
    }
  }

  private func updatePlacemarksChanges(
    uiView: YMKMapView,
    context: Context
  ) {
    let placemarkAdder: PlacemarkAdder = context
      .coordinator
      .clusterizedPlacemarkCollection?
      .addPlacemark(with:image:style:)
      ??
      uiView
      .mapWindow.map.mapObjects
      .addPlacemark(with:image:style:)

    let placemarkRemover: PlacemarkRemover = context
      .coordinator
      .clusterizedPlacemarkCollection?
      .remove(with:)
      ?? uiView
      .mapWindow.map.mapObjects
      .remove(with:)

    // Find placemarks differences.
    let placemarksDifferences = placemarks.difference(
      from: context.coordinator.view.placemarks
    )

    // Find insertion and removal elements ids to detect placemark property
    // value changes.
    //
    // If insertions and removals both contain a change with a placemark
    // with the same id then that two changes (an insertion and a removal)
    // should be considered as a single placemark object change.
    //
    // So instead of removing the placemark object with some id and adding it
    // with new property values that placemark object can be updated.
    let insertionElementIDs = Set(
      placemarksDifferences.insertions.map(\.element.id)
    )
    let removalElementIDs = Set(
      placemarksDifferences.removals.map(\.element.id)
    )

    var existNonUpdatingChanges = false

    // Handle differences.
    for difference in placemarksDifferences {
      switch difference {
      case let .insert(_, placemark, _):
        // If this placemark (a placemark with same id) is also included in a
        // removal then this is the placemark object update case.
        if removalElementIDs.contains(placemark.id),
           let placemarkObject = context.coordinator
           .placemarkObjects[placemark.id]
        {
          // Update the placemark object.
          placemarkObject.geometry = placemark.location.toYMKPoint()
          placemarkObject.setIconWith(
            placemark.image,
            style: placemark.style.toYMKIconStyle()
          )
        } else {
          // Add a new placemark object.
          existNonUpdatingChanges = true
          context.coordinator
            .placemarkObjects[placemark.id] = createPlacemark(
              placemark,
              placemarkAdder: placemarkAdder,
              listener: context.coordinator
            )
        }
      case let .remove(_, placemark, _):
        // If this placemark (a placemark with same id) is also included in an
        // insertion then this is the placemark object update case. But there is
        // no need to do any updates since it is done in insertion case.
        if insertionElementIDs.contains(placemark.id),
           context.coordinator.placemarkObjects[placemark.id] != nil
        {
          continue
        }

        // Remove the placemark object.
        if let placemarkObject = context.coordinator.placemarkObjects
          .removeValue(forKey: placemark.id)
        {
          existNonUpdatingChanges = true
          placemarkRemover(placemarkObject)
        }
      }
    }

    // If there are any insertion or removal changes and clustering is used
    // then update the clusters.
    if existNonUpdatingChanges,
       let clusterizedPlacemarkCollection = context.coordinator
       .clusterizedPlacemarkCollection,
       let clusteringOptions
    {
      clusterizedPlacemarkCollection.clusterPlacemarks(
        withClusterRadius: clusteringOptions.radius,
        minZoom: clusteringOptions.minZoom
      )
    }
  }
}

// MARK: - Coordinator.

public extension YandexMap {
  class Coordinator: NSObject,
    YMKMapCameraListener,
    YMKUserLocationObjectListener,
    YMKMapObjectTapListener,
    YMKClusterListener,
    YMKClusterTapListener
  {
    var view: YandexMap
    var placemarkObjects: [Int: YMKPlacemarkMapObject] = [:]
    var clusterizedPlacemarkCollection: YMKClusterizedPlacemarkCollection?

    init(view: YandexMap) {
      self.view = view
    }

    public func onCameraPositionChanged(
      with _: YMKMap,
      cameraPosition: YMKCameraPosition,
      cameraUpdateReason reason: YMKCameraUpdateReason,
      finished _: Bool
    ) {
      guard reason != .application else {
        return
      }

      // Set view's camera position to current if they are different.
      let currentCameraPosition = YandexMapCameraPosition.fromYMKCameraPosition(
        cameraPosition
      )
      if view.position != currentCameraPosition {
        view.position = currentCameraPosition
      }
    }

    public func onObjectAdded(with view: YMKUserLocationView) {
      let image: UIImage
      if let path = Bundle.module.path(forResource: "circle", ofType: "png"),
         let uiImage = UIImage(contentsOfFile: path)
      {
        image = uiImage
      } else {
        image = UIImage(
          systemName: "circle.inset.filled"
        )!
      }

      let style = YMKIconStyle(
        anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
        rotationType: YMKRotationType.noRotation.rawValue as NSNumber,
        zIndex: 0,
        flat: true,
        visible: true,
        scale: 1,
        tappableArea: nil
      )

      view.arrow.setIconWith(
        image,
        style: style
      )
      view.pin.setIconWith(
        image,
        style: style
      )
    }

    public func onObjectRemoved(with _: YMKUserLocationView) {}

    public func onObjectUpdated(
      with _: YMKUserLocationView,
      event _: YMKObjectEvent
    ) {}

    public func onMapObjectTap(
      with mapObject: YMKMapObject,
      point _: YMKPoint
    ) -> Bool {
      if let placemarkObject = mapObject as? YMKPlacemarkMapObject,
         let placemark = placemarkObject.userData as? Placemark
      {
        return view.placemarkTapAction(placemark)
      }

      return false
    }

    public func onClusterAdded(with cluster: YMKCluster) {
      // Setup cluster image.
      if let image = view.clusteringOptions?.image {
        cluster.appearance.setIconWith(
          image(YandexMapCluster(
            size: cluster.size,
            location: .fromYMKPoint(cluster.appearance.geometry),
            placemarkObjects: cluster.placemarks
          ))
        )
      } else {
        cluster.appearance.setIconWith(clusterDefaultImage(cluster.size))
      }

      cluster.addClusterTapListener(with: self)
    }

    public func onClusterTap(with cluster: YMKCluster) -> Bool {
      if let options = view.clusteringOptions {
        return options.tapAction(YandexMapCluster(
          size: cluster.size,
          location: .fromYMKPoint(cluster.appearance.geometry),
          placemarkObjects: cluster.placemarks
        ))
      }

      return true
    }

    private func clusterDefaultImage(_ clusterSize: UInt) -> UIImage {
      let fontSize: CGFloat = 15
      let marginSize: CGFloat = 3
      let strokeSize: CGFloat = 3

      let scale = UIScreen.main.scale
      let text = (clusterSize as NSNumber).stringValue
      let font = UIFont.systemFont(ofSize: fontSize * scale)
      let size = text.size(withAttributes: [NSAttributedString.Key.font: font])

      let textRadius = sqrt(
        size.height * size.height + size.width * size.width
      ) / 2

      let internalRadius = textRadius + marginSize * scale
      let externalRadius = internalRadius + strokeSize * scale
      let iconSize = CGSize(
        width: externalRadius * 2,
        height: externalRadius * 2
      )

      UIGraphicsBeginImageContext(iconSize)
      let context = UIGraphicsGetCurrentContext()!

      context.setFillColor(UIColor.red.cgColor)
      context.fillEllipse(in: CGRect(
        origin: .zero,
        size: CGSize(width: 2 * externalRadius, height: 2 * externalRadius)
      ))

      context.setFillColor(UIColor.white.cgColor)
      context.fillEllipse(in: CGRect(
        origin: CGPoint(
          x: externalRadius - internalRadius,
          y: externalRadius - internalRadius
        ),
        size: CGSize(width: 2 * internalRadius, height: 2 * internalRadius)
      ))

      (text as NSString).draw(
        in: CGRect(
          origin: CGPoint(
            x: externalRadius - size.width / 2,
            y: externalRadius - size.height / 2
          ),
          size: size
        ),
        withAttributes: [
          NSAttributedString.Key.font: font,
          NSAttributedString.Key.foregroundColor: UIColor.black,
        ]
      )

      let image = UIGraphicsGetImageFromCurrentImageContext()!
      return image
    }
  }
}

// MARK: - CollectionDifference.Change.

private extension CollectionDifference.Change {
  var element: ChangeElement {
    switch self {
    case let .insert(_, element, _):
      return element
    case let .remove(_, element, _):
      return element
    }
  }

  var offset: Int {
    switch self {
    case let .insert(offset, _, _):
      return offset
    case let .remove(offset, _, _):
      return offset
    }
  }
}
