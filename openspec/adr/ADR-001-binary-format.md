# ADR-001: Mapped Binary Compatibility Policy

**Status:** Approved
**Author:** sasha
**Date:** 2026-07-20
**Tickets:** TRAYS-0yj, TRAYS-bn5
**Requirements:** REQ-24, REQ-26

## Context

The shared-memory and persistence layer needs a binary format for communicating
tree snapshots across processes and languages. The format must be versioned,
cross-platform, and safe for concurrent readers. This ADR locks in the format
versioning, byte order, layout extensibility, synchronization protocol,
backward-compatibility policy, and fixture obligations.

## Decision

### 1. Byte Order: Host-order with marker

Write in the host's native byte order. The header begins with a fixed 4-byte
magic string `54 52 41 59` (ASCII `"TRAY"`) written in network byte order
(big-endian), followed by a 4-byte endianness marker stored as a native int32.

**Reader validation:**
1. Read 4 bytes; compare to `54 52 41 59` ("TRAY"). If mismatch, reject.
2. Read next 4 bytes as a native int32 — this is the endianness marker.
   - If marker value == `0x01020304`: writer and reader have the same byte
     order. No swap needed.
   - If marker value == `0x04030201`: byte order is reversed. Reader MUST swap
     every multi-byte field.
   - Any other value: file is corrupt or not a Tray format. Reject.

**Rationale:** Zero runtime cost on the common single-machine path. Automatic
detection in heterogeneous distributed deployments. No configuration or
compile-time flags needed.

### 2. Primitive Type Encoding: Fixed-layout with reserved extensibility

The mapping uses a fixed-layout header with explicit byte offsets, not a
serialization framework. Every section is length-prefixed so unknown sections
can be skipped without interpreting their contents.

**Header layout (version 1):**

| Offset | Size | Field |
|--------|------|-------|
| 0      | 4    | Magic: `54 52 41 59` ("TRAY", network byte order) |
| 4      | 4    | Endianness marker (native int32, see §1) |
| 8      | 4    | Format ID (incremental, starting at 1) |
| 12     | 4    | Total header size (allows forward skips) |
| 16     | 8    | Snapshot epoch |
| 24     | 4    | Numeric type tag (0=Float64, 1=Float32, etc.) |
| 28     | 4    | Branching factor b |
| 32     | 8    | Leaf count n |
| 40     | 8    | Total node count |
| 48     | 8    | Offset to leaf payloads |
| 56     | 8    | Offset to internal nodes |
| 64     | 8    | Offset to schema blob |
| 72     | 8    | Checksum (xxHash3) |
| 80     | 16   | Reserved for future use |
| 96     | 4    | Schema blob length (bytes) |
| 100    | —    | Schema blob (TOML, UTF-8) |

**Offsets and bounds checking:** Every offset-relative read MUST verify that
`offset + field_size` is within the mapped region before dereferencing. A reader
encountering an out-of-bounds offset MUST reject the mapping with a format error
and MUST NOT attempt to read past the known mapped extent.

**Schema blob format:** Length-prefixed TOML encoded as UTF-8. The first 4 bytes
are the length (unsigned int32, in file byte order). The following bytes are the
TOML document. This format is versioned independently of the header format ID
via a `schema_version` key in the TOML blob itself.

**Rationale:** Fixed offsets give deterministic zero-allocation reads.
Length-prefixed sections and reserved fields let us add new sections in future
format versions without breaking old readers. No serialization framework
dependency. TOML is human-readable and has parsers in every target language.

### 3. Versioning: Incremental sequential format IDs

Format IDs are sequential integers starting at 1. Each new version increments
the ID. There is no semantic versioning — only a monotonic counter.

**Rationale:** Simple, unambiguous, no parsing overhead. The accrual model (see
below) ensures old readers can safely ignore unknown IDs.

### 4. Backward Compatibility: Clojure-style accrual model

