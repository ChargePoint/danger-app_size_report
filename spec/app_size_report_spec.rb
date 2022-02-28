# frozen_string_literal: false

require File.expand_path('spec_helper', __dir__)

module Danger
  describe Danger::DangerAppSizeReport do
    it 'should be a plugin' do
      expect(Danger::DangerAppSizeReport.new(nil)).to be_a Danger::Plugin
    end

    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @app_size_report = @dangerfile.app_size_report
      end

      it 'Converts App Size Report to JSON' do
        json_string = @app_size_report.report_json("#{File.dirname(__dir__)}/Resources/App\ Thinning\ Size\ Report.txt")

        expected_json = File.read("#{File.dirname(__dir__)}/Resources/expectedReportJSON.json")

        expect(json_string).to eq(expected_json)
      end

      it 'Generates IOS App Size Danger Report' do
        @app_size_report.flag_violations(
          "#{File.dirname(__dir__)}/Resources/App\ Thinning\ Size\ Report.txt",
          build_type: 'Clip',
          size_limit: 12,
          limit_unit: 'MB'
        )

        expect(@dangerfile.status_report[:warnings]).to eq(['The size limit of 10 MB has been exceeded by one or more variants'])
      end

      it 'Generates Android App Size Danger Report' do
        @app_size_report.flag_android_violations(
          "#{File.dirname(__dir__)}/Resources/app.aab",
          "#{File.dirname(__dir__)}/Resources/testKey1",
          "testKey1",
          "testKey1",
          "testKey1",
          screen_densities: ["MDPI", "HDPI", "XHDPI", "XXHDPI", "XXXHDPI"],
          languages: ["en", "de", "da", "es", "fr", "it", "nb", "nl", "sv"],
          build_type: 'Instant',
          size_limit: 1.459,
          limit_unit: 'MB',
        )

        expect(@dangerfile.status_report[:warnings]).to eq(['The size limit of 1.459 MB has been exceeded by 18 variants'])
      end
    end
  end
end
