---
applyTo: ".github/workflows/**"
---
# GitHub Actions CI/CD Instructions

- Use the latest stable versions of official GitHub Actions (actions/checkout@v4, actions/setup-java@v4, actions/setup-node@v4).
- Pin action versions to major version tags, not commit SHAs.
- Run CI on pull_request events targeting main branch.
- Run CD on push events to main branch (after CI passes).
- Use job-level permissions with least privilege (contents: read by default).
- Cache Maven dependencies using the built-in `cache: maven` parameter on actions/setup-java, or explicitly with actions/cache and ~/.m2/repository path.
- Cache npm dependencies using the built-in `cache: npm` parameter on actions/setup-node, or explicitly with actions/cache and ~/.npm path.
- Use matrix strategy for testing across multiple Java or Node versions when applicable.
- Include explicit timeout-minutes on long-running jobs (default: 30).
- Use environment variables for configuration, not hardcoded values.
- Separate CI (build + test) and CD (deploy) into distinct workflow files.
- Include a health check step after deployment.
- Use GitHub environment secrets for Azure deployment credentials.
