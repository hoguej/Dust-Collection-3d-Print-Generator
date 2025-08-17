#!/usr/bin/env ruby
# test_ring_generator.rb - Test suite for RingGenerator module

require 'test/unit'
require 'tempfile'
require 'fileutils'
require_relative '../lib/ring_generator'

class TestRingGenerator < Test::Unit::TestCase
  
  def setup
    @test_output_dir = 'test/output'
    FileUtils.mkdir_p(@test_output_dir)
  end
  
  def teardown
    # Clean up test files
    FileUtils.rm_rf(@test_output_dir) if Dir.exist?(@test_output_dir)
  end

  # Test dust collection clearance calculation
  def test_calculate_dust_collection_clearance
    # Test known empirical data points
    # 45.8mm should give approximately 0.6mm clearance
    clearance_45 = RingGenerator.calculate_dust_collection_clearance(45.8)
    assert_in_delta(0.6, clearance_45, 0.1, "45.8mm diameter should give ~0.6mm clearance")
    
    # 101mm should give approximately 0.1mm clearance
    clearance_101 = RingGenerator.calculate_dust_collection_clearance(101.0)
    assert_in_delta(0.1, clearance_101, 0.05, "101mm diameter should give ~0.1mm clearance")
    
    # Test that larger diameters give smaller clearances
    clearance_50 = RingGenerator.calculate_dust_collection_clearance(50.0)
    clearance_100 = RingGenerator.calculate_dust_collection_clearance(100.0)
    assert(clearance_50 > clearance_100, "Larger diameters should have smaller clearances")
    
    # Test rounding to 0.05mm increments
    clearance = RingGenerator.calculate_dust_collection_clearance(75.0)
    assert_equal(clearance, (clearance * 20).round / 20.0, "Should round to 0.05mm increments")
  end

  # Test inner diameter calculation
  def test_calculate_inner_diameter
    # Basic calculation
    inner = RingGenerator.calculate_inner_diameter(30.0, 2.0)
    assert_equal(26.0, inner, "30mm outer - 4mm total thickness = 26mm inner")
    
    inner = RingGenerator.calculate_inner_diameter(100.0, 5.0)
    assert_equal(90.0, inner, "100mm outer - 10mm total thickness = 90mm inner")
    
    # Edge case: thickness too large
    assert_raises(RuntimeError) do
      RingGenerator.calculate_inner_diameter(10.0, 5.0) # Would result in 0mm inner
    end
    
    assert_raises(RuntimeError) do
      RingGenerator.calculate_inner_diameter(10.0, 6.0) # Would result in negative inner
    end
  end

  # Test default text generation
  def test_generate_default_text
    assert_equal("30mm", RingGenerator.generate_default_text(30.5))
    assert_equal("100mm", RingGenerator.generate_default_text(100.2))
    assert_equal("45mm", RingGenerator.generate_default_text(45.0))
  end

  # Test filename generation
  def test_generate_filename
    # Inner diameter mode
    filename = RingGenerator.generate_filename(25.0, 2.0, 20.0, true)
    assert_equal("ring_id25.0_t2.0_h20.0.scad", filename)
    
    # Outer diameter mode
    filename = RingGenerator.generate_filename(25.0, 2.0, 20.0, false, outer_diameter: 29.0)
    assert_equal("ring_od29.0_t2.0_h20.0.scad", filename)
    
    # Different extension
    filename = RingGenerator.generate_filename(25.0, 2.0, 20.0, true, extension: ".stl")
    assert_equal("ring_id25.0_t2.0_h20.0.stl", filename)
    
    # Decimal handling
    filename = RingGenerator.generate_filename(25.5, 2.3, 20.7, true)
    assert_equal("ring_id25.5_t2.3_h20.7.scad", filename)
  end

  # Test OpenSCAD script generation
  def test_generate_scad_script
    script = RingGenerator.generate_scad_script(
      inner_diameter: 20.0,
      thickness: 2.0,
      height: 10.0,
      text: "20mm",
      font_size: 5.0,
      text_depth: 1.0
    )
    
    # Check that script contains expected elements
    assert_match(/inner_diameter = 20\.0/, script)
    assert_match(/thickness = 2\.0/, script)
    assert_match(/height = 10\.0/, script)
    assert_match(/text_content = "20mm"/, script)
    assert_match(/font_size = 5\.0/, script)
    assert_match(/text_depth = 1\.0/, script)
    
    # Check for required modules and functions
    assert_match(/module ring_with_text/, script)
    assert_match(/module curved_text_inner/, script)
    assert_match(/module curved_text_outer/, script)
    assert_match(/ring_with_text\(\);/, script)
    
    # Check for proper calculations
    assert_match(/outer_diameter = inner_diameter \+ \(thickness \* 2\)/, script)
    
    # Check for OpenSCAD syntax elements
    assert_match(/cylinder/, script)
    assert_match(/difference/, script)
    assert_match(/translate/, script)
    assert_match(/rotate/, script)
  end

  # Test SCAD file creation
  def test_create_scad_file
    filepath = File.join(@test_output_dir, 'test_ring.scad')
    
    RingGenerator.create_scad_file(
      filepath,
      inner_diameter: 25.0,
      thickness: 2.5,
      height: 15.0,
      text: "test",
      font_size: 4.0,
      text_depth: 1.5
    )
    
    assert(File.exist?(filepath), "SCAD file should be created")
    
    content = File.read(filepath)
    assert_match(/inner_diameter = 25\.0/, content)
    assert_match(/thickness = 2\.5/, content)
    assert_match(/height = 15\.0/, content)
    assert_match(/text_content = "test"/, content)
  end

  # Test parameter validation and edge cases
  def test_parameter_validation
    # Test very small dimensions
    script = RingGenerator.generate_scad_script(
      inner_diameter: 1.0,
      thickness: 0.5,
      height: 1.0,
      text: "1mm"
    )
    assert_match(/inner_diameter = 1\.0/, script)
    
    # Test large dimensions
    script = RingGenerator.generate_scad_script(
      inner_diameter: 200.0,
      thickness: 10.0,
      height: 50.0,
      text: "200mm"
    )
    assert_match(/inner_diameter = 200\.0/, script)
    
    # Test special characters in text (should be handled gracefully)
    script = RingGenerator.generate_scad_script(
      inner_diameter: 30.0,
      thickness: 2.0,
      height: 20.0,
      text: "30.5mm ID"
    )
    assert_match(/text_content = "30\.5mm ID"/, script)
  end

  # Test mathematical relationships
  def test_mathematical_relationships
    inner_d = 30.0
    thickness = 3.0
    
    # Test that outer diameter calculation is correct
    outer_d = inner_d + (thickness * 2)
    assert_equal(36.0, outer_d)
    
    # Test that inner diameter calculation reverses correctly
    calculated_inner = RingGenerator.calculate_inner_diameter(outer_d, thickness)
    assert_equal(inner_d, calculated_inner)
  end

  # Test clearance calculation properties
  def test_clearance_calculation_properties
    # Test monotonic decreasing property (larger diameter = smaller clearance)
    diameters = [30, 50, 70, 90, 110]
    clearances = diameters.map { |d| RingGenerator.calculate_dust_collection_clearance(d) }
    
    # Each clearance should be smaller than the previous
    (0...clearances.length-1).each do |i|
      assert(clearances[i] > clearances[i+1], 
        "Clearance should decrease as diameter increases: #{clearances[i]} > #{clearances[i+1]} for diameters #{diameters[i]} vs #{diameters[i+1]}")
    end
    
    # Test that all clearances are positive
    clearances.each_with_index do |clearance, i|
      assert(clearance > 0, "Clearance should be positive for diameter #{diameters[i]}: got #{clearance}")
    end
    
    # Test reasonable bounds (clearances should be between 0.05 and 5.0 mm for typical diameters)
    typical_diameters = [20, 30, 50, 75, 100, 150]
    typical_diameters.each do |diameter|
      clearance = RingGenerator.calculate_dust_collection_clearance(diameter)
      assert(clearance >= 0.05 && clearance <= 5.0, 
        "Clearance should be reasonable for diameter #{diameter}mm: got #{clearance}mm")
    end
  end
end
