# Dev and Deploy Agents

## Overview

These agents rely on the overarching [Human OS Architecture](Human_OS_Architecture.md).

**Dev Agent** handles development tasks like mapping data and preparing new verticals. It runs the initial vertical mapping and sets up configuration files.

**Deploy Agent** takes the generated artifacts from Dev Agent and publishes them. It updates production configurations and ensures the vertical is live.

## Generating a New Vertical

1. Run the vertical mapping through Dev Agent.
2. Review the generated files.
3. Call Deploy Agent to publish the new vertical.

## Configuration Example (Placeholder)

```yaml
# mapping_consulting.yml
# Example configuration for a consulting vertical
```

## Manual Review Best Practices

- Check all generated mappings for accuracy before deployment.
- Verify that configuration files conform to repository standards.
- Ensure sensitive data is not committed.
