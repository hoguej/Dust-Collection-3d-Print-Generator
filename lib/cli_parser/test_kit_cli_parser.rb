#!/usr/bin/env ruby
# test_kit_cli_parser.rb - CLI parser for test kit scripts

require_relative '../cli_parser'

class TestKitCLIParser < CLIParser
  def initialize(script_name:, description:, examples: [])
    super(script_name: script_name, description: description, examples: examples)
  end
  
  private
  
  def add_diameter_options(parser)
    parser.separator ""
    parser.separator "Diameter options (specify exactly one):"
    parser.on("-i", "--inner DIAMETER", Float, "Inner diameter in mm (creates rings that fit inside)") { |v| @options.inner = v }
    parser.on("-o", "--outer DIAMETER", Float, "Outer diameter in mm (creates rings that fit around)") { |v| @options.outer = v }
  end
end
