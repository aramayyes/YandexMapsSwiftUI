# YandexMapsSwiftUI

YandexMaps for SwifUI. Supports only iOS 13+.

This library uses YandexMapKit for iOS. See https://yandex.com/dev/maps/mapkit/doc/ios-quickstart/concepts/ios/quickstart.html


Requirements
------------ 

- Deployment target: iOS 13+
- Xcode 12+

Install
-------

### SwiftPM

```
https://github.com/aramayyes/YandexMapsSwiftUI
```

Setup
-----
1. Add `import YandexMapsMobile` to your `AppDelegate`
2. Set your API key in the `application:didFinishLaunchingWithOptions` method of the application delegate and instantiate the YMKMapKit object:
```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    YMKMapKit.setApiKey("Your API key")
    YMKMapKit.sharedInstance()
}
```

Usage
-----
- ### Without clustering
```swift
struct ExampleMapView: View {
  @StateObject var model = ExampleMapViewModel()

  var body: some View {
    YandexMap(
      position: $model.cameraPosition,
      placemarks: model.markers
    ) { marker in
     // Marker tap action.
    }
    .ignoresSafeArea()
  }
}
``` 

- ### With clustering
```swift
struct ExampleMapView: View {
  @StateObject var model = ExampleMapViewModel()

  var body: some View {
    YandexMap(
      position: $model.cameraPosition,
      placemarks: model.markers,
      cameraAnimationDuration: Float = 2.0,
      clusteringOptions: .init(
        radius: 60,
        minZoom: 14,
        tapAction: { cluster in // Cluster tap action.
          let zoom = model.cameraPosition.zoom + 2
          let azimuth = model.cameraPosition.azimuth
          let tilt = model.cameraPosition.tilt
          
          model.cameraPosition = YandexMapCameraPosition(
            center: YandexMapLocation(
              latitude: 40.183135,
              longitude: 44.515303
            ),
            zoom: zoom,
            azimuth: azimuth,
            tilt: tilt
          )

          return true
        }
      )
    ) { yandexMarker in
      // Marker tap action.
    }
    .ignoresSafeArea()
  }
``` 

### Camera position
To update camera position just update the `@Published` property. Also when user drags the map this property will be updated.
```swift
@MainActor class ExampleMapViewModel {
  ...

  @Published var cameraPosition = YandexMapCameraPosition(
    center: YandexMapLocation(
      latitude: 40.183135,
      longitude: 44.515303
    ),
    zoom: 12,
    azimuth: 0,
    tilt: 0
  )

  func moveTo(location: YandexMapLocation) {
    model.cameraPosition = YandexMapCameraPosition(
      center: location,
      zoom: zoom,
      azimuth: azimuth,
      tilt: tilt
    )
  }
```

### Placemarks
Should conform to `YandexMapPlacemark`.
```swift
public protocol YandexMapPlacemark: Hashable {
  /// Id of the placemark that will be used to detect this placemark change and avoid
  /// removing and adding it to the map on its every change.
  var id: Int { get } 

  /// Location of the placemark.
  var location: YandexMapLocation { get }
  
  /// Icon image of the placemark.
  var image: UIImage { get }
  
  /// Style of the placemark.
  var style: YandexMapIconStyle { get }
}
```

For `YandexMapIconStyle` see https://yandex.ru/dev/maps/mapkit/doc/ios-ref/full/Classes/YMKIconStyle.html

### CameraAnimationDuration
Map movement animation duration in seconds. Default = 1.0. 

### ClusteringOptions
Pass `nil` if clustering is not needed.
```swift
public struct YandexMapClusteringOptions<Placemark: YandexMapPlacemark> {
  /// See https://yandex.ru/dev/maps/mapkit/doc/ios-ref/full/Classes/YMKClusterizedPlacemarkCollection.html#-clusterPlacemarksWithClusterRadiusminZoom
  public let radius: Double
  
  /// See https://yandex.ru/dev/maps/mapkit/doc/ios-ref/full/Classes/YMKClusterizedPlacemarkCollection.html#-clusterPlacemarksWithClusterRadiusminZoom
  public let minZoom: UInt

  /// Image for the cluster. If nil, the default will be used.
  public let image: ((YandexMapCluster<Placemark>) -> UIImage)?
  
  /// Tap action for the cluster.
  public let tapAction: (YandexMapCluster<Placemark>) -> Bool
}
```

`YandexMapCluster<Placemark>` contains size of the placemark, location and `placemarks` which is a `lazy var`.

```swift
public struct YandexMapCluster<Placemark: YandexMapPlacemark> {
  public let size: UInt
  public let location: YandexMapLocation
  public lazy var placemarks: [Placemark]
}
```

### Placemark tap action.
Action when the placemark is tapped.

---
### NOTE: To use a custom SwiftUI view as a placemark icon image the extensions below can be used:
```swift
extension View {
  @MainActor func snapshot() -> UIImage {
    if #available(iOS 16.0, *) {
      let renderer = ImageRenderer(content: self)
      renderer.scale = UIScreen.main.scale
      return renderer.uiImage ?? UIImage()
    } else {
      let controller = UIHostingController(rootView: self)
      let view = controller.view
      let targetSize = controller.view.intrinsicContentSize
      view?.bounds = CGRect(origin: .zero, size: targetSize)
      view?.backgroundColor = .clear

      let window = UIWindow(frame: CGRect(origin: .zero, size: targetSize))
      window.addSubview(controller.view)
      window.makeKeyAndVisible()
      return controller.view.snapshot()
    }
  }
}

extension UIView {
  func snapshot() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()!
    layer.render(in: context)
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
  }
}
```