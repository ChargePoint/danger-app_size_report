# danger-app_size_report

A [Danger](https://github.com/danger/danger) plugin that reports size violations for iOS Apps and App Clips. A valid [App Thinning Size Report](https://developer.apple.com/documentation/xcode/reducing-your-app-s-size) must be passed to the plugin for accurate functionality.

## Installation

    $ gem install danger-app_size_report

## Usage

### `flag_violations`

Report app size violations given a valid App Thinning Size Report.

    // Dangerfile

    report_path = "/Path/to/AppSizeReport.txt"
    app_size_report.flag_violations(
        report_path, 
        build_type: 'App', 
        size_limit: 4, 
        limit_unit: 'GB', 
        fail_on_warning: false
    )

#### Parameters

- `report_path` [String, required] Path to valid App Thinning Size Report text file.
- `build_type` [String, optional] [Default: 'App'] Specify whether the report corresponds to an App or an App Clip. 
  - Supported values: 'App', 'Clip'
- `size_limit` [Numeric, optional] [Default: 4] Specify the app size limit. 
- `limit_unit` [String, optional] [Default: 'GB'] Specific the unit for the given size limit.
  - Supported values: 'KB', 'MB', 'GB'
- `fail_on_warning` [Boolean, optional] [Default: false] Specify whether the PR should fail if one or more app variants exceed the given size limit. By default, the plugin issues a warning in this case. 

### `report_json`

Returns a JSON string representation of the given App Thinning Size Report.

    // Dangerfile
    
    report_path = "/Path/to/AppSizeReport.txt"
    app_size_json = app_size_report.report_json(report_path)

#### Parameters

- `report_path` [String, required] Path to valid App Thinning Size Report text file.

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
