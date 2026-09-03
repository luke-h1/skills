---
name: react-native-project-structure
description: Folder structure and file placement conventions for React Native/Expo apps with Expo Router. Use when scaffolding a new React Native project, deciding where a new file, component, hook, util, or test should live, or reviewing a project's layout. Covers colocated utils, __tests__ folders, and the no-barrel-export rule.
---

# React Native Project Structure

How to lay out a React Native/Expo app with Expo Router. Follow this when creating files in a new or existing project; if an existing project has a conflicting committed convention, follow that project.

## Layout

```
├── assets/                       # fonts, images, static files
├── modules/                      # local Expo native modules (Swift/Kotlin)
├── plugins/                      # Expo config plugins
├── patches/                      # package patches
├── scripts/                      # build/deploy/release shell + TS scripts
├── e2e/                          # end-to-end tests (Maestro etc.)
├── src/
│   ├── app/                      # Expo Router routes ONLY — every file is a route
│   │   ├── _layout.tsx
│   │   ├── index.tsx
│   │   └── tabs/
│   ├── components/               # reusable UI shared across screens
│   │   ├── Button/
│   │   │   ├── Button.tsx        #   root file named after the folder, NOT index.tsx
│   │   │   └── Button.stories.tsx
│   │   └── Chat/                 #   complex component → nested tree, see below
│   ├── screens/                  # screen bodies that route files render
│   │   └── Stream/
│   │       ├── LiveStreamScreen.tsx
│   │       ├── components/       #   private to this screen — not shared
│   │       ├── useSleepTimer.ts  #   screen-private hook, colocated
│   │       └── __tests__/
│   ├── hooks/                    # reusable hooks; hooks/queries/ for react-query
│   ├── services/                 # HTTP/WS API clients ONLY — no UI, no state
│   ├── store/                    # app state (see store layout below)
│   ├── utils/                    # shared pure utils, grouped by domain
│   │   ├── string/
│   │   ├── date-time/
│   │   └── __tests__/
│   ├── lib/                      # third-party library wrappers, named after the library
│   │   ├── react-query/
│   │   └── expo-image/
│   ├── types/                    # external API types, one folder per provider
│   ├── context/                  # React contexts
│   ├── Providers/                # provider components composing app-level setup
│   ├── constants/                # cross-file constants
│   ├── styles/                   # theme, colors, shared style helpers
│   ├── i18n/                     # i18next setup + locales/
│   └── dev/                      # dev-only tooling, gated out of prod bundles
├── app.config.ts
├── eas.json
└── package.json
```

Alias `@app/*` → `./src/*` in `tsconfig.json`. `src/app` is routes-only; screen UI lives in `src/screens`, with the route file doing route concerns (params) and rendering the screen component.

## No index files, no barrel exports

Never create `index.ts`/`index.tsx` re-export files. The root of a component folder is a file named after the folder, and imports always use the full path including the filename:

```ts
import { Button } from '@app/components/Button/Button';
import { formatViewerCount } from '@app/utils/number/formatViewerCount';
```

Barrels hide where code lives, break tree-shaking, and invite circular imports. A rename or move should change import paths — that is a feature.

## Colocate by owner, promote on sharing

Everything private to a component or screen lives inside its folder; only promote to a top-level dir (`components/`, `hooks/`, `utils/`) when a second unrelated consumer appears. A complex component becomes a nested tree mirroring the top-level shape:

```
components/Chat/
├── Chat.tsx                  # root, named after the folder
├── components/               # private sub-components (each may nest again)
├── hooks/                    # useChatScroll.ts, useChatSession.ts…
├── util/                     # pure helpers used only by Chat (singular `util`)
├── types/
├── styles.ts
└── __tests__/
```

Colocated helper dirs are singular `util/`; only the shared top-level `src/utils/` is plural. Pure functions go in `util/`, hooks in `hooks/` — never mix the two.

## Tests and fixtures

Tests live in a `__tests__/` directory beside the code under test — not in `.test.ts` files next to sources, and not in a separate top-level test tree. Every level can have its own: `src/utils/__tests__/`, `components/Chat/hooks/__tests__/`, `src/app/__tests__/`.

Shared fixtures go in `__tests__/__fixtures__/`, named `{thing}.fixture.ts` after the surface they support (`useChat.fixture.ts`, not `chatFixtures.ts`). Jest mocks for whole packages go in a root `__mocks__/`.

## Naming

- **PascalCase** for component and screen files and their folders: `LiveStreamCard/LiveStreamCard.tsx`, `screens/Stream/`.
- **camelCase** for everything else: hooks (`useSleepTimer.ts`), utils, stores, services, types files.
- Platform splits use extensions, imported extension-free: `ChatComposer.tsx` + `ChatComposer.ios.tsx`, `bar.web.tsx`. Props must match across variants and a default (no-extension) file must exist.
- Style objects stay at the bottom of the component file, or in a colocated `styles.ts` / `{name}Styles.ts` when large — never a top-level styles dump.

## Store layout

State libraries get a per-domain folder split so components never import the state library's primitives directly:

```
store/chat/
├── observables/    # module-level state
├── actions/        # pure mutations, no React
├── react/          # hooks components consume
├── types/
└── __tests__/
```

## Boundaries worth enforcing

- `services/` talks to the network and nothing else; screens consume it through `hooks/queries/`.
- `lib/` wraps third-party packages so the rest of the app imports your wrapper, not the package (`@app/lib/react-query/queryClient`).
- `dev/` code must be require-gated so it never ships in production bundles.
- Native code lives in `modules/`; `ios/` and `android/` stay generated (and gitignored under CNG/prebuild).
