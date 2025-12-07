fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac build_signed

```sh
[bundle exec] fastlane mac build_signed
```

Build and sign the macOS app with Developer ID

### mac build_unsigned

```sh
[bundle exec] fastlane mac build_unsigned
```

Build without signing (for testing)

### mac notarize_app

```sh
[bundle exec] fastlane mac notarize_app
```

Notarize the app with Apple using App Store Connect API

### mac build_notarized

```sh
[bundle exec] fastlane mac build_notarized
```

Build, sign, and notarize the app

### mac archive

```sh
[bundle exec] fastlane mac archive
```

Create a zip archive of the app

### mac release

```sh
[bundle exec] fastlane mac release
```

Build, archive, and release UNSIGNED to GitHub

### mac release_signed

```sh
[bundle exec] fastlane mac release_signed
```

Build, sign, notarize, and release to GitHub

### mac release_draft

```sh
[bundle exec] fastlane mac release_draft
```

Create a draft release (unsigned)

### mac release_draft_signed

```sh
[bundle exec] fastlane mac release_draft_signed
```

Create a signed draft release

### mac bump

```sh
[bundle exec] fastlane mac bump
```

Bump version number

### mac generate_appcast

```sh
[bundle exec] fastlane mac generate_appcast
```

Generate Sparkle appcast from releases

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
