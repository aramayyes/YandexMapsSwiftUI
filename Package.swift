// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to
// build this package.

import PackageDescription

let package = Package(
  name: "YandexMapsSwiftUI",
  platforms: [
    .iOS(.v13),
  ],
  products: [
    // Products define the executables and libraries a package produces, and
    // make them visible to other packages.
    .library(
      name: "YandexMapsSwiftUI",
      targets: ["YandexMapsSwiftUI"]
    ),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a
    // module or a test suite.
    // Targets can depend on other targets in this package, and on products in
    // packages this package depends on.
    .target(
      name: "YandexMapsSwiftUI",
      dependencies: [
        "YandexMapsMobile",
      ],
      resources: [
        .process("Resources"),
      ]
    ),
    .binaryTarget(
      name: "YandexMapsMobile",
      url: "https://github.com/c-villain/YandexMapsMobileLite/releases/download/4.3.1/YandexMapsMobile.xcframework.zip",
      checksum: "9bfb13051437f525b8cce99c96dc362af6e070a1fec3a8db966d33305b896529"
    ),
  ]
)
