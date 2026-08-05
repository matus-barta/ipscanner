# Contributing to IP Scanner

Thank you for contributing to IP Scanner.

## Licensing

IP Scanner is licensed under GPL-3.0-only with the additional
App Store distribution permission described in
`APP_STORE_EXCEPTION.md`.

By intentionally submitting a contribution for inclusion in
IP Scanner, you agree to license that contribution under
GPL-3.0-only together with the same App Store distribution
exception.

You retain copyright ownership of your contribution.

## Contributor responsibilities

By submitting a contribution, you confirm that:

- You created the contribution or have the right to submit it.
- You have permission to license it under the project's terms.
- It does not knowingly contain incompatible third-party code,
  data, or artwork.
- Any third-party material is clearly identified with its source
  and license.
- If an employer owns the contribution, you have permission to
  submit it.

## Development guidelines

Before opening a pull request:

1. Build both the macOS and iPadOS targets.
2. Test the affected platform.
3. Keep platform-independent code under `Shared`.
4. Document any new dependencies, resources, or permissions.
5. Format the updated files with swift format, run: `swiftformat .` in root of the project and review the changes
