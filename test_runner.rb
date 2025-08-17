#!/usr/bin/env ruby
# test_runner.rb - Run library tests for the circle_maker project

require 'test/unit'

# Set up the test environment
puts "Circle Maker Library Test Suite"
puts "=" * 50

# Add the project root to the load path
$LOAD_PATH.unshift(File.expand_path('.', __dir__))

# Only require library test files (not CLI tests)
test_files = Dir[File.join(__dir__, 'test', 'test_*.rb')]

if test_files.empty?
  puts "No test files found in test/ directory"
  exit 1
end

puts "Loading library test files:"
test_files.each do |file|
  puts "  - #{File.basename(file)}"
  require file
end

puts "\nRunning library tests..."
puts "-" * 50

# Test::Unit will automatically run all loaded test cases
