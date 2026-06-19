# Contributing to gassier-nix-pkgs

Thank you for your interest in contributing to this project!

## Code of Conduct

- Be respectful
- Accept constructive criticism
- Focus on what's best for the community

## How to Contribute

### Report a Bug

1. Check if the bug has already been reported
2. Provide a clear description of the issue
3. Include steps to reproduce
4. Mention your environment (system, Nix version, etc.)

### Propose an Enhancement

1. Use a clear and descriptive title
2. Provide a usage example
3. List relevant resources

### Add a New Package

1. Create a new branch: `git checkout -b feat/my-package`
2. Follow the existing structure in `pkgs/mimo-code/`
3. Test your package:
   ```bash
   nix build .#my-package
   ```
4. Submit a pull request with a clear description

### Submit a Pull Request

1. Ensure your code follows project conventions
2. Test your change: `nix build`
3. Write a clear description of your change
4. Branches with prefixes `feat/`, `fix/`, `docs/` are welcome

## Commit Style

We use semantic commits:
- `feat:` - new feature/package
- `fix:` - bug fix
- `docs:` - documentation
- `chore:` - tasks (dependencies, etc.)
- `refactor:` - refactoring

Example:
```
feat(packages): add new-awesome-tool package
```

## Questions?

Open an issue or start a discussion!
