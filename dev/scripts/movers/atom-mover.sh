#!/usr/bin/env bash
# atom-mover.sh — move atom folders into structured subcategories (e.g. semantic/forms, visual/feedback)

set -e

ROOT="packages/ui/components/atoms"
DRY=false

usage() {
  echo "Usage: ./deep-atom-mover.sh [-T path/to/atoms] [--dry]"
  exit 1
}

# Parse args
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -T|--target)
      ROOT="$2"
      shift 2
      ;;
    --dry)
      DRY=true
      shift
      ;;
    *)
      echo "❌ Unknown arg: $1"
      usage
      ;;
  esac
done

echo "🚚 Deep atom mover running..."
echo "📦 Source root: $ROOT"
echo "🧪 Dry mode: $DRY"

# Component folder to new subpath map
declare -A MOVE_MAP=(
  # Semantic ➝ Forms
  [Input]="semantic/forms"
  [Textarea]="semantic/forms"
  [Select]="semantic/forms"
  [Checkbox]="semantic/forms"
  [Radio]="semantic/forms"
  [Label]="semantic/forms"
  [Fieldset]="semantic/forms"
  [Legend]="semantic/forms"
  [Output]="semantic/forms"
  [Form]="semantic/forms"

  # Semantic ➝ Structure
  [Main]="semantic/structure"
  [Section]="semantic/structure"
  [Header]="semantic/structure"
  [Footer]="semantic/structure"
  [Article]="semantic/structure"
  [Aside]="semantic/structure"
  [Nav]="semantic/structure"

  # Semantic ➝ Media
  [Img]="semantic/media"
  [Video]="semantic/media"
  [Audio]="semantic/media"
  [Picture]="semantic/media"
  [Canvas]="semantic/media"
  [Svg]="semantic/media"

  # Semantic ➝ Metadata
  [Title]="semantic/metadata"
  [Base]="semantic/metadata"
  [Script]="semantic/metadata"
  [Mark]="semantic/metadata"

  # Semantic ➝ Layout
  [Body]="semantic/layout"
  [Template]="semantic/layout"
  [Iframe]="semantic/layout"
  [Search]="semantic/layout"

  # Semantic ➝ Navigation
  [Link]="semantic/navigation"
  [Menu]="semantic/navigation"
  [Option]="semantic/navigation"
  [Map]="semantic/navigation"
  [Area]="semantic/navigation"

  # Semantic ➝ Misc
  [Time]="semantic/misc"
  [Table]="semantic/misc"
  [Datalist]="semantic/misc"
  [Button]="semantic/misc"
  [Shell]="semantic/misc"
  [Figcaption]="semantic/misc"
  [Figure]="semantic/misc"

  # Visual ➝ Display
  [Avatar]="visual/display"
  [Logo]="visual/display"
  [StatusDot]="visual/display"
  [Heading]="visual/display"
  [TextLead]="visual/display"
  [Tagline]="visual/display"
  [Icon]="visual/display"
  [Text]="visual/display"
  [Blockquote]="visual/display"


  # Visual ➝ Feedback
  [Alert]="visual/feedback"
  [Error]="visual/feedback"
  [Spinner]="visual/feedback"
  [Skeleton]="visual/feedback"
  [LoadingDots]="visual/feedback"
  [Sonner]="visual/feedback"

  # Visual ➝ Data
  [ProgressBar]="visual/data"
  [Pagination]="visual/data"
  [Divider]="visual/data"
  [DividerLabel]="visual/data"
  [Separator]="visual/data"

  # Visual ➝ Interactions
  [Tooltip]="visual/interactions"
  [Popover]="visual/interactions"
  [Toggle]="visual/interactions"
  [Switch]="visual/interactions"
  [Tab]="visual/interactions"
  [Slider]="visual/interactions"
  [Sheet]="visual/interactions"
  [Sidebar]="visual/interactions"
  [ScrollArea]="visual/interactions"
  [Resizable]="visual/interactions"

  # Visual ➝ Code
  [CodeBlock]="visual/code"
  [Keyboard]="visual/code"
  [TextHighlight]="visual/code"

  # Visual ➝ Composition
  [Badge]="visual/composition"
  [BadgeIcon]="visual/composition"
  [LabelIcon]="visual/composition"
  [Pill]="visual/composition"
)

MOVED=0
SKIPPED=0

for COMPONENT in "${!MOVE_MAP[@]}"; do
  SRC="$ROOT/semantic/$COMPONENT"
  [[ -d "$SRC" ]] || SRC="$ROOT/visual/$COMPONENT"
  [[ -d "$SRC" ]] || SRC="$ROOT/$COMPONENT"

  DEST="$ROOT/${MOVE_MAP[$COMPONENT]}/$COMPONENT"

  if [[ -d "$DEST" ]]; then
    echo "✅ Already in place: $COMPONENT"
    continue
  fi

  if [[ ! -d "$SRC" ]]; then
    echo "⚠️  Not found: $COMPONENT"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo "🔀 Moving $COMPONENT → ${MOVE_MAP[$COMPONENT]}"
  if [[ "$DRY" = true ]]; then
    echo "  [Dry] mv $SRC → $DEST"
  else
    mkdir -p "$(dirname "$DEST")"
    mv "$SRC" "$DEST"
    echo "  ✅ Moved: $COMPONENT"
    MOVED=$((MOVED + 1))
  fi
done

echo "🏁 Deep atom move complete — $MOVED moved, $SKIPPED skipped."
