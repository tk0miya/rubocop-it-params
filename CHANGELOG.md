## [Unreleased]

## [1.0.0] - 2026-08-05

Initial release.

- `Style/PreferItParameter`: recommends the `it` block parameter (Ruby 3.4+) over a named
  block argument in single-line blocks. Autocorrection is available but unsafe, so
  `rubocop -A` is required to apply it. Only projects with `TargetRubyVersion` 3.4 or
  higher are inspected; see the README for the cases the cop skips.
