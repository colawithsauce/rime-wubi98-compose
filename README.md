# rime-wubi98-compose

A small Rime schema for Wubi 98 users who want to keep composing after the
fourth code instead of committing the first candidate on the fifth key.

## What It Changes

The schema is based on the normal `wubi98_ci` table workflow, but changes the
core speller behavior and adds a Lua composer:

```yaml
speller:
  auto_select: false
  max_code_length: 0

translator:
  enable_sentence: false
  enable_encoder: false
  encode_commit_history: false
  enable_user_dict: false

four_code_composer:
  chunk_size: 4
  per_chunk_limit: 5
```

This means:

- the fifth code no longer commits the selected four-code candidate;
- unique candidates are not auto-committed;
- longer plain code input is composed greedily as four-code chunks first.

For example, `abcdef` is composed as `abcd'ef`, not as `abc'def`, when both
chunks can be found in the dictionary. Earlier chunks are fixed to their current
first candidate, while the last chunk contributes several selectable
alternatives. The native table-translator sentence composer is disabled for this
schema because it chooses a weighted sentence path and may prefer non-four-code
splits.

Sentence composition and phrase learning are separate paths in Rime, but they
can meet in a surprising way. Native `enable_sentence` lets the table translator
build sentence candidates; memorization happens later through writable
user-dictionary memory hooks.

This schema uses a Lua candidate instead of native `enable_sentence`, and keeps
`enable_user_dict`, `enable_encoder`, and `encode_commit_history` disabled. If
you copy this into a larger Wubi schema, check every `table_translator` that
shares the same dictionary language, not only the main `translator`.

For example, a copied schema may still contain translators like
`table_translator@fixed`, `table_translator@mkst`, or reverse-lookup helpers. If
any table translator for the same Wubi dictionary keeps a writable user
dictionary / encoder path, committed sentence candidates can still be memorized.
For a no-learning compose variant, set these on all such table translators:

```yaml
enable_user_dict: false
enable_encoder: false
encode_commit_history: false
```

## Requirements

This repository does not include a Wubi dictionary. It expects you already have:

- `wubi98_ci.dict.yaml`
- `wubi98_ci.extended.dict.yaml`

The schema references `wubi98_ci.extended`.

## Install

Copy these into your Rime user directory:

- `wubi98_ci_compose.schema.yaml`
- `lua/four_code_composer.lua`

Add the schema to `default.custom.yaml`:

```yaml
patch:
  schema_list:
    - { schema: wubi98_ci }
    - { schema: wubi98_ci_compose }
```

Then redeploy Rime.

If you merged this with an existing schema, inspect the compiled schema after
redeploy and make sure no Wubi table translator still has phrase learning
enabled:

```sh
rg -n "enable_user_dict|enable_encoder|encode_commit_history" \
  ~/Library/Rime/build/wubi98_ci_compose.schema.yaml
```

On macOS with Squirrel, the user directory is usually:

```text
~/Library/Rime
```

## Notes

This is an experimental compose-oriented variant. Wubi is a fixed-shape code
input method, so long composition quality depends heavily on the dictionary and
Rime table translator behavior. The original fast four-code workflow is still
better for users who prefer immediate auto-commit.

Rime's table translator already supports sentence composition, but its weighted
path can choose splits such as `abc'def`. This variant keeps the separate Wubi
98 schema while replacing native sentence composition with a small four-code
greedy Lua composer.