New format versions may only add fields or sections — never remove, reinterpret,
or change the byte offset of existing fields. Old readers skip unknown sections
by reading the length prefix. New readers always read old formats natively.

**Rules:**
- Existing fields keep their byte offset and semantics forever.
- Adding a field: use a reserved slot or append a new length-prefixed section.
- Removing a field: forbidden. Mark as deprecated but keep the offset.
- Changing a field's semantics: forbidden. Add a new field instead.
- A reader encountering an unknown format ID MAY refuse to read, but if it
  supports the format range, it MUST handle unknown sections gracefully by
  skipping them via the length prefix.

**Supported version range:** Readers support the current version and all earlier
versions. A reader encountering a newer version than it knows MAY refuse, but
SHOULD attempt to read the header (up to total_header_size) and report the
format ID.

### 5. Synchronization Protocol: Seqlock-style atomic epoch counter

A single 64-bit atomic epoch counter in shared memory mediates access. On 32-bit
platforms where atomic 64-bit operations are unavailable, a 32-bit counter
(wrapping at 2³¹) MAY be used with libatomic or equivalent support.

- **Writer protocol:**
  1. Atomically increment epoch from even to odd (lock acquired).
  2. Write leaf data and all internal nodes.
  3. Publish via atomic store (store-release in C++ terms).
  4. Atomically increment epoch from odd to even (lock released).

- **Reader protocol:**
  1. Atomically load epoch (load-acquire). Must be even.
  2. Read any data needed.
  3. Verify epoch is unchanged and still even. If not, retry from step 1.
  4. If the epoch is odd for more than a configurable timeout, assume the
     writer has crashed and either wait for recovery or abort the mapping.

- **Crash recovery:** A writer crash leaves the epoch odd. The next writer or
  recovery process detects the stuck odd epoch and can either roll back or
  abort the mapping. Readers never block — they retry until the epoch is even
  again.

- **Wraparound:** The 64-bit counter wraps after 2⁶³ writes. At 1 million
  writes/second, this takes ~300,000 years — not a practical concern.
  Implementations using 32-bit counters MUST handle wraparound explicitly
  (e.g., by rejecting epoch values that would indicate stale data).

**Rationale:** Lock-free for readers. No POSIX mutex dependency (works across
languages). Retry-on-conflict mirrors Clojure STM's philosophy. The epoch
counter is a single integer — trivial to map in shared memory.

### 6. Golden Fixtures

One canonical fixture file per format version. The fixture is a minimal valid
tree (b=2, 2-leaf Float64 ScalarSummary) serialized in the format. Every
language implementation claiming compatibility with a version must pass the
fixture.

**Fixture obligations:**
- Read the header and verify magic, endianness marker, format ID.
- Read the root payload and verify it matches the expected value via semantic
  equality (payload struct field comparison), not byte-exact comparison.
- Read a leaf payload and verify it matches via semantic equality.
- Read and parse the schema blob.
- Zero full-deserialization attempts (all reads from mapped memory).

**Byte-exact vs semantic comparison:** The conformance fixture checks semantic
equality only. Byte-exact comparison is a stricter separate goal and is not
required for format compatibility.

## Consequences

**Accepted trade-offs:**
- Fixed-layout header is less flexible than a self-describing format (e.g., Cap'n
  Proto, FlatBuffers) but simpler to implement and zero-copy across languages.
- Host-order with marker means distributed deployments must handle swapping, but
  the marker detection is zero-cost on single-machine paths.
- Seqlock is reader-lock-free but requires writer to publish all data in one
  critical section; large writes may cause reader starvation. Mitigation: keep
  the critical section minimal (swap epoch, not data).

**Rejected alternatives:**
- Network byte order everywhere: rejected for zero-cost single-machine reads.
- Cap'n Proto / FlatBuffers: rejected for simplicity and no dependency cost.
- POSIX mutex / rwlock: rejected for cross-language portability and reader
  fairness.
- Semantic versioning for format IDs: rejected for simplicity; sequential IDs
  are unambiguous and monotonic.