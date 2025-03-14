# Changelog for GraphAppToolkit

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Updated docs for the module.
- Release Candidate

## [0.2.0-preview0001] - 2025-03-14

### Added

- Added cert options to the GraphAppToolkit send email.
- Updated auth methods to invoke needed permissions only.
- Added private functions to handle existing certs and secrets.
- Added support for -WhatIf and -Confirm parameters to cmdlets.
- Renamed private function "New-TkAppName" to "Initialize-TkAppName".
- Renamed private function "New-TkRequiredResourcePermissionObject" to "Initialize-TkRequiredResourcePermissionObject".
- Updated documentation across the module (README.md, help XML files, and about_GraphAppToolkit.help.txt).
- Enhanced logging in private functions for improved auditability.
- Switch parameter for removing domain suffix from the app name.
- Certificate subject to param splat export.
- Permissions to comment based help.
- Initial test cases structure for Pester with rudimentary tests.

### Fixed

- Fixed formatting.
- Manual app call for sending email.
- Confirm to high for connect function.
- Corrected parameter block formatting and alignment issues in multiple cmdlets.
- Fixed Connect function ShouldProcess output.

## [0.1.2] - 2025-03-11

### Added

- Added class definitions for GraphAppToolkit

## [0.1.1] - 2025-03-10

### Added

- Add tools for documentation and initial HTML help
- Initial README.md file
- Initial help documentation
- Updated Help docs and readme post initial testing

### Fixed

- Fix param block alignment and added help messages to parameters
- Aligned comment blocks in functions with the code

## [0.1.0-initial] - 2025-03-10

### Added

- Initial release of GraphAppToolkit
