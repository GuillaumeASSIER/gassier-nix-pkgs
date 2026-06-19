# Devcontainer Configuration

Ce dossier contient la configuration du devcontainer pour ce projet Nix.

## Utilisation

### Avec VS Code

1. Installez l'extension "Dev Containers" de Microsoft
2. Ouvrez le dossier du projet dans VS Code
3. Cliquez sur le bouton "Reopen in Container" ou utilisez la commande `Dev Containers: Reopen in Container`

VS Code va alors construire l'image Docker et ouvrir le projet dans le container.

### Commandes Nix disponibles

Une fois dans le devcontainer, vous aurez accès à :

- `nix flake update` - Mettre à jour les dépendances du flake
- `nix flake check` - Vérifier la configuration du flake
- `nix build` - Construire les packages
- `nix develop` - Entrer dans un shell de développement avec les dépendances
- `nix-shell` - Entrer dans un shell de développement (alternative)

### Exemple d'utilisation

```bash
# Construire le package par défaut
nix build

# Entrer dans l'environnement de développement
nix develop

# Vérifier la configuration
nix flake check

# Mettre à jour les dépendances
nix flake update
```

## Extensions VS Code pré-installées

- **nix-ide** - Support du langage Nix avec formatage
- **Nix** - Support syntax highlighting pour Nix
- **direnv** - Support pour direnv (.envrc)

## Fichiers de configuration

- `Dockerfile` - Image Docker avec Nix installé
- `devcontainer.json` - Configuration VS Code pour le devcontainer

## Notes

- L'utilisateur `nix-dev` est créé pour les opérations de développement
- Les features expérimentales de Nix sont activées pour supporter les flakes
- Votre configuration SSH et Git locale est montée en lecture seule
