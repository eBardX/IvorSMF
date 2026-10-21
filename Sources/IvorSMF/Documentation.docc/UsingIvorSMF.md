# Using IvorSMF

Take Standard MIDI File bytes from `Data` to a validated syntax tree, and back
to `Data`.

## Overview

IvorSMF exposes four processing types. Each is a `Sendable` value type with a
no-argument initializer and a single primary method:

 Type              | Method                | Result
:----              |:------                |:------
 ``SMFParser``     | `parse(_:)`           | `(SMFSequence, [SMFParser.Diagnostic])`
 ``SMFNormalizer`` | `normalize(_:)`       | `(SMFSequence, [SMFNormalizer.Change])`
 ``SMFValidator``  | `validate(_:)`        | `(SMFSequence, [SMFValidator.Issue])`
 ``SMFFormatter``  | `format(_:)`          | `Data`

An ``SMFSequence`` carries two Boolean state flags that enforce the order of the
pipeline:

- **`isNormalized`** — `validate(_:)` throws unless this is `true`.
- **`isValidated`** — `format(_:)` throws unless this is `true`.

So the canonical order is **parse → normalize → validate → format**:

```swift
let (parsed, diagnostics)  = try SMFParser().parse(data)
let (normalized, changes)  = SMFNormalizer().normalize(parsed)
let (validated, issues)    = try SMFValidator().validate(normalized)

guard issues.isEmpty
else { /* handle issues */ return }

let output = try SMFFormatter().format(validated)
```

Both `normalize(_:)` and `validate(_:)` are idempotent — calling them on a
sequence that is already normalized or validated returns it unchanged — so it is
always safe to run the full pipeline.

## Parsing

``SMFParser`` decodes raw binary data into an ``SMFSequence``:

```swift
let (sequence, diagnostics) = try SMFParser().parse(data)
```

The parser is always tolerant. It performs only byte/structural recovery, and
reports each repair as an ``SMFParser/Diagnostic``:

- ``SMFParser/Diagnostic/chunkLengthClamped(declared:available:)`` — a chunk’s
  declared length exceeded the remaining data, so it was clamped to what was
  available.
- ``SMFParser/Diagnostic/dataAfterEndOfTrackSkipped(byteCount:)`` — a track
  chunk had data after its End-of-Track event, so the extra bytes were skipped.
- ``SMFParser/Diagnostic/invalidChunkTypeSkipped(_:)`` — a chunk’s type was not
  four ASCII characters, so the chunk was skipped like any other unrecognized
  chunk.
- ``SMFParser/Diagnostic/metaEventLengthClamped(type:declared:expected:)`` — a
  recognized fixed-length meta-event declared more data bytes than its type
  defines, so the surplus bytes were ignored.
- ``SMFParser/Diagnostic/metaEventLengthInvalid(type:declared:expected:)`` — a
  fixed-length meta-event declared fewer data bytes than its type defines, so
  it was kept as ``SMFMetaMessage/unknown(_:_:)``.
- ``SMFParser/Diagnostic/strayRealTimeByteSkipped`` — a stray system real-time
  byte in the event stream was skipped.
- ``SMFParser/Diagnostic/trackCountMismatch(declared:actual:)`` — the header’s
  track count did not match the number of `MTrk` chunks found.
- ``SMFParser/Diagnostic/truncatedEventSkipped`` — a track chunk ended partway
  through an event, so the incomplete event was skipped and the track ended
  there.
- ``SMFParser/Diagnostic/unknownFormatReadAsFormat1(_:)`` — the header declared
  a format other than 0, 1, or 2, so the tracks were read as format 1, as RP-001
  allows.
- ``SMFParser/Diagnostic/variableLengthQuantityClamped`` — a variable-length
  quantity exceeded the 0x0FFFFFFF maximum, so it was clamped to that maximum.

Diagnostics are always returned, never thrown; each has a human-readable
`message`:

```swift
for diagnostic in diagnostics {
    print(diagnostic.message)
}
```

The parser throws ``SMFParser/Error`` only when no sequence can be produced at
all — for example a missing or truncated header chunk, or bytes that cannot be
decoded as any recognized event.

