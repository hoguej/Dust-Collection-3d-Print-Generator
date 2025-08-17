#!/usr/bin/env ruby
# cli_parser.rb - Standardized CLI parsing for dust collection scripts

require 'optparse'
require_relative 'cli_options'

class CLIParser
  attr_reader :options, :parser
  
  def initialize(script_name:, description:, examples: [])
    @script_name = script_name
    @description = description
    @examples = examples
    @options = CLIOptions.new
    @parser = create_parser
  end
  
  # Parse command line arguments
  def parse!(argv = ARGV)
    begin
      @parser.parse!(argv)
      
      # Check for help request or no arguments
      if should_show_help?(argv)
        puts @parser
        exit 0
      end
      
    rescue OptionParser::ParseError => e
      warn e.message
      warn @parser
      exit 1
    end
    
    @options
  end
  
  # Validate options and show errors
  def validate!
    @options.validate_basic_options!
  rescue ArgumentError => e
    warn e.message
    warn @parser
    exit 1
  end
  
  # Validate adapter-specific options
  def validate_adapter!
    @options.validate_adapter_options!
  rescue ArgumentError => e
    warn e.message
    warn @parser
    exit 1
  end
  
  private
  
  def should_show_help?(argv)
    argv.empty? && !@options.has_diameter_input? && !@options.help_requested
  end
  
  def create_parser
    OptionParser.new do |o|
      o.banner = create_banner
      
      # Standard diameter options
      add_diameter_options(o)
      
      # Standard geometry options  
      add_geometry_options(o)
      
      # Standard text options
      add_text_options(o)
      
      # Standard output options
      add_output_options(o)
      
      # Help option
      o.on("-h", "--help", "Show help") do
        @options.help_requested = true
        puts o
        exit
      end
    end
  end
  
  def create_banner
    banner = "Usage: ruby #{@script_name} [options]\n"
    banner += "#{@description}\n" unless @description.empty?
    
    unless @examples.empty?
      banner += "\nExamples:\n"
      @examples.each { |example| banner += "  #{example}\n" }
    end
    
    banner
  end
  
  def add_diameter_options(parser)
    parser.separator ""
    parser.separator "Diameter options (specify exactly one):"
    parser.on("-i", "--inner DIAMETER", Float, "Inner diameter in mm") { |v| @options.inner = v }
    parser.on("-o", "--outer DIAMETER", Float, "Outer diameter in mm") { |v| @options.outer = v }
  end
  
  def add_geometry_options(parser)
    parser.separator ""
    parser.separator "Geometry options:"
    parser.on("--t THICKNESS", Float, "Wall thickness in mm (default #{CLIOptions::DEFAULT_THICKNESS})") { |v| @options.thickness = v }
    parser.on("--h HEIGHT", Float, "Height in mm (default #{CLIOptions::DEFAULT_HEIGHT})") { |v| @options.height = v }
  end
  
  def add_text_options(parser)
    parser.separator ""
    parser.separator "Text options:"
    parser.on("--text TEXT", String, "Custom text to emboss (optional)") { |v| @options.text = v }
    parser.on("--font-size SIZE", Float, "Font size (default #{CLIOptions::DEFAULT_FONT_SIZE})") { |v| @options.font_size = v }
    parser.on("--text-depth DEPTH", Float, "Text depth in mm (default #{CLIOptions::DEFAULT_TEXT_DEPTH})") { |v| @options.text_depth = v }
  end
  
  def add_output_options(parser)
    parser.separator ""
    parser.separator "Output options:"
    parser.on("--stl", "Generate STL file (also creates SCAD file)") { @options.generate_stl = true }
    parser.on("--timeout SECONDS", Integer, "STL generation timeout in seconds (default #{CLIOptions::DEFAULT_TIMEOUT})") { |v| @options.timeout = v }
    parser.on("-f", "--file NAME", String, "Output base name (extension added automatically)") { |v| @options.output_file = v }
  end
end

# Specialized parser for adapter scripts
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

# Specialized parser for test kit scripts  
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

# Specialized parser for adapter pair scripts
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
