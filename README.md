# danger-app_size_report

Danger-app_size_report. A danger plugin for reporting app sizes.

## Installation
put `gem danger-app_size_report` to your project 'Gemfile'

## Usage

Convert XCResult to json using XCParse (branch https://github.com/ChargePoint/xcparse/pull/57)

Simply add `app_size_report.report` to your `Dangerfile` passing the path to report JSON path and app size limit.

Then add this code to the danger file.
    ```ruby
    app_size_report.report(
        "[report path]", 
        10
    )
    ```
Please replace [report path] to where XCParse conversion is located

### Contributing
If you like what you see and willing to support the work, you could:
- Open an [issue](https://github.com/ChargePoint/danger-app_size_report/issues/new)
- Contribute code, and pull requests.