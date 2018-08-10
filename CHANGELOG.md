# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres roughly to [Semantic Versioning](http://semver.org/).


## [Unreleased]
### Added
### Changed
### Fixed

## [0.2.0] - 2018-08-10
### Changed
- All icon usage changed from using FontAwesome to using embedded SVG icons.
- Font sizes adapt to label resolution to produce more accurate printed sizes. Requires each text box in every label to be selected and the label saved to store the new correct sizes. NB: This can make text slightly smaller or larger and bounding boxes may need to be resized or font size changed.

## [0.1.5] - 2018-07-06
### Changed
- Upgrade Konva from version 1.6.0 to version 2.1.7 (specifically to fix an error where the background image was saved with the wrong dimensions).

## [0.1.4] - 2018-06-22
- Upgrade framework.
- AG-Grid version 18.

## [0.1.3] - 2018-04-09
### Changed
- Audit changes to labels table.
- Validation changes to manage stripping input strings.
- AG-Grid version 17. New theme "balham".
- Make user login case-insensitive.

## [0.1.2] - 2018-03-04
### Added
- Capistrano deploy.
### Changed
- Menu system linked to web application.
- Rake tasks respect dotenv local override for database url.
- Skipped version 0.1.1.

## [0.1.0] - 2018-02-12
### Added
- This changelog.
### Changed
- Move to Ruby 2.5.
