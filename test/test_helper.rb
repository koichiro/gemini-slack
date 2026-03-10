require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
  track_files "src/**/*.rb"
end

require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../src/gemini'
