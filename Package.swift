// swift-tools-version: 6.3

// © 2025–2026 John Gary Pusey (see LICENSE.md)

import PackageDescription

let swiftSettings: [SwiftSetting] = [.defaultIsolation(nil),
                                     .enableUpcomingFeature("ExistentialAny"),
                                     .enableUpcomingFeature("ImmutableWeakCaptures"),
                                     .enableUpcomingFeature("InferIsolatedConformances"),
                                     .enableUpcomingFeature("InternalImportsByDefault"),
                                     .enableUpcomingFeature("MemberImportVisibility"),
                                     .enableUpcomingFeature("NonisolatedNonsendingByDefault")]

let package = Package(name: "IvorSMF",
                      platforms: [.iOS(.v18),
                                  .macOS(.v15)],
                      products: [.library(name: "IvorSMF",
                                          targets: ["IvorSMF"])],
                      dependencies: [.package(url: "https://github.com/eBardX/IvorMIDI.git",
                                              branch: "v2-main"),
                                     .package(url: "https://github.com/eBardX/IvorSMPTE.git",
                                              branch: "develop"),
                                     .package(url: "https://github.com/eBardX/XestiTools.git",
                                              .upToNextMajor(from: "10.0.0"))],
                      targets: [.target(name: "IvorSMF",
                                        dependencies: [.product(name: "IvorMIDI",
                                                                package: "IvorMIDI"),
                                                       .product(name: "IvorSMPTE",
                                                                package: "IvorSMPTE"),
                                                       .product(name: "XestiTools",
                                                                package: "XestiTools")],
                                        swiftSettings: swiftSettings),
                                .testTarget(name: "IvorSMFTests",
                                            dependencies: [.target(name: "IvorSMF"),
                                                           .product(name: "IvorMIDI",
                                                                    package: "IvorMIDI"),
                                                           .product(name: "IvorSMPTE",
                                                                    package: "IvorSMPTE"),
                                                           .product(name: "XestiTools",
                                                                    package: "XestiTools")],
                                            resources: [.process("TestFixtures")],
                                            swiftSettings: swiftSettings)],
                      swiftLanguageModes: [.v6])
