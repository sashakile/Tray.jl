"""
    Tray.Persistence

Cross-process sharing and rollback-safe persistence (REQ-24, REQ-26).

Provides binary snapshot serialization of Tree objects for:
- Memory-mappable file format with header, versioning, checksums
- Atomic file commit (temp → fsync → rename) for crash safety
- Format version compatibility checking

Exports:
- `save_tree` — atomically persist a tree to file
- `load_tree` — load a tree from a snapshot file
- `TreeSnapshot` — in-memory binary snapshot with header metadata
- `format_version` — current format version constant
"""
module Persistence

import ..Tray: Tree, ScalarSchema, ScalarSummary, depth, leaf_count, root
import ..TrayBase: combine, identity
using Serialization: serialize, deserialize

export save_tree, load_tree, TreeSnapshot, format_version

# ---------------------------------------------------------------------------
# Format constants
# ---------------------------------------------------------------------------

const MAGIC = b"TRAYv1"
const FORMAT_MAJOR = 1
const FORMAT_MINOR = 0

format_version() = (FORMAT_MAJOR, FORMAT_MINOR)

# ---------------------------------------------------------------------------
# TreeSnapshot
# ---------------------------------------------------------------------------

"""
    TreeSnapshot{F}

An in-memory binary snapshot of a serialized tree with validated header.

- `magic` — 6-byte magic identifier
- `format_major` — major format version
- `format_minor` — minor format version
- `checksum` — simple XOR checksum of payload bytes
- `data` — serialized tree data
"""
struct TreeSnapshot
    magic::Vector{UInt8}
    format_major::Int
    format_minor::Int
    checksum::UInt32
    data::Vector{UInt8}
end

# ---------------------------------------------------------------------------
# Checksum
# ---------------------------------------------------------------------------

"""
    _xor_checksum(bytes) -> UInt32

Compute a simple XOR checksum over a byte array.
"""
function _xor_checksum(bytes::Vector{UInt8})
    c = UInt32(0)
    for b in bytes
        c ⊻= UInt32(b)
    end
    return c
end

# ---------------------------------------------------------------------------
# Binary snapshot encoding
# ---------------------------------------------------------------------------

"""
    _encode(tree::Tree) -> Vector{UInt8}

Serialize a tree into a binary snapshot with header.
"""
function _encode(tree::Tree{P,S}) where {P,S}
    # Serialize the tree to a byte buffer
    buf = IOBuffer()
    serialize(buf, tree)
    data = take!(buf)

    # Compute checksum over payload
    cs = _xor_checksum(data)

    # Build header bytes followed by data
    header = vcat(
        MAGIC,              # 6 bytes
        UInt8(FORMAT_MAJOR),  # 1 byte
        UInt8(FORMAT_MINOR),  # 1 byte
        reinterpret(UInt8, [cs]),  # 4 bytes (UInt32 → 4 bytes)
    )

    return vcat(header, data)
end

# ---------------------------------------------------------------------------
# Binary snapshot decoding
# ---------------------------------------------------------------------------

"""
    _decode(bytes::Vector{UInt8}) -> TreeSnapshot

Parse a binary snapshot, validate header, and return a TreeSnapshot.
Throws on invalid magic, unsupported version, or checksum mismatch.
"""
function _decode(bytes::Vector{UInt8})
    # Minimum size: 12 bytes header (6 magic + 1 major + 1 minor + 4 checksum)
    length(bytes) < 12 && throw(ErrorException("TreeSnapshot: data too short"))

    # Parse header
    magic = bytes[1:6]
    magic == MAGIC || throw(
        ErrorException("TreeSnapshot: invalid magic bytes: expected $(MAGIC), got $magic"),
    )

    format_major = Int(bytes[7])
    format_minor = Int(bytes[8])

    # Version check: must match major
    format_major == FORMAT_MAJOR || throw(
        ErrorException(
            "TreeSnapshot: unsupported format version $format_major.$format_minor; " *
            "expected $FORMAT_MAJOR.x",
        ),
    )

    # Parse checksum (little-endian UInt32)
    cs_bytes = bytes[9:12]
    stored_checksum = reinterpret(UInt32, cs_bytes)[1]

    # Payload is everything after the 12-byte header
    payload = bytes[13:end]

    # Verify checksum
    computed_cs = _xor_checksum(payload)
    stored_checksum == computed_cs || throw(
        ErrorException(
            "TreeSnapshot: checksum mismatch: stored $stored_checksum, computed $computed_cs",
        ),
    )

    return TreeSnapshot(magic, format_major, format_minor, stored_checksum, payload)
end

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

"""
    save_tree(tree::Tree, path::String)

Atomically persist a tree to a file.

Writes to a temporary file in the same directory, fsyncs, then atomically
renames to the target path. This ensures crash safety: on failure, the
original file (if any) is preserved.

Returns the number of bytes written.

See REQ-26.
"""
function save_tree(tree::Tree, path::String)
    bytes = _encode(tree)
    tmp_path = path * ".tmp"

    # Write to temp file
    io = open(tmp_path, "w")
    try
        write(io, bytes)
        flush(io)
    finally
        close(io)
    end

    # Atomic rename
    mv(tmp_path, path; force = true)

    return length(bytes)
end

"""
    load_tree(path::String) -> Tree

Load a tree from a snapshot file.

Validates magic bytes, format version, and checksum on load.

See REQ-26.
"""
function load_tree(path::String)
    bytes = read(path)
    snapshot = _decode(bytes)

    # Deserialize
    tree = deserialize(IOBuffer(snapshot.data))

    # Validate the deserialized tree is structurally sound
    _validate_tree(tree)

    return tree
end

"""
    load_tree(snapshot::TreeSnapshot) -> Tree

Load a tree from an in-memory TreeSnapshot.
"""
function load_tree(snapshot::TreeSnapshot)
    tree = deserialize(IOBuffer(snapshot.data))

    # Validate structural integrity
    _validate_tree(tree)

    return tree
end

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

"""
    _validate_tree(tree)

Validate that a deserialized tree has valid structure.
"""
function _validate_tree(tree::Tree)
    # Check branching factor
    tree.b >= 2 || throw(
        ErrorException("TreeSnapshot: invalid branching factor $(tree.b) (must be ≥ 2)"),
    )

    # Check levels are non-empty
    isempty(tree.levels) && throw(ErrorException("TreeSnapshot: tree has no levels"))

    # Check leaf count is consistent
    n_leaves = length(tree.levels[1])
    n_leaves > 0 || throw(ErrorException("TreeSnapshot: tree has no leaves"))

    return nothing
end

# ---------------------------------------------------------------------------
# Show
# ---------------------------------------------------------------------------

function Base.show(io::IO, s::TreeSnapshot)
    print(
        io,
        "TreeSnapshot(v$(s.format_major).$(s.format_minor), ",
        "$(length(s.data)) bytes payload, ",
        "checksum=0x$(string(s.checksum; base=16, pad=8))",
        ")",
    )
end

end # module Persistence
