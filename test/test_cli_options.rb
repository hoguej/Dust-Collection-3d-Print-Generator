#!/usr/bin/env ruby
# test_cli_options.rb - Test suite for CLIOptions PORO

require 'test/unit'
require_relative '../lib/cli_options'

class TestCLIOptions < Test::Unit::TestCase
  
  def setup
    @options = CLIOptions.new
  end
  
  # Test initialization with defaults
  def test_initialization_defaults
    assert_nil(@options.inner)
    assert_nil(@options.outer)
    assert_equal(CLIOptions::DEFAULT_THICKNESS, @options.thickness)
    assert_equal(CLIOptions::DEFAULT_HEIGHT, @options.height)
    assert_equal(CLIOptions::DEFAULT_FONT_SIZE, @options.font_size)
    assert_equal(CLIOptions::DEFAULT_TEXT_DEPTH, @options.text_depth)
    assert_equal(CLIOptions::DEFAULT_TIMEOUT, @options.timeout)
    assert_equal(false, @options.generate_stl)
    assert_equal(false, @options.help_requested)
  end
  
  # Test thickness validation
  def test_valid_thickness
    @options.thickness = 2.0
    assert(@options.valid_thickness?, "Valid thickness should return true")
    
    @options.thickness = 0.1
    assert(@options.valid_thickness?, "Small positive thickness should be valid")
    
    @options.thickness = 0
    assert_equal(false, @options.valid_thickness?, "Zero thickness should be invalid")
    
    @options.thickness = -1.0
    assert_equal(false, @options.valid_thickness?, "Negative thickness should be invalid")
  end
  
  # Test diameter input validation
  def test_has_diameter_input
    assert_equal(false, @options.has_diameter_input?, "No diameter should return false")
    
    @options.inner = 30.0
    assert(@options.has_diameter_input?, "Inner diameter should return true")
    
    @options.inner = nil
    @options.outer = 35.0
    assert(@options.has_diameter_input?, "Outer diameter should return true")
    
    @options.inner = 30.0
    @options.outer = 35.0
    assert(@options.has_diameter_input?, "Both diameters should return true")
  end
  
  # Test single diameter validation
  def test_has_single_diameter_input
    assert_equal(false, @options.has_single_diameter_input?, "No diameter should return false")
    
    @options.inner = 30.0
    assert(@options.has_single_diameter_input?, "Only inner should return true")
    
    @options.outer = 35.0
    assert_equal(false, @options.has_single_diameter_input?, "Both diameters should return false")
    
    @options.inner = nil
    assert(@options.has_single_diameter_input?, "Only outer should return true")
  end
  
  # Test mode detection
  def test_mode_detection
    assert_equal(false, @options.inner_mode?, "No diameter should not be inner mode")
    assert_equal(false, @options.outer_mode?, "No diameter should not be outer mode")
    
    @options.inner = 30.0
    assert(@options.inner_mode?, "Inner diameter should be inner mode")
    assert_equal(false, @options.outer_mode?, "Inner diameter should not be outer mode")
    
    @options.inner = nil
    @options.outer = 35.0
    assert_equal(false, @options.inner_mode?, "Outer diameter should not be inner mode")
    assert(@options.outer_mode?, "Outer diameter should be outer mode")
  end
  
  # Test primary diameter
  def test_primary_diameter
    assert_nil(@options.primary_diameter, "No diameter should return nil")
    
    @options.inner = 30.0
    assert_equal(30.0, @options.primary_diameter, "Inner diameter should be returned")
    
    @options.inner = nil
    @options.outer = 35.0
    assert_equal(35.0, @options.primary_diameter, "Outer diameter should be returned")
    
    @options.inner = 30.0
    assert_equal(30.0, @options.primary_diameter, "Inner should take precedence when both set")
  end
  
  # Test adapter validations
  def test_adapter_validations
    assert_equal(false, @options.has_adapter_side1?, "No side1 should return false")
    assert_equal(false, @options.has_adapter_side2?, "No side2 should return false")
    
    @options.inner1 = 30.0
    assert(@options.has_adapter_side1?, "Inner1 should return true")
    assert(@options.has_single_adapter_side1?, "Only inner1 should be single")
    
    @options.outer1 = 35.0
    assert_equal(false, @options.has_single_adapter_side1?, "Both side1 values should not be single")
    
    @options.inner2 = 40.0
    assert(@options.has_adapter_side2?, "Inner2 should return true")
    assert(@options.has_single_adapter_side2?, "Only inner2 should be single")
  end
  
  # Test basic options validation
  def test_validate_basic_options
    @options.inner = 30.0
    @options.thickness = 2.0
    
    assert_nothing_raised("Valid options should not raise") do
      @options.validate_basic_options!
    end
    
    @options.thickness = 0
    assert_raises(ArgumentError, "Zero thickness should raise") do
      @options.validate_basic_options!
    end
    
    @options.thickness = 2.0
    @options.outer = 35.0
    assert_raises(ArgumentError, "Both diameters should raise") do
      @options.validate_basic_options!
    end
    
    @options.inner = nil
    @options.outer = nil
    assert_raises(ArgumentError, "No diameters should raise") do
      @options.validate_basic_options!
    end
  end
  
  # Test adapter options validation
  def test_validate_adapter_options
    @options.inner1 = 30.0
    @options.inner2 = 40.0
    
    assert_nothing_raised("Valid adapter options should not raise") do
      @options.validate_adapter_options!
    end
    
    @options.outer1 = 35.0
    assert_raises(ArgumentError, "Both side1 values should raise") do
      @options.validate_adapter_options!
    end
    
    @options.outer1 = nil
    @options.inner2 = nil
    assert_raises(ArgumentError, "No side2 values should raise") do
      @options.validate_adapter_options!
    end
  end
  
  # Test dimension calculations
  def test_calculate_dimensions
    # Inner mode
    @options.inner = 30.0
    @options.thickness = 2.0
    
    dims = @options.calculate_dimensions
    assert_equal(30.0, dims[:inner_diameter])
    assert_equal(34.0, dims[:outer_diameter])
    assert_equal(:inner, dims[:mode])
    
    # Outer mode
    @options.inner = nil
    @options.outer = 35.0
    
    dims = @options.calculate_dimensions
    assert_equal(31.0, dims[:inner_diameter])
    assert_equal(35.0, dims[:outer_diameter])
    assert_equal(:outer, dims[:mode])
    
    # Edge case: thickness too large
    @options.outer = 3.0
    @options.thickness = 2.0  # Would result in -1 inner diameter
    
    assert_raises(ArgumentError, "Thickness too large should raise") do
      @options.calculate_dimensions
    end
  end
  
  # Test default text generation
  def test_generate_default_text
    # Custom text
    @options.text = "Custom"
    assert_equal("Custom", @options.generate_default_text)
    
    # Inner mode default
    @options.text = nil
    @options.inner = 30.5
    assert_equal("I30mm", @options.generate_default_text)
    
    # Outer mode default
    @options.inner = nil
    @options.outer = 35.7
    assert_equal("O35mm", @options.generate_default_text)
  end
  
  # Test output path resolution
  def test_resolve_output_path
    # Test output directory creation (mock)
    # We'll test the path resolution logic
    
    # No output file, no default
    assert_nil(@options.resolve_output_path)
    
    # No output file, with default basename
    path = @options.resolve_output_path("test")
    assert_equal("output/test.scad", path)
    
    # No output file, with default basename and custom extension
    path = @options.resolve_output_path("test", ".stl")
    assert_equal("output/test.stl", path)
    
    # Relative output file (base name only)
    @options.output_file = "custom"
    path = @options.resolve_output_path
    assert_equal("output/custom.scad", path)
    
    # Relative output file with extension (should strip extension)
    @options.output_file = "custom.old"
    path = @options.resolve_output_path(nil, ".scad")
    assert_equal("output/custom.scad", path)
    
    # Output file with path
    @options.output_file = "subdir/custom"
    path = @options.resolve_output_path(nil, ".stl")
    assert_equal("subdir/custom.stl", path)
    
    # Output file with path and extension (should strip extension)
    @options.output_file = "subdir/custom.old"
    path = @options.resolve_output_path(nil, ".scad")
    assert_equal("subdir/custom.scad", path)
  end
  
  # Test base name extraction
  def test_base_name
    assert_nil(@options.base_name, "No output file should return nil")
    
    @options.output_file = "test"
    assert_equal("test", @options.base_name)
    
    @options.output_file = "test.scad"
    assert_equal("test", @options.base_name)
    
    @options.output_file = "path/test.old.scad"
    assert_equal("test.old", @options.base_name)
  end
  
  # Test summary generation
  def test_to_summary
    @options.inner = 25.0
    @options.thickness = 2.5
    @options.height = 15.0
    @options.generate_stl = true
    @options.timeout = 300
    
    summary = @options.to_summary
    
    assert_equal(25.0, summary[:inner_diameter])
    assert_equal(30.0, summary[:outer_diameter])
    assert_equal(2.5, summary[:thickness])
    assert_equal(15.0, summary[:height])
    assert_equal("I25mm", summary[:text])
    assert_equal(:inner, summary[:mode])
    assert_equal(true, summary[:generate_stl])
    assert_equal(300, summary[:timeout])
  end
end
