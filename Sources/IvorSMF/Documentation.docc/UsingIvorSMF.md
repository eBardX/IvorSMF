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

The parser is always tolerant. It performs only byte/structural recovery —
clamping an over-long chunk length, skipping a stray system real-time byte,
tolerating a track-count mismatch between the header and the actual `MTrk`
chunks it finds — and reports each repair as an ``SMFParser/Diagnostic``.
Diagnostics are always returned, never thrown; each has a human-readable
`message`:

```swift
for diagnostic in diagnostics {
    print(diagnostic.message)
}
```

The parser throws ``SMFParser/Error`` only when no sequence can be produced at
all — for example a missing or truncated header chunk, or bytes that cannot be
decoded as any recognized event. Deviations the model itself can represent —
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
   all End-of-Track events, then appends a single one at the maximum remaining
   event tick (or tick zero if the track is otherwise empty). No musical event
   is ever dropped.
2. A format 0 sequence must have exactly one track; a format 0 sequence with
   more than one track is reinterpreted as format 1, which has no such
   restriction.
3. Within a track, a sequence-number meta-event must appear at time zero, and,
   in a format 1 sequence with more than one track, tempo and time-signature
   meta-events must appear only in the first track.

``SMFNormalizer/Change`` reports each fix applied:

- **`coercedFormat(from:to:)`** — the sequence declared format 0 but had more
  than one track; it was reinterpreted as format 1. This is a sequence-wide
  change, so `trackIndex` is `nil`.
- **`insertedEndOfTrack(trackIndex:)`** — the track had no End-of-Track; one was
  appended.
- **`relocatedEndOfTrack(trackIndex:)`** — the track had one or more
  End-of-Track events that were not already the sole final event (a premature
  End-of-Track with later events, and/or duplicates); they were consolidated
  into a single trailing one.
- **`relocatedSequenceNumber(trackIndex:)`** — the track had a sequence-number
  meta-event that did not appear at time zero; its time was reset to zero.
- **`relocatedTempo(trackIndex:)`** — the track had a tempo meta-event, but the
  sequence is format 1 with more than one track; the event was moved to track 0.
- **`relocatedTimeSignature(trackIndex:)`** — the track had a time-signature
  meta-event, but the sequence is format 1 with more than one track; the event
  was moved to track 0.

Normalization automatically fixes every ``SMFValidator/Issue`` case that has a
deterministic fix, so a normalized sequence never has
``SMFValidator/Issue/missingEndOfTrack(trackIndex:)`` or
``SMFValidator/Issue/eventAfterEndOfTrack(trackIndex:)``. Issues that require a
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

- ``SMFValidator/Issue/missingEndOfTrack(trackIndex:)`` and
  ``SMFValidator/Issue/eventAfterEndOfTrack(trackIndex:)`` — a normalized
  sequence never has these; ``SMFNormalizer`` clears them mechanically.
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

The formatter emits a canonical wire form — maximal running status, minimal
variable-length quantities, single-packet system exclusive data — so
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
`MIDIChannelMessage` from IvorMIDI. An ``SMFTimeCode`` division carries an
`SMPTEFrameRate`, and the `.smpteOffset` case of ``SMFMetaMessage`` carries an
`SMPTETime`; both types come from IvorSMPTE. Import those packages alongside
IvorSMF to construct or inspect these values.

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
``SMFValidator/Issue/missingEndOfTrack(trackIndex:)`` and
``SMFValidator/Issue/eventAfterEndOfTrack(trackIndex:)`` for every track, those
two cases never appear here. Any issue that remains — most commonly
``SMFValidator/Issue/unencodableText(trackIndex:)`` — requires a judgment call
the normalizer cannot make on its own, so this workflow reports it and stops
rather than guessing at a fix.

The parser’s diagnostics are:

 Case                                                             | Meaning
:----                                                             |:-------
 ``SMFParser/Diagnostic/chunkLengthClamped(declared:available:)`` | A chunk’s declared length exceeded the remaining data; clamped to what was available.
 ``SMFParser/Diagnostic/strayRealTimeByteSkipped``                | A system real-time byte (0xF8–0xFE) appeared in the event stream and was discarded.
 ``SMFParser/Diagnostic/trackCountMismatch(declared:actual:)``    | The header’s `ntrks` field did not match the number of MTrk chunks found.

## Concurrency

IvorSMF is built for Swift 6 strict concurrency. Every public type — the four
processing types and the entire AST — is a `Sendable` value type, so instances
can be freely shared across tasks and actor boundaries. The processing types
hold no mutable state, so a single ``SMFParser``, ``SMFNormalizer``,
``SMFValidator``, or ``SMFFormatter`` instance can be reused for any number of
concurrent operations.
