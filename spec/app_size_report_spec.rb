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
        json_string = @app_size_report.report_json("#{File.dirname(__dir__)}/Resources/App\ Thinning\ Size\ Report\ CPClip.txt")

        expected_json = File.read("#{File.dirname(__dir__)}/Resources/expectedReportJSON.json")

        expect(json_string).to eq(expected_json)
      end

      it 'Generates IOS App Size Danger Report for Clip' do
        @app_size_report.flag_ios_violations(
          "#{File.dirname(__dir__)}/Resources/App\ Thinning\ Size\ Report\ CPClip.txt",
          build_type: 'Clip',
          limit_size: 12,
          limit_unit: 'MB'
        )

        expect(@dangerfile.status_report[:warnings]).to eq(['The size limit of 10 MB has been exceeded by one or more variants'])
      end

      it 'Generates IOS App Size Danger Report for App' do
        @app_size_report.flag_ios_violations(
          "#{File.dirname(__dir__)}/Resources/App\ Thinning\ Size\ Report\ CP.txt",
          build_type: 'App',
          limit_size: 45,
          limit_unit: 'MB'
        )

        expect(@dangerfile.status_report[:warnings]).to eq(['The size limit of 45 MB has been exceeded by one or more variants', 'The optimal cellular size limit of 200 MB has been exceeded by one or more variants'])
      end

      it 'Generates Android App Size Danger Report' do
        @app_size_report.flag_android_violations(
          "#{File.dirname(__dir__)}/Resources/app.aab",
          "#{File.dirname(__dir__)}/Resources/testKey1",
          'testKey1',
          'testKey1',
          'testKey1',
          screen_densities: %w[MDPI HDPI XHDPI XXHDPI XXXHDPI],
          languages: %w[en de da es fr it nb nl sv],
          build_type: 'Instant',
          limit_size: 1.459,
          limit_unit: 'MB'
        )

        expect(@dangerfile.status_report[:warnings]).to eq(['The size limit of 1.459 MB has been exceeded by 18 variants'])
      end
    end
  end
end