An 0xF7 system exclusive event is read as a
``SMFSysExMessage/continuation(_:)`` packet while a multi-packet message is
still open (that is, after a packet that does not end with 0xF7), and as an
``SMFSysExMessage/escape(_:)`` otherwise. Deviations the model itself can represent —
including a track with no terminal End-of-Track event, or a format 0 file with
more than one track — are left intact by the parser, merely flagged with a
diagnostic; they become an ``SMFNormalizer/Change`` and, if still present, an
``SMFValidator/Issue`` further down the pipeline, not a parse-time concern.

```swift
do {
    let (sequence, _) = try SMFParser().parse(data)
} catch let error as SMFParser.Error {
    print(error.message)
}
```

## Normalizing

``SMFNormalizer`` mechanically canonicalizes a sequence, returning a new
sequence whose `isNormalized` flag is `true`, together with a list of the
changes it applied:

```swift
let (normalized, changes) = SMFNormalizer().normalize(sequence)

for change in changes {
    print(change.message)      // what was changed
    print(change.trackIndex)   // which track, or nil for a sequence-wide change
}
```

Canonical form requires several things:

1. Each track must have exactly one End-of-Track meta-event, as the final event,
   at a tick greater than or equal to every other event in the track. The
   normalizer brings every track into this form data-preservingly: it removes
   all End-of-Track events, then appends a single one at the latest tick of any
   event in the track, including the removed End-of-Track events (or tick zero
   if the track is otherwise empty). An End-of-Track gives a track its exact
   length, so it is never moved earlier, and no musical event is ever dropped.
2. A format 0 sequence must have exactly one track; a format 0 sequence with
   more than one track is reinterpreted as format 1, which has no such
   restriction.
3. Within a track, sequence-number, sequence/track-name, SMPTE-offset, and
   device-name meta-events must appear at the start of the track: at time zero,
   ahead of any transmittable (MIDI or system exclusive) event.
4. In a format 1 sequence with more than one track, tempo, time-signature,
   SMPTE-offset, and sequence-number meta-events must appear only in the first
   track, which holds the tempo map.
5. Every system exclusive message must end with 0xF7, and no transmittable event
   may appear between the packets of a multi-packet message. An open message is
   terminated by appending 0xF7 to its final packet when the track ends or
   another transmittable event arrives; a continuation packet left with no
   message to continue becomes the escape that a reader would take it for.

``SMFNormalizer/Change`` reports each fix applied:

- **`coercedFormat(from:to:)`** — the sequence declared format 0 but had more
  than one track; it was reinterpreted as format 1. This is a sequence-wide
  change, so `trackIndex` is `nil`.
- **`convertedSysExContinuationToEscape(trackIndex:)`** — the track had a
  system exclusive continuation packet with no open message to continue; it was
  converted to an escape.
- **`insertedEndOfTrack(trackIndex:)`** — the track had no End-of-Track; one was
  appended.
- **`relocatedDeviceName(trackIndex:)`**,
  **`relocatedSequenceNumber(trackIndex:)`**,
  **`relocatedSequenceTrackName(trackIndex:)`**, and
  **`relocatedSMPTEOffset(trackIndex:)`** — the track had that meta-event
  somewhere other than its start; it was moved to time zero, ahead of any
  transmittable event.
- **`relocatedEndOfTrack(trackIndex:)`** — the track had one or more
  End-of-Track events that were not already the sole final event (a premature
  End-of-Track with later events, and/or duplicates); they were consolidated
  into a single trailing one.
- **`relocatedSequenceNumberToFirstTrack(trackIndex:)`**,
  **`relocatedSMPTEOffsetToFirstTrack(trackIndex:)`**,
  **`relocatedTempo(trackIndex:)`**, and
  **`relocatedTimeSignature(trackIndex:)`** — the track had that meta-event, but
  the sequence is format 1 with more than one track; the event was moved to
  track 0. If a moved event is later than track 0’s End-of-Track, track 0 also
  reports `relocatedEndOfTrack(trackIndex:)`.
- **`terminatedSysEx(trackIndex:)`** — the track had a system exclusive message
  that did not end with 0xF7; 0xF7 was appended to its final packet.

