---
paths:
  - config/locales/**/*.yml
  - app/frontend/**/*.svelte
  - app/reads/**
  - db/cases/reference.yml
  - lib/demo/seed.rb
---

# Player-facing copy

Read `docs/design/voice.md` before writing or changing anything a player or the Instructor reads. It is the spec. Where this file and it disagree, it wins.

`CONTEXT.md` supplies the vocabulary and none of the prose. It explains design decisions to developers, so a sentence lifted from it reads as a design note on the page. `spec/copy/context_prose_spec.rb` fails on a lifted sentence. Its allowlist only shrinks, so never add to it.

Legal accuracy is judged separately from voice (#387).
