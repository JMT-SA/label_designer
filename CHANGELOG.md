# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres roughly to [Semantic Versioning](http://semver.org/).


## [Unreleased]
### Added
- Label Publishers email group. All users in the group will receive an email on label approval.
- UI theme was changed to use blues.
### Changed
### Fixed
- DB connection was lost soon after Passenger was restarted due to child processes using the parent process connection after forking.
- Drb connection to shared_config was not closing sockets after use.

## [0.5.0] - 2019-03-29
### Added
- Exceptions are emailed. The recipients and subject prefix can be configured.
- On publish, any paths in LABEL_PUBLISH_NOTIFY_URLS are sent a JSON package with a list of published labels and their variables so that those applications can maintain their label template definitions.
- Label designs can include static barcode variables.
### Changed
- User maintainer security for maintaining users.
- User permissions security for allocating users to programs.

## [0.4.1] - 2019-02-15
### Added
- Email a preview image to someone for approval.
- Batch print a label.
### Changed
- Only approved labels can be published.

## [0.4.0] - 2019-02-07
### Added
- User email groups.
- Labels can be completed, approved, rejected and reopened.
### Changed
- Upgrade framework: DRY gems.
- Upgrade jQuery ContextMenu.
- Modified status display.
- Services are observable.
- Simple page layout for login.

## [0.3.5] - 2019-01-24
### Added
- Dataminer module included.
- Created by and Updated by on labels.
- Labels can be archived and un-archived (active/inactive).
- Publishing of labels is logged and uses the job queue to do the work.
### Changed
- Status logging for create, link and delete of labels.
- List of variables for a label can be configured via the variable set and shared_config.

## [0.3.0] - 2019-01-04
### Added
- Action on labels grid: `Refresh preview values from sub-labels` - combines preview values from a multi-label's sub-labels, replacing sample_data for the mult-label.
- Job queues using Que gem.
- Send email using the `Mail` gem. `config/mail_settings.rb` must be set up and a default sender address must be set up in the `.env.local` file for `SYSTEM_MAIL_SENDER`.
- Calculated columns for grids.
- RMD (Registered Mobile Devices) functionality for scanning on Android hardware.
- Log status functionality.
- Document sequence rules for creating document serial numbers.
### Changed
- Roda::DataGrid update to the way list grids are defined (using Crossbeams::DataGrid::ListGridDefinition instead of calling layout's grid renderer).
- All fetch requests expect JSON responses. This mostly affects dialog-building responses which were returning HTML text. All `return_json_response` calls replaced by one in the main route.
- Grid rows can be coloured simply by providing a class in a column named `colour_rule`.
- Capture locations.
- AG Grid upgraded to 1.19.2.
- AppLoader for bootstrapping (the code was moved from label_designer.rb)

## [0.2.3] - 2018-09-17
### Changed
- Label name is no longer constrained to 16 character length.
- Label name must be unique.

## [0.2.2] - 2018-08-27
### Changed
- Crossbeams::LabelDesigner upgraded to version 0.1.7 (Canvas scrolling changed, fix bug with undo).

## [0.2.1] - 2018-08-22
### Changed
- Crossbeams::LabelDesigner upgraded to version 0.1.6 (Lato Light font added, toolbar redesign).

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
