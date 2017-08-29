# frozen_string_literal: true

require 'spec_helper'
require 'rspec/structured_data_matcher'
require 'net/http'

describe 'validate schema.org output' do
  Dir.glob('_site/examples/**/*.html') do |fn|
    it "#{fn} has valid Schema.org output" do
      expect(File.read(fn)).to valid_structure_data
    end
  end
end
