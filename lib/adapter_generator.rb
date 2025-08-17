#!/usr/bin/env ruby
# adapter_generator.rb - Library for generating tapered dust collection adapters

module AdapterGenerator
  # Standard wall thickness for dust collection (2mm radial = 4mm total diameter difference)
  DEFAULT_WALL_THICKNESS = 4.0
  
  # Standard section lengths in mm
  SECTION_LENGTH_MM = 50.8  # 2 inches
  TRANSITION_LENGTH_MM = 25.4  # 1 inch
  
  # Calculate inner/outer diameter pairs with standard wall thickness
  def self.calculate_diameter_pair(inner: nil, outer: nil, wall_thickness: DEFAULT_WALL_THICKNESS)
    if inner && outer
      raise ArgumentError, "Specify either inner OR outer diameter, not both"
    elsif inner
      calculated_outer = inner + wall_thickness
      { inner: inner, outer: calculated_outer }
    elsif outer
      calculated_inner = outer - wall_thickness
      raise ArgumentError, "Outer diameter too small for wall thickness" if calculated_inner <= 0
      { inner: calculated_inner, outer: calculated_outer }
    else
      raise ArgumentError, "Must specify either inner or outer diameter"
    end
  end
  
  # Generate OpenSCAD script for tapered adapter
  def self.generate_tapered_adapter_scad(side1:, side2:, section_length: SECTION_LENGTH_MM, transition_length: TRANSITION_LENGTH_MM)
    total_length = (section_length * 2) + transition_length
    
    <<~SCAD
      // Tapered dust collection adapter
      // Side 1: #{side1[:inner]}mm inner / #{side1[:outer]}mm outer
      // Side 2: #{side2[:inner]}mm inner / #{side2[:outer]}mm outer
      
      side1_inner = #{side1[:inner]};
      side1_outer = #{side1[:outer]};
      side2_inner = #{side2[:inner]};
      side2_outer = #{side2[:outer]};
      
      side1_length = #{section_length};  // #{section_length/25.4} inches
      transition_length = #{transition_length};  // #{transition_length/25.4} inch
      side2_length = #{section_length};  // #{section_length/25.4} inches
      total_length = #{total_length};  // #{total_length/25.4} inches total
      
      module tapered_adapter() {
          difference() {
              // Outer shape - three distinct sections
              union() {
                  // Side 1: constant diameter for #{section_length/25.4} inches
                  translate([0, 0, 0])
                  cylinder(h=side1_length, r=side1_outer/2, $fn=128);
                  
                  // Transition: tapered section for #{transition_length/25.4} inch
                  translate([0, 0, side1_length])
                  hull() {
                      cylinder(h=0.1, r=side1_outer/2, $fn=128);
                      translate([0, 0, transition_length])
                      cylinder(h=0.1, r=side2_outer/2, $fn=128);
                  }
                  
                  // Side 2: constant diameter for #{section_length/25.4} inches
                  translate([0, 0, side1_length + transition_length])
                  cylinder(h=side2_length, r=side2_outer/2, $fn=128);
              }
              
              // Inner cavity - three distinct sections
              union() {
                  // Side 1 inner: constant diameter, slightly longer to ensure clean cut
                  translate([0, 0, -0.5])
                  cylinder(h=side1_length + 0.5, r=side1_inner/2, $fn=128);
                  
                  // Transition inner: tapered section
                  translate([0, 0, side1_length])
                  hull() {
                      cylinder(h=0.1, r=side1_inner/2, $fn=128);
                      translate([0, 0, transition_length])
                      cylinder(h=0.1, r=side2_inner/2, $fn=128);
                  }
                  
                  // Side 2 inner: constant diameter, slightly longer to ensure clean cut
                  translate([0, 0, side1_length + transition_length])
                  cylinder(h=side2_length + 0.5, r=side2_inner/2, $fn=128);
              }
          }
      }
      
      tapered_adapter();
    SCAD
  end
  
  # Generate filename for tapered adapter
  def self.generate_adapter_filename(side1_spec:, side2_spec:, extension: ".scad")
    "adapter_#{side1_spec}_to_#{side2_spec}#{extension}"
  end
  
  # Create diameter specification string for filename
  def self.create_diameter_spec(inner: nil, outer: nil)
    if inner
      "i#{inner}"
    elsif outer
      "o#{outer}"
    else
      raise ArgumentError, "Must specify either inner or outer diameter"
    end
  end
  
  # Create SCAD file for tapered adapter
  def self.create_adapter_scad_file(filepath, side1:, side2:, section_length: SECTION_LENGTH_MM, transition_length: TRANSITION_LENGTH_MM)
    scad_content = generate_tapered_adapter_scad(
      side1: side1,
      side2: side2,
      section_length: section_length,
      transition_length: transition_length
    )
    
    File.write(filepath, scad_content)
  end
  
  # Create STL file for tapered adapter using OpenSCAD
  def self.create_adapter_stl_file(stl_filepath, side1:, side2:, section_length: SECTION_LENGTH_MM, transition_length: TRANSITION_LENGTH_MM, timeout: 180)
    require 'tempfile'
    require_relative 'ring_generator'
    
    Tempfile.create(['adapter', '.scad']) do |scad_file|
      scad_content = generate_tapered_adapter_scad(
        side1: side1,
        side2: side2,
        section_length: section_length,
        transition_length: transition_length
      )
      
      scad_file.write(scad_content)
      scad_file.flush
      
      # Use RingGenerator's convert method for consistency
      RingGenerator.convert_scad_to_stl(scad_file.path, stl_filepath, timeout: timeout)
    end
  end
  
  # Calculate total length of adapter
  def self.calculate_total_length(section_length: SECTION_LENGTH_MM, transition_length: TRANSITION_LENGTH_MM)
    (section_length * 2) + transition_length
  end
  
  # Convert mm to inches for display
  def self.mm_to_inches(mm)
    mm / 25.4
  end
end
