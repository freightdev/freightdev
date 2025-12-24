# Astro Enterprise Architecture

## Directory Map

```
src/
├── components/
│   ├── atoms/        # Foundation (Button, Container, Typography)
│   ├── molecules/    # Composed atoms (Card, FormField, LinkCard, MapCard)
│   ├── organisms/    # Page sections (Hero, CTA, Navbar, Footer, ContactSection, Section)
│   ├── templates/    # Page-level orchestration (PageComposer)
│   └── islands/      # Reserved for interactive islands (React/Vue/Svelte)
├── configs/
│   ├── content/      # Domain copy & data (features, pricing, testimonials, etc.)
│   ├── forms/        # Form schemas (contact form)
│   └── pages/        # Declarative page blueprints consumed by PageComposer
├── styles/           # Global CSS tokens + utilities
├── theme/            # TypeScript design tokens used by Tailwind + utilities
├── types/            # Cross-cutting TS types (routes, content, base props)
├── utils/            # Shared helpers (cn, layout utilities, formatting)
├── layouts/          # BaseLayout and future page layouts
└── pages/            # File-based routes that load a blueprint + composer
```

## Atomic Components

- Every component owns its props, variants, and helpers inside its folder.
- Atoms expose stylistic primitives (buttons, containers, typography). They never import from higher layers.
- Molecules compose atoms (e.g., `Card` combines typography + layout; `FormField` renders inputs from schema).
- Organisms assemble molecules into full sections (`Hero`, `CTA`, `ContactSection`, `Section`).
- Templates (currently `PageComposer`) orchestrate organisms based on configuration.
- `src/components/index.ts` re-exports public primitives so consumers can `import { Hero } from '@components';`.

## Styling Strategy

- Global CSS lives in `src/styles` (reset + shared utility classes) and is imported once inside `BaseLayout`.
- Design tokens remain typed in `src/theme/**` and mirrored as CSS custom properties for non-Tailwind consumers.
- Tailwind can continue to power utility classes, but atoms provide a semantic layer so organisms rarely reach for raw class strings.

## Config & Data Flow

1. Content (features, pricing, testimonials, etc.) is defined under `src/configs/content`.
2. Page blueprints (`src/configs/pages/*.ts`) stitch components together by describing a tree of `{ component, props, children }`.
3. `PageComposer` reads a blueprint, resolves each component via `component-registry.ts`, and renders the hierarchy.
4. File-based routes load the relevant blueprint and pass it to `<PageComposer nodes={blueprint.sections} />`, keeping `.astro` files thin.

## Forms

- Form schemas (fields, copy) live in `src/configs/forms`.
- `FormField` (molecule) handles individual input rendering.
- `ContactSection` (organism) drops in the form + map card with a consistent layout.

## Extending the System

1. **New Atom/Molecule**: create a folder, define `*.astro`, local types, and export from `index.ts`.
2. **New Organism**: compose atoms/molecules, add it to `component-registry.ts` if you want to reference it from blueprints.
3. **New Page**:
   - Add a blueprint under `src/configs/pages/<name>.ts`.
   - Create `src/pages/<name>.astro` that imports the blueprint and renders `<PageComposer />`.
4. **Interactive features**: drop React/Vue/Svelte components into `src/components/islands` and register them like any other component.

This layout keeps responsibilities explicit, minimizes coupling, and lets the configuration layer drive the experience while components stay reusable and predictable.
