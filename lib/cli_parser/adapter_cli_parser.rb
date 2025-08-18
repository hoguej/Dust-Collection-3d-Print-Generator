#!/usr/bin/env ruby
# adapter_cli_parser.rb - CLI parser for tapered adapter scripts

require_relative '../cli_parser'

class AdapterCLIParser < CLIParser
  def initialize(script_name:, description:, examples: [])
    super(script_name: script_name, description: description, examples: examples)
  end
  
  def validate!
    validate_adapter!
  end
  
  private
  
  def should_show_help?(argv)
    argv.empty? && !@options.has_adapter_side1? && !@options.has_adapter_side2? && !@options.help_requested
  end
  
  def add_diameter_options(parser)
    parser.separator ""
    parser.separator "Side 1 diameter (specify exactly one):"
    parser.on("--i1 DIAMETER", Float, "Inner diameter of side 1 in mm") { |v| @options.inner1 = v }
    parser.on("--o1 DIAMETER", Float, "Outer diameter of side 1 in mm") { |v| @options.outer1 = v }
    
    parser.separator ""
    parser.separator "Side 2 diameter (specify exactly one):"
    parser.on("--i2 DIAMETER", Float, "Inner diameter of side 2 in mm") { |v| @options.inner2 = v }
    parser.on("--o2 DIAMETER", Float, "Outer diameter of side 2 in mm") { |v| @options.outer2 = v }
  end
  
  def add_geometry_options(parser)
    # Adapters don't use standard geometry options - they calculate their own
  end
  
  def add_text_options(parser)
    # Adapters don't use text options
  end
end
