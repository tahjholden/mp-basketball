# Vertical Mapper

This utility converts the canonical MP-Basketball SQL migrations and n8n workflow files
into a new domain by applying string replacements defined in a YAML mapping file.
See the [Human OS Architecture](../../docs/Human_OS_Architecture.md) for how verticals integrate with the broader system.

It requires the [PyYAML](https://pyyaml.org/) package to parse the mapping file.

## Usage

```
python tools/vertical_mapper/vertical_mapper.py \
  --mapping tools/vertical_mapper/mapping_consulting.yml \
  --sql-dir supabase/migrations \
  --workflow-dir workflows \
  --dist-dir dist/consulting
```

The script will create the target directory (e.g. `dist/consulting/`) and write the
modified SQL and JSON files there.

### Mapping YAML

A mapping file contains `tables`, `fields` and `values` sections. Each section
specifies simple text replacements:

```yaml
tables:
  player: consultant
  coach: manager
fields:
  first_name: given_name
values:
  Player: Consultant
```
