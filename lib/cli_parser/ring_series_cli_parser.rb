#!/usr/bin/env ruby
# ring_series_cli_parser.rb - CLI parser for ring series scripts

require_relative '../cli_parser'

class RingSeriesCLIParser < CLIParser
  def initialize(script_name:, description:, examples: [])
    super(script_name: script_name, description: description, examples: examples)
  end
  
  def validate!
    validate_ring_series!
  end
  
  def validate_ring_series!
    @options.validate_basic_options!
    @options.validate_ring_series_options!
  rescue ArgumentError => e
    warn e.message
    warn @parser
    exit 1
  end
  
  private
  
  def add_output_options(parser)
    parser.separator ""
    parser.separator "Ring series options:"
    parser.on("--step SIZE", Float, "Step size between rings (default 0.1)") { |v| @options.step = v }
    parser.on("--count NUMBER", Integer, "Number of rings to create (default 1)") { |v| @options.count = v }
    parser.on("--up", "Step up in diameter (default)") { @options.direction = :up }
    parser.on("--down", "Step down in diameter") { @options.direction = :down }
    
    parser.separator ""
    parser.separator "Output options:"
    parser.on("--stl", "Generate STL files (also creates SCAD files)") { @options.generate_stl = true }
    parser.on("--timeout SECONDS", Integer, "STL generation timeout in seconds (default #{CLIOptions::DEFAULT_TIMEOUT})") { |v| @options.timeout = v }
    parser.on("-f", "--file NAME", String, "Output directory base name (auto-generated if not provided)") { |v| @options.output_file = v }
  end
end
