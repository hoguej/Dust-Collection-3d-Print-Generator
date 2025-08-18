#!/usr/bin/env ruby
# adapter_pair_cli_parser.rb - CLI parser for adapter pair scripts

require_relative '../cli_parser'

class AdapterPairCLIParser < CLIParser
  def initialize(script_name:, description:, examples: [])
    super(script_name: script_name, description: description, examples: examples)
  end
  
  private
  
  def add_diameter_options(parser)
    parser.separator ""
    parser.separator "Diameter options (specify exactly one):"
    parser.on("-i", "--inner DIAMETER", Float, "Inner diameter in mm (creates adapter that slides inside)") { |v| @options.inner = v }
    parser.on("-o", "--outer DIAMETER", Float, "Outer diameter in mm (creates adapter that slides over)") { |v| @options.outer = v }
  end
  
  def add_output_options(parser)
    parser.separator ""
    parser.separator "Output options:"
    parser.on("--stl", "Generate STL files (also creates SCAD files)") { @options.generate_stl = true }
    parser.on("--timeout SECONDS", Integer, "STL generation timeout in seconds (default #{CLIOptions::DEFAULT_TIMEOUT})") { |v| @options.timeout = v }
    parser.on("-f", "--file NAME", String, "Output base name (directory created automatically)") { |v| @options.output_file = v }
  end
end
