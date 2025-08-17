#!/usr/bin/env ruby
# cli_options.rb - PORO for standardized CLI option handling

require 'optparse'

# Plain Old Ruby Object for handling CLI options
class CLIOptions
  # Standard defaults
  DEFAULT_THICKNESS = 2.0
  DEFAULT_HEIGHT = 20.0
  DEFAULT_FONT_SIZE = 5.0
  DEFAULT_TEXT_DEPTH = 2.0
  DEFAULT_TIMEOUT = 180
  DEFAULT_OUTPUT_DIR = "output"
  
  attr_accessor :inner, :outer, :thickness, :height, :font_size, :text_depth, 
                :text, :output_file, :generate_stl, :timeout, :help_requested
  
  # Adapter-specific options
  attr_accessor :inner1, :outer1, :inner2, :outer2
  
  def initialize
    @inner = nil
    @outer = nil
    @thickness = DEFAULT_THICKNESS
    @height = DEFAULT_HEIGHT
    @font_size = DEFAULT_FONT_SIZE
    @text_depth = DEFAULT_TEXT_DEPTH
    @text = nil
    @output_file = nil
    @generate_stl = false
    @timeout = DEFAULT_TIMEOUT
    @help_requested = false
    
    # Adapter-specific
    @inner1 = nil
    @outer1 = nil
    @inner2 = nil
    @outer2 = nil
  end
  
  # Validation methods
  def valid_thickness?
    thickness > 0
  end
  
  def has_diameter_input?
    !inner.nil? || !outer.nil?
  end
  
  def has_single_diameter_input?
    [inner, outer].compact.size == 1
  end
  
  def inner_mode?
    !inner.nil?
  end
  
  def outer_mode?
    !outer.nil?
  end
  
  # Adapter-specific validations
  def has_adapter_side1?
    !inner1.nil? || !outer1.nil?
  end
  
  def has_adapter_side2?
    !inner2.nil? || !outer2.nil?
  end
  
  def has_single_adapter_side1?
    [inner1, outer1].compact.size == 1
  end
  
  def has_single_adapter_side2?
    [inner2, outer2].compact.size == 1
  end
  
  def primary_diameter
    inner || outer
  end
  
  # File handling
  def ensure_output_directory!
    Dir.mkdir(DEFAULT_OUTPUT_DIR) unless Dir.exist?(DEFAULT_OUTPUT_DIR)
  end
  
  def resolve_output_path(default_basename = nil, extension = ".scad")
    ensure_output_directory!
    
    basename = output_file || default_basename
    return nil if basename.nil?
    
    # Remove any existing extension from the basename
    basename = File.basename(basename, ".*")
    
    # Determine the directory
    if output_file && output_file.include?("/")
      # User provided a path - use their directory but our basename + extension
      dir = File.dirname(output_file)
      File.join(dir, "#{basename}#{extension}")
    else
      # Use default output directory
      File.join(DEFAULT_OUTPUT_DIR, "#{basename}#{extension}")
    end
  end
  
  # Get base name without extension for directory creation
  def base_name
    return nil if output_file.nil?
    File.basename(output_file, ".*")
  end
  
  # Validation with error messages
  def validate_basic_options!
    unless valid_thickness?
      raise ArgumentError, "Error: thickness must be > 0"
    end
    
    unless has_single_diameter_input?
      raise ArgumentError, "Error: specify exactly one of -i/--inner or -o/--outer"
    end
  end
  
  def validate_adapter_options!
    unless has_single_adapter_side1?
      raise ArgumentError, "Error: specify exactly one of --i1 or --o1 for side 1"
    end
    
    unless has_single_adapter_side2?
      raise ArgumentError, "Error: specify exactly one of --i2 or --o2 for side 2"
    end
  end
  
  # Calculate dimensions
  def calculate_dimensions
    if inner_mode?
      {
        inner_diameter: inner,
        outer_diameter: inner + (thickness * 2),
        mode: :inner
      }
    else
      calculated_inner = outer - (thickness * 2)
      if calculated_inner <= 0
        raise ArgumentError, "Thickness too large: inner diameter <= 0"
      end
      {
        inner_diameter: calculated_inner,
        outer_diameter: outer,
        mode: :outer
      }
    end
  end
  
  # Generate default text with I/O indicators
  def generate_default_text
    return text unless text.nil?
    
    if inner_mode?
      "I#{inner.to_i}mm"
    else
      "O#{outer.to_i}mm"
    end
  end
  
  # Summary for display
  def to_summary
    dims = calculate_dimensions
    {
      inner_diameter: dims[:inner_diameter],
      outer_diameter: dims[:outer_diameter],
      thickness: thickness,
      height: height,
      text: generate_default_text,
      mode: dims[:mode],
      generate_stl: generate_stl,
      timeout: timeout
    }
  end
end