Normalization automatically fixes every ``SMFValidator/Issue`` case that has a
deterministic fix, so a normalized sequence never has
``SMFValidator/Issue/missingEndOfTrack(trackIndex:)``,
``SMFValidator/Issue/eventAfterEndOfTrack(trackIndex:)``,
``SMFValidator/Issue/unterminatedSysEx(trackIndex:)``, or
``SMFValidator/Issue/orphanSysExContinuation(trackIndex:)``. Issues that require a
judgment call, such as ``SMFValidator/Issue/unencodableText(trackIndex:)``, are
left to ``SMFValidator`` and the caller — normalization never touches them.

## Validating

``SMFValidator`` checks a **normalized** sequence against the Standard MIDI
Files specification:

```swift
let (validated, issues) = try SMFValidator().validate(normalized)

if issues.isEmpty {
    // `validated.isValidated` is now true.
} else {
    issues.forEach { print($0.message) }
}
```

- If the sequence has not been normalized, `validate(_:)` throws
  ``SMFValidator/Error/notNormalized``.
- If any issues are found, the returned sequence is the **input unchanged** (its
  `isValidated` flag stays `false`). Fix the issues — or run it through the
  normalizer again after editing — and validate again.
- Only when the issues array is empty does the returned sequence have
  `isValidated == true` — the prerequisite for formatting.

Each ``SMFValidator/Issue`` has a ``SMFValidator/Issue/message`` and, except for
the sequence-wide ``SMFValidator/Issue/invalidTrackCount(trackCount:format:)``,
a ``SMFValidator/Issue/trackIndex``:

- ``SMFValidator/Issue/missingEndOfTrack(trackIndex:)``,
  ``SMFValidator/Issue/eventAfterEndOfTrack(trackIndex:)``,
  ``SMFValidator/Issue/unterminatedSysEx(trackIndex:)``, and
  ``SMFValidator/Issue/orphanSysExContinuation(trackIndex:)`` — a normalized
  sequence never has these; ``SMFNormalizer`` clears them mechanically.
- ``SMFValidator/Issue/invalidMetaEventType(trackIndex:)`` — an
  ``SMFMetaMessage/unknown(_:_:)`` meta-event has a type byte of 0x80 or
  greater, which RP-001 does not allow.
- ``SMFValidator/Issue/invalidTrackCount(trackCount:format:)``,
  ``SMFValidator/Issue/deltaTimeTooLarge(trackIndex:)``, and
  ``SMFValidator/Issue/eventDataTooLarge(trackIndex:)`` — structural violations
  that would prevent ``SMFFormatter`` from encoding the sequence.
- ``SMFValidator/Issue/unencodableText(trackIndex:)`` — a meta-event’s text
  contains a character that cannot be encoded as single-byte SMF text. This is a
  judgment call (for instance, whether to drop the offending characters or the
  whole event) left to the caller, so ``SMFNormalizer`` does not attempt to fix
  it.

## Formatting

``SMFFormatter`` serializes a **validated** sequence back to binary data:

```swift
let data = try SMFFormatter().format(validated)
```

If the sequence has not been validated, `format(_:)` throws
``SMFFormatter/Error/notValidated``. Because the model is validated first,
formatting itself only fails on structurally unencodable content (a value out of
range for its wire representation).

The formatter emits a canonical wire form — maximal running status and minimal
variable-length quantities, with system exclusive packets written as given — so
round-tripping is **semantic, not byte-exact**: `parse → normalize → validate →
format` reproduces an equal ``SMFSequence`` (comparing `format`, `division`, and
`tracks`; the two flags are metadata and excluded from `==`), but the bytes may
differ from the original if it used a non-canonical but equivalent encoding.
Byte-exactness does happen to hold when the input was already canonical.

## The AST model

The syntactic model is a tree of value types:

```
SMFSequence
├─ format:   SMFFormat      // 0, 1, or 2
├─ division: SMFDivision    // .metrical(SMFTickRate) | .timeCode(SMFTimeCode)
└─ tracks:   [SMFTrack]
   └─ events: [SMFEvent]    // .meta | .midi | .sysEx, each with an absolute SMFEventTime
```

