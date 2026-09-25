# IvorSMF

A Standard MIDI Files parser, normalizer, validator, and formatter.

[![Swift 6.3](https://img.shields.io/badge/Swift-6.3-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS-lightgrey.svg)](https://developer.apple.com)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/eBardX/IvorSMF/blob/main/LICENSE.md)

* [Overview](#overview)
* [Requirements](#requirements)
* [Installation](#installation)
    * [Swift Package Manager](#spm_installation)
* [Quick Start](#quick_start)
* [Documentation](#documentation)
* [Reference Documentation](#reference_documentation)
* [Credits](#credits)
* [License](#license)

## <a name="overview">Overview</a>

The IvorSMF framework provides a [Standard MIDI Files][smf] parser, normalizer,
validator, and formatter written in Swift. It targets [RP-001 Standard MIDI
Files 1.0][rp001], as extended by [RP-017 SMF Lyric Meta Event
Definition][rp017], [RP-019 SMF Device Name and Program Name Meta
Events][rp019], and [RP-026 SMF Language and Display Extensions][rp026], with a
strict-concurrency-ready, value-type API.

IvorSMF builds on two companion packages: [IvorMIDI][ivormidi] supplies the
MIDI channel messages carried by MIDI events, and [IvorSMPTE][ivorsmpte]
supplies the SMPTE frame rates and timecode values used by timecode-based time
divisions and SMPTE offset meta-events.

Everything flows through a small, explicit pipeline of four value types, each
with a no-argument initializer:

 Stage     | Type            | Input → Output
:-----     |:----            |:--------------
 Parse     | `SMFParser`     | `Data` → `SMFSequence`
 Normalize | `SMFNormalizer` | `SMFSequence` → `SMFSequence` (canonical)
 Validate  | `SMFValidator`  | `SMFSequence` → validated `SMFSequence`
 Format    | `SMFFormatter`  | `SMFSequence` → `Data`

The pipeline is gated by two flags on `SMFSequence`: a sequence must be
normalized before it can be validated, and validated before it can be formatted.
See the [usage guide][guide] for a full walkthrough of the API.

## <a name="requirements">Requirements</a>

* iOS 18.0+ / macOS 15.0+
* Swift 6.3 toolchain
* Swift 6 language mode

## <a name="installation">Installation</a>

### <a name="spm_installation">Swift Package Manager</a>

IvorSMF is distributed exclusively through the [Swift Package Manager][spm].

To add IvorSMF to a Swift package, add it to the `dependencies` in your
`Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/eBardX/IvorSMF.git",
             .upToNextMajor(from: "1.0.0"))
]
```

Then add `IvorSMF` to the dependencies of any target that uses it:

```swift
.target(name: "MyTarget",
        dependencies: [.product(name: "IvorSMF",
                                package: "IvorSMF")])
```

To add IvorSMF to an Xcode project, choose **File ▸ Add Package Dependencies…**
and enter the repository URL:

```
https://github.com/eBardX/IvorSMF.git
```

IvorSMF depends on [IvorMIDI][ivormidi], [IvorSMPTE][ivorsmpte], and
[XestiTools][xestitools]; the Swift Package Manager resolves them automatically.

## <a name="quick_start">Quick Start</a>

Take an SMF file from `Data` all the way back to `Data`:

```swift
import Foundation
import IvorSMF

let data = try Data(contentsOf: url)

// 1. Parse raw bytes into a typed sequence. Always tolerant — recoverable
//    deviations are reported as diagnostics rather than thrown.
let (parsed, diagnostics) = try SMFParser().parse(data)

// 2. Normalize to canonical form (a single trailing End-of-Track per track).
let (normalized, changes) = SMFNormalizer().normalize(parsed)

// 3. Validate against the SMF 1.0 specification (+ extensions).
let (validated, issues) = try SMFValidator().validate(normalized)

guard issues.isEmpty
else { issues.forEach { print($0.message) }; return }

// 4. Format back to binary data.
let output = try SMFFormatter().format(validated)
```

Each stage is independent, so you can stop at the AST or round-trip through the
formatter. For the complete story — the AST models and error handling — see the
[usage guide][guide].

## <a name="documentation">Documentation</a>

* [Using IvorSMF][guide] — a guide to using the public API, published as part
  of the DocC documentation.
* Every public declaration carries a DocC comment; a few call out the
  relevant page of the [RP-001 specification][smf] where a clamping or other
  spec-mandated behavior needs justification.

## <a name="reference_documentation">Reference Documentation</a>

Full [reference documentation][refdoc] is available courtesy of [DocC][docc].

## <a name="credits">Credits</a>

John Gary Pusey (ebardx@gmail.com)

## <a name="license">License</a>

IvorSMF is available under [the MIT license][license].

[docc]:         https://www.swift.org/documentation/docc/
[guide]:        https://eBardX.github.io/ivor-packages-docs/documentation/ivorsmf/usingivorsmf
[ivormidi]:     https://github.com/eBardX/IvorMIDI
[ivorsmpte]:    https://github.com/eBardX/IvorSMPTE
[license]:      https://github.com/eBardX/IvorSMF/blob/main/LICENSE.md
[refdoc]:       https://eBardX.github.io/ivor-packages-docs/documentation/ivorsmf
[rp001]:	    https://midi.org/standard-midi-files-specification
[rp017]:	    https://midi.org/smf-lyric-meta-event-definition
[rp019]:	    https://midi.org/smf-device-name-and-program-name-meta-events
[rp026]:	    https://midi.org/smf-language-and-display-extensions
[smf]:          https://midi.org/standard-midi-files
[spm]:          https://swift.org/package-manager/
[xestitools]:   https://github.com/eBardX/XestiTools
