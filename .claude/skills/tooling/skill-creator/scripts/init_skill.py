#!/usr/bin/env python3
"""
Skill Initializer - Creates a new skill directory with template files

Usage:
    python init_skill.py <skill-name> --path <output-directory>

Example:
    python init_skill.py my-new-skill --path .claude/skills/tooling
"""

import sys
import os
import argparse
from pathlib import Path

SKILL_MD_TEMPLATE = '''---
name: {name}
description: TODO - Describe what this skill does and when it should be used. Include specific triggers and contexts.
---

# {title}

TODO: Write instructions for using this skill.

## Overview

Describe the skill's purpose and capabilities.

## Usage

### When to Use

- Trigger condition 1
- Trigger condition 2

### Workflow

1. Step 1
2. Step 2
3. Step 3

## References

- See `references/` for detailed documentation (load as needed)

## Scripts

- See `scripts/` for executable utilities (run as needed)
'''

EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
"""
Example script - Replace with actual functionality

Usage:
    python example.py <input>
"""

import sys


def main():
    if len(sys.argv) < 2:
        print("Usage: python example.py <input>")
        sys.exit(1)

    input_arg = sys.argv[1]
    print(f"Processing: {input_arg}")
    # TODO: Implement actual functionality


if __name__ == "__main__":
    main()
'''

EXAMPLE_REFERENCE = '''# Reference Document

TODO: Add detailed reference material here.

This file is loaded into context only when Claude determines it's needed,
keeping the main SKILL.md lean.

## Section 1

Details...

## Section 2

Details...
'''


def init_skill(name, output_path):
    """Create a new skill directory with template files."""
    # Validate name (kebab-case)
    if not all(c.isalnum() or c == '-' for c in name):
        print(f"Error: Skill name '{name}' must be kebab-case (lowercase letters, digits, hyphens)")
        return False

    if name.startswith('-') or name.endswith('-') or '--' in name:
        print(f"Error: Name '{name}' cannot start/end with hyphen or contain consecutive hyphens")
        return False

    skill_dir = Path(output_path) / name
    if skill_dir.exists():
        print(f"Error: Directory already exists: {skill_dir}")
        return False

    # Create directories
    skill_dir.mkdir(parents=True)
    (skill_dir / "scripts").mkdir()
    (skill_dir / "references").mkdir()
    (skill_dir / "assets").mkdir()

    # Create SKILL.md
    title = name.replace('-', ' ').title()
    skill_md = SKILL_MD_TEMPLATE.format(name=name, title=title)
    (skill_dir / "SKILL.md").write_text(skill_md)

    # Create example files
    (skill_dir / "scripts" / "example.py").write_text(EXAMPLE_SCRIPT)
    (skill_dir / "references" / "example.md").write_text(EXAMPLE_REFERENCE)
    (skill_dir / "assets" / ".gitkeep").write_text("")

    print(f"Skill initialized at: {skill_dir}")
    print(f"  SKILL.md - Edit frontmatter and instructions")
    print(f"  scripts/example.py - Replace with actual scripts")
    print(f"  references/example.md - Replace with actual references")
    print(f"  assets/.gitkeep - Add template files here")
    print(f"\nNext: Edit SKILL.md and replace example files with real content.")
    return True


def main():
    parser = argparse.ArgumentParser(description="Initialize a new Claude skill")
    parser.add_argument("name", help="Skill name (kebab-case)")
    parser.add_argument("--path", required=True, help="Output directory")
    args = parser.parse_args()

    success = init_skill(args.name.lower(), args.path)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
