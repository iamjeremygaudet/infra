# Caddy Docker Custom Builds

[GitHub Repository](https://github.com/serfriz/caddy-custom-builds/tree/main)

**Badges:**  
GitHub release (latest SemVer) | GitHub build status | License

Caddy takes a modular approach to building Docker images, allowing users to include only the modules they need. This repository aims to provide flexibility and convenience to run Caddy with specific combinations of modules by providing pre-built images according to the needs and preferences of the users.

All custom images are updated automatically when a new version of Caddy is released using the official Caddy Docker image. This is done by using GitHub Actions to build and push the images for all Caddy supported platforms to Docker Hub, GitHub Packages, and Quay container registries.

Since the update cycle of many modules is faster than Caddy's, all custom images are periodically rebuilt with the latest version of their respective modules on the first day of every month. If you are already running Caddy's latest version, you can force an update by re-creating the container (for example, by running `docker compose up --force-recreate` if using Docker Compose).

All commits and tags are signed with a GPG key to ensure their integrity and authenticity. Two-factor authentication (2FA) is enabled for all accounts involved in managing this repository and the container registries.