Some payloads come from companion packages. A `.midi` event carries a
`MIDIChannelMessage` from IvorMIDI. An ``SMFTimeCode`` division carries a
`SMPTEFrameRate`, and the `.smpteOffset` case of ``SMFMetaMessage`` carries a
`SMPTETime`; both types come from IvorSMPTE. Import those packages alongside
IvorSMF to construct or inspect these values. A Standard MIDI File can encode
only four of IvorSMPTE’s frame rates — `.fps24`, `.fps25`, `.fps2997Drop`,
and `.fps30` — so ``SMFTimeCode`` rejects any other rate, and a
SMPTE offset at any other rate cannot be formatted. Call
``SMFTimeCode/supports(_:)`` to check a frame rate before using it in either
place.

Event times are **absolute** ticks from the start of the track, not the delta
times used on the wire — the parser decodes deltas into absolute time, and the
formatter re-encodes them. This is a lossless, deterministic bijection, so
keeping the AST absolute is simply the more ergonomic of two equivalent
encodings: it makes hand-built sequences easy to construct (place events at
absolute ticks; no running-sum arithmetic to maintain) and preserves a useful
absolute-timed-but-not-note-paired view of the data. ``SMFTrack`` sorts its
events by time on initialization, using a *stable* sort — same-tick event order
is part of a sequence’s meaning, so authored order among simultaneous events is
preserved.

A MIDI Channel Prefix meta-event associates a channel with the meta-events and
system exclusive events that follow it, until the next MIDI event or prefix.
Call ``SMFTrack/channel(forEventAt:)`` to find the channel associated with any
event. When a sequence has no tempo or time signature, RP-001 assumes
``SMFTempo/default`` (120 beats per minute) and ``SMFTimeSignature/default``
(4/4).

Text meta-events are decoded with the Windows-1252 character set, the RP-026
default; ``SMFText/decodedString(using:)`` re-decodes a lyric written in another
character set, such as Shift-JIS.

``SMFSequence`` equality and hashing compare `format`, `division`, and `tracks`
only; `isNormalized` and `isValidated` are pipeline metadata and are excluded.

## Building a sequence programmatically

You can construct the AST directly rather than parsing bytes:

```swift
import IvorMIDI
import IvorSMF

let track = SMFTrack(events: [.midi(0, .noteOn(1, 0x3c, 0x64)),
                              .midi(120, .noteOff(1, 0x3c, 0x64))])

let sequence = SMFSequence(format: .format0,
                           division: .metrical(480),
                           tracks: [track])
```

A directly-constructed sequence has `isNormalized == false` and `isValidated ==
false` — exactly like one fresh out of the parser — so it must be run through
the normalizer and validator before formatting. This example’s
track has no End-of-Track event, so `SMFNormalizer().normalize(_:)` will append
one before `SMFValidator().validate(_:)` can succeed.

IvorMIDI’s message builders plug straight in.
``SMFEvent/midiEvents(for:at:)`` places a sequence of channel messages — such as
the control changes that set a registered parameter — at one tick, in sending
order. ``SMFSysExMessage/init(for:)`` wraps any `MIDISystemMessage`: a system
exclusive message, such as one from IvorMIDI’s universal system exclusive
builders, becomes a single complete packet, and a system common or real-time
message becomes an escape. Going the other way,
``SMFSysExMessage/systemMessage`` decodes a parsed event back into a
`MIDISystemMessage`.

```swift
let bendRange = MIDIChannelMessage.registeredParameterChange(.pitchBendSensitivity,
                                                             value: MIDIData2Value(msb: 12, lsb: 0),
                                                             on: 1)

let setup = SMFTrack(events: [.sysEx(0, SMFSysExMessage(for: .masterVolume(16_383)))]
                             + SMFEvent.midiEvents(for: bendRange, at: 0))
```

Program numbers in `MIDIChannelMessage.programChange` are `MIDIProgram`
values, numbered 1–128 like channels, so the wire byte `C0 05` is program 6.

## Error handling

