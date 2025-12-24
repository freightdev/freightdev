# Book Inventory

This is the core `index.yaml` that defines your structured memory shelf for Markdown-native agents.

## Purpose

The **Book Inventory** provides a registry of all active books within the system, including their structure (marks), metadata (cover), and location. This forms the foundation for MARK-powered memory operations.

## Concepts

Books are structured memory containers built from Markdown pages (snapshots) and marks (logic references).
Each Book has a Cover (its metadata/contract) and a Bookmark (its internal structure of marks).

Markers are agent tools that connect and activate marks across books.
Once created, a Marker becomes portable—able to travel beyond non-original books while still tied to its original marks.

Markers require Ink to execute marks, leaving behind an Ink Trail (execution log) with each stroke.
Trails log every token-based action.
Ribbons are cached Trails—replayable memories that don’t consume Ink.

This inventory defines the full shelf of structured memory accessible to Markdown-Native Agents.

## Marker Behavior

* Markers can be shared across books once created.
* Trails and Ribbons track usage and enable traceable agent behaviors.
* Each mark executed consumes `ink`, stored in the trail.

## File Structure

```yaml
root: /home/jesse/Desktop/bookstore/inventory/books
index: /home/jesse/Desktop/bookstore/inventory/books/index.yaml
```

## Books Defined

```yaml
books:
  - title: Freight Dispatching
    path: inventory/books/freight-dispatching
    cover: bookcover.yaml
    marks: bookmark.yaml

  - title: Driver Operations
    path: inventory/books/driver-operations
    cover: bookcover.yaml
    marks: bookmark.yaml

  - title: Safety Guides
    path: inventory/books/safety-guides
    cover: bookcover.yaml
    marks: bookmark.yaml

  - title: Logbook
    path: inventory/books/logbook
    cover: bookcover.yaml
    marks: bookmark.yaml
```

## Usage

Use the command:

```
mark book
```

To initialize and validate books against their `bookmark.yaml` structure.

Use:

```
mark trail
```

To log execution history of marks using available `ink`.

---

This system is part of the MARK ecosystem and should be version-controlled as your structured AI-readable memory network expands.
