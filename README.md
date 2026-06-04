# rime-wubi98-compose

A small Rime schema for Wubi 98 users who want to keep composing after the
fourth code instead of committing the first candidate on the fifth key.

## What It Changes

The schema is based on the normal `wubi98_ci` table workflow, but changes the
core speller behavior:

```yaml
speller:
  auto_select: false
  max_code_length: 0

translator:
  enable_sentence: true
```

This means:

- the fifth code no longer commits the selected four-code candidate;
- unique candidates are not auto-committed;
- Rime can continue composing longer input, closer to a Pinyin-style workflow.

## Requirements

This repository does not include a Wubi dictionary. It expects you already have:

- `wubi98_ci.dict.yaml`
- `wubi98_ci.extended.dict.yaml`

The schema references `wubi98_ci.extended`.

## Install

Copy `wubi98_ci_compose.schema.yaml` into your Rime user directory.

Add the schema to `default.custom.yaml`:

```yaml
patch:
  schema_list:
    - { schema: wubi98_ci }
    - { schema: wubi98_ci_compose }
```

Then redeploy Rime.

On macOS with Squirrel, the user directory is usually:

```text
~/Library/Rime
```

## Notes

This is an experimental compose-oriented variant. Wubi is a fixed-shape code
input method, so long composition quality depends heavily on the dictionary and
Rime table translator behavior. The original fast four-code workflow is still
better for users who prefer immediate auto-commit.