Thrown errors conform to `EnhancedError` (from
[XestiTools](https://github.com/eBardX/XestiTools)): each has a `category` of
`"IvorSMF"` and a human-readable `message`.

 Type                   | Thrown by
:----                   |:---------
 ``SMFParser/Error``    | `SMFParser.parse(_:)`
 ``SMFValidator/Error`` | `SMFValidator.validate(_:)`
 ``SMFFormatter/Error`` | `SMFFormatter.format(_:)`

Non-fatal results are returned rather than thrown, and each also provides a
`message`:

 Type                     | Returned by     | Also
:----                     |:-----------     |:-----
 ``SMFParser/Diagnostic`` | `parse(_:)`     | —
 ``SMFNormalizer/Change`` | `normalize(_:)` | `trackIndex` (`Int?`)
 ``SMFValidator/Issue``   | `validate(_:)`  | `trackIndex` (`Int?`)

## Recovering from real-world deviations

Real-world MIDI files frequently deviate from the RP-001 specification —
truncated chunk lengths, missing End-of-Track markers, stray real-time bytes,
and track-count mismatches in the header are all common. Putting the stages
above together, here is the full recovery workflow for a file of unknown
quality:

```swift
let data = try Data(contentsOf: fileURL)
let (parsed, diagnostics) = try SMFParser().parse(data)

if !diagnostics.isEmpty {
    print("Repaired \(diagnostics.count) issue(s) while parsing:")
    for diagnostic in diagnostics { print("  • \(diagnostic.message)") }
}

let (normalized, changes) = SMFNormalizer().normalize(parsed)
for change in changes { print("  • \(change.message)") }

let (validated, issues) = try SMFValidator().validate(normalized)

if !issues.isEmpty {
    print("\(issues.count) validation issue(s) found:")
    for issue in issues { print("  • \(issue.message)") }
    return
}

let cleanData = try SMFFormatter().format(validated)
try cleanData.write(to: outputURL)
```

Because normalization mechanically clears
``SMFValidator/Issue/missingEndOfTrack(trackIndex:)``,
``SMFValidator/Issue/eventAfterEndOfTrack(trackIndex:)``,
``SMFValidator/Issue/unterminatedSysEx(trackIndex:)``, and
``SMFValidator/Issue/orphanSysExContinuation(trackIndex:)`` for every track,
those cases never appear here. Any issue that remains — most commonly
``SMFValidator/Issue/unencodableText(trackIndex:)`` — requires a judgment call
the normalizer cannot make on its own, so this workflow reports it and stops
rather than guessing at a fix.

The parser’s diagnostics are:

 Case                                                                          | Meaning
:----                                                                          |:-------
 ``SMFParser/Diagnostic/chunkLengthClamped(declared:available:)``              | A chunk’s declared length exceeded the remaining data; clamped to what was available.
 ``SMFParser/Diagnostic/dataAfterEndOfTrackSkipped(byteCount:)``               | A track chunk had data after its End-of-Track event; the extra bytes were skipped.
 ``SMFParser/Diagnostic/invalidChunkTypeSkipped(_:)``                          | A chunk’s type was not four ASCII characters; the chunk was skipped.
 ``SMFParser/Diagnostic/metaEventLengthClamped(type:declared:expected:)``    | A recognized fixed-length meta-event declared more data bytes than its type defines; the surplus bytes were ignored.
 ``SMFParser/Diagnostic/metaEventLengthInvalid(type:declared:expected:)``    | A fixed-length meta-event declared fewer data bytes than its type defines; the event was retained as ``SMFMetaMessage/unknown(_:_:)``.
 ``SMFParser/Diagnostic/strayRealTimeByteSkipped``                             | A system real-time byte (0xF8–0xFE) appeared in the event stream and was discarded.
 ``SMFParser/Diagnostic/trackCountMismatch(declared:actual:)``                 | The header’s `ntrks` field did not match the number of MTrk chunks found.
 ``SMFParser/Diagnostic/truncatedEventSkipped``                                | A track chunk ended partway through an event; the incomplete event was skipped.
 ``SMFParser/Diagnostic/unknownFormatReadAsFormat1(_:)``                       | The header declared a format other than 0, 1, or 2; the tracks were read as format 1.
 ``SMFParser/Diagnostic/variableLengthQuantityClamped``                        | A variable-length quantity exceeded the 0x0FFFFFFF maximum; clamped to that maximum.

## Concurrency

IvorSMF is built for Swift 6 strict concurrency. Every public type — the four
processing types and the entire AST — is a `Sendable` value type, so instances
can be freely shared across tasks and actor boundaries. The processing types
hold no mutable state, so a single ``SMFParser``, ``SMFNormalizer``,
``SMFValidator``, or ``SMFFormatter`` instance can be reused for any number of
concurrent operations.
