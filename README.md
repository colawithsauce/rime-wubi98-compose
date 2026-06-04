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
  enable_encoder: false
  encode_commit_history: false
  enable_user_dict: false
```

This means:

- the fifth code no longer commits the selected four-code candidate;
- unique candidates are not auto-committed;
- Rime can continue composing longer input, closer to a Pinyin-style workflow.

Sentence composition and phrase learning are separate paths in Rime, but they
can meet in a surprising way. `enable_sentence` lets the table translator build
sentence candidates; memorization happens later through writable user-dictionary
memory hooks.

In a small schema with only the translator shown here, disabling
`enable_user_dict`, `enable_encoder`, and `encode_commit_history` prevents this
variant from learning the composed sentence as a phrase. If you copy this into a
larger Wubi schema, check every `table_translator` that shares the same
dictionary language, not only the one that has `enable_sentence: true`.

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

Copy `wubi98_ci_compose.schema.yaml` into your Rime user directory.

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

Rime's table translator already supports sentence composition; this schema just
turns that behavior on for a separate Wubi 98 variant while removing the
four-code auto-commit boundary.
