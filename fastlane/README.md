# Fastlane Setup for Sparkley

This directory contains Fastlane configuration for building and releasing Sparkley.

## Setup

1. Install Ruby dependencies:

```bash
bundle install
```

2. Copy the environment template and add your secrets:

```bash
cp .env.example .env
```

3. Edit `.env` and add your GitHub Personal Access Token:
   - Go to https://github.com/settings/tokens
   - Create a token with `repo` or `public_repo` scope
   - Add it to `.env` as `GITHUB_TOKEN`

## Available Lanes

### Build

```bash
# Build without code signing (for testing/CI)
bundle exec fastlane build_unsigned

# Build with Developer ID signing (requires Apple Developer account)
bundle exec fastlane build
```

### Archive

```bash
# Create a zip archive of the built app
bundle exec fastlane archive
```

### Release

```bash
# Build and create a GitHub release
bundle exec fastlane release

# Create a draft release (won't be public until you publish it)
bundle exec fastlane release_draft

# Create a prerelease
bundle exec fastlane release prerelease:true
```

### Version Management

```bash
# Bump patch version (1.0.0 -> 1.0.1)
bundle exec fastlane bump type:patch

# Bump minor version (1.0.0 -> 1.1.0)
bundle exec fastlane bump type:minor

# Bump major version (1.0.0 -> 2.0.0)
bundle exec fastlane bump type:major
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app

      - name: Build and Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: bundle exec fastlane release
```

## Code Signing (Optional)

For distributing signed builds outside the App Store, you need:

1. An Apple Developer account ($99/year)
2. A "Developer ID Application" certificate
3. Export the certificate and add to your keychain

Then update your `.env`:

```
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
```

And use `bundle exec fastlane build` instead of `build_unsigned`.

## Notes

- The `build_unsigned` lane creates a functional app that runs on your Mac but shows a security warning on first launch
- For distribution to others, consider signing with Developer ID or distributing via the App Store
- GitHub releases are created with the version number from the Xcode project
