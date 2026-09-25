# ``IvorSMF``

@Metadata {
    @PageColor(blue)
}

A Standard MIDI Files parser, normalizer, validator, and formatter.

## Overview

The IvorSMF framework provides a [Standard MIDI
Files](https://midi.org/standard-midi-files) parser, normalizer, validator, and
formatter written in Swift. It targets [RP-001 Standard MIDI Files
1.0](https://midi.org/standard-midi-files-specification), as extended by [RP-017
SMF Lyric Meta Event
Definition](https://midi.org/smf-lyric-meta-event-definition), [RP-019 SMF
Device Name and Program Name Meta
Events](https://midi.org/smf-device-name-and-program-name-meta-events), and
[RP-026 SMF Language and Display
Extensions](https://midi.org/smf-language-and-display-extensions), with a
strict-concurrency-ready, value-type API.

IvorSMF builds on two companion packages: IvorMIDI supplies the MIDI channel
messages carried by MIDI events, and IvorSMPTE supplies the SMPTE frame rates
and timecode values used by timecode-based time divisions and SMPTE offset
meta-events.

### The pipeline

Everything flows through a small, explicit pipeline of four value types, each a
`Sendable` value type with a no-argument initializer:

 Stage     | Type               | Input → Output
:-----     |:----               |:--------------
 Parse     | ``SMFParser``      | `Data` → ``SMFSequence``
 Normalize | ``SMFNormalizer``  | ``SMFSequence`` → ``SMFSequence`` (canonical)
 Validate  | ``SMFValidator``   | ``SMFSequence`` → validated ``SMFSequence``
 Format    | ``SMFFormatter``   | ``SMFSequence`` → `Data`

An ``SMFSequence`` carries two Boolean state flags that enforce the order of the
pipeline: a sequence must be normalized before it can be validated, and
validated before it can be formatted. Both normalization and validation are
idempotent, so it is always safe to run the full pipeline:

```swift
import Foundation
import IvorSMF

let data = try Data(contentsOf: url)

let (parsed, diagnostics) = try SMFParser().parse(data)
let (normalized, changes) = SMFNormalizer().normalize(parsed)
let (validated, issues)   = try SMFValidator().validate(normalized)

guard issues.isEmpty else {
    issues.forEach { print($0.message) }
    return
}

let output = try SMFFormatter().format(validated)  // back to SMF
```

See <doc:UsingIvorSMF> for a full guide to each stage, the models, and error
handling.

## Topics

### Guides

- <doc:UsingIvorSMF>

### Processing

- ``SMFParser``
- ``SMFNormalizer``
- ``SMFValidator``
- ``SMFFormatter``

### Sequence model

- ``SMFSequence``
- ``SMFTrack``
- ``SMFEvent``

### Event content

- ``SMFMetaMessage``
- ``SMFSysExMessage``

### Time and division

- ``SMFDivision``
- ``SMFTickRate``
- ``SMFTimeCode``
- ``SMFEventTime``
- ``SMFTempo``
- ``SMFTimeSignature``

### Keys, text, and identifiers

- ``SMFKeySignature``
- ``SMFText``
- ``SMFData2Value``
- ``SMFFormat``
