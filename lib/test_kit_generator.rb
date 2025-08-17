#!/usr/bin/env ruby
# test_kit_generator.rb - Library for generating test fit kits with multiple clearances

require_relative 'ring_generator'

module TestKitGenerator
  # Standard clearance multipliers for test fit kits
  CLEARANCE_MULTIPLIERS = [0.5, 0.75, 1.0, 1.5].freeze  # Tight, Snug, Optimal, Loose
  CLEARANCE_NAMES = ["tight", "snug", "optimal", "loose"].freeze
  
  # Generate data for individual test rings
  def self.generate_test_ring_data(base_diameter:, is_outer_mode:, thickness:, height:, font_size:, text_depth:)
    rings = []
    base_clearance = RingGenerator.calculate_dust_collection_clearance(base_diameter)
    clearances = CLEARANCE_MULTIPLIERS.map { |mult| base_clearance * mult }
    
    if is_outer_mode
      # Create replica of outer diameter part
      replica_inner = RingGenerator.calculate_inner_diameter(base_diameter, thickness)
      rings << {
        name: "replica_od#{base_diameter}",
        description: "Replica of measured part",
        inner_diameter: replica_inner,
        outer_diameter: base_diameter,
        text: "O#{base_diameter}mm",
        text_on_inner: false
      }
      
      # Create test rings that fit around the base diameter
      clearances.each_with_index do |clearance, i|
        test_inner = base_diameter + clearance
        test_outer = test_inner + (thickness * 2)
        rings << {
          name: "test_fit_#{sprintf('%.1f', clearance)}mm_clearance",
          description: "Test ring - #{CLEARANCE_NAMES[i]} fit",
          inner_diameter: test_inner,
          outer_diameter: test_outer,
          text: "I#{sprintf('%.1f', test_inner)}mm",
          text_on_inner: true
        }
      end
    else
      # Create replica of inner diameter part
      rings << {
        name: "replica_id#{base_diameter}",
        description: "Replica of measured part",
        inner_diameter: base_diameter,
        outer_diameter: base_diameter + (thickness * 2),
        text: "I#{base_diameter}mm",
        text_on_inner: true
      }
      
      # Create test rings that fit inside the base diameter
      clearances.each_with_index do |clearance, i|
        test_outer = base_diameter - clearance
        test_inner = RingGenerator.calculate_inner_diameter(test_outer, thickness)
        rings << {
          name: "test_fit_#{sprintf('%.1f', clearance)}mm_clearance",
          description: "Test ring - #{CLEARANCE_NAMES[i]} fit",
          inner_diameter: test_inner,
          outer_diameter: test_outer,
          text: "O#{sprintf('%.1f', test_outer)}mm",
          text_on_inner: false
        }
      end
    end
    
    rings.each do |ring|
      ring[:scad] = RingGenerator.generate_scad_script(
        inner_diameter: ring[:inner_diameter],
        thickness: thickness,
        height: height,
        text: ring[:text],
        font_size: font_size,
        text_depth: text_depth,
        text_on_inner: ring[:text_on_inner]
      )
    end
    
    rings
  end
  
  # Calculate grid positions for cross layout (5 rings total)
  def self.calculate_grid_positions(spacing)
    [
      [spacing, spacing],        # Replica (center)
      [spacing, 0],              # Test ring 1 - bottom
      [0, spacing],              # Test ring 2 - left  
      [2*spacing, spacing],      # Test ring 3 - right
      [spacing, 2*spacing]       # Test ring 4 - top
    ]
  end
  
  # Calculate optimal spacing for grid layout
  def self.calculate_grid_spacing(rings, clearance_buffer: 10.0)
    max_diameter = rings.map { |ring| ring[:outer_diameter] }.max
    max_diameter + clearance_buffer
  end
  
  # Generate combined SCAD file with all rings in grid layout
  def self.generate_combined_scad(rings:, spacing:, height:, font_size:, text_depth:)
    # Start with the ring generator modules (get everything except the final call)
    base_scad = RingGenerator.generate_scad_script(
      inner_diameter: 10,  # Dummy values
      thickness: 2,
      height: height,
      text: "dummy",
      font_size: font_size,
      text_depth: text_depth,
      text_on_inner: true
    ).split("ring_with_text();").first
    
    positions = calculate_grid_positions(spacing)
    scad_parts = [base_scad]
    
    rings.each_with_index do |ring, index|
      position = positions[index]
      x_offset = position[0]
      y_offset = position[1]
      
      position_names = ["center", "bottom", "left", "right", "top"]
      
      scad_parts << <<~SCAD
        
        // #{ring[:description]} (#{position_names[index]})
        translate([#{x_offset}, #{y_offset}, 0]) {
            difference() {
                cylinder(h=#{height}, r=#{ring[:outer_diameter] / 2}, $fn=128);
                cylinder(h=#{height + 1}, r=#{ring[:inner_diameter] / 2}, $fn=128);
                
                translate([0, 0, #{height / 2}])
                rotate([0, 0, 180])
                curved_text_outer("#{ring[:text]}", #{ring[:outer_diameter] / 2}, #{font_size}, #{text_depth});
            }
        }
      SCAD
    end
    
    scad_parts.join("\n")
  end
  
  # Generate filename for test kit
  def self.generate_test_kit_filename(base_diameter:, is_outer_mode:, thickness:, height:, extension: ".scad")
    if is_outer_mode
      "test_fit_kit_od#{sprintf('%.1f', base_diameter)}_t#{sprintf('%.1f', thickness)}_h#{sprintf('%.1f', height)}#{extension}"
    else
      "test_fit_kit_id#{sprintf('%.1f', base_diameter)}_t#{sprintf('%.1f', thickness)}_h#{sprintf('%.1f', height)}#{extension}"
    end
  end
  
  # Create combined SCAD file for test kit
  def self.create_combined_scad_file(filepath, base_diameter:, is_outer_mode:, thickness:, height:, font_size:, text_depth:)
    rings = generate_test_ring_data(
      base_diameter: base_diameter,
      is_outer_mode: is_outer_mode,
      thickness: thickness,
      height: height,
      font_size: font_size,
      text_depth: text_depth
    )
    
    spacing = calculate_grid_spacing(rings)
    scad_content = generate_combined_scad(
      rings: rings,
      spacing: spacing,
      height: height,
      font_size: font_size,
      text_depth: text_depth
    )
    
    File.write(filepath, scad_content)
    { rings: rings, spacing: spacing }
  end
  
  # Create individual SCAD and STL files for each ring in test kit
  def self.create_individual_files(output_dir, base_diameter:, is_outer_mode:, thickness:, height:, font_size:, text_depth:, generate_stl: false, timeout: 180)
    rings = generate_test_ring_data(
      base_diameter: base_diameter,
      is_outer_mode: is_outer_mode,
      thickness: thickness,
      height: height,
      font_size: font_size,
      text_depth: text_depth
    )
    
    created_files = []
    
    rings.each_with_index do |ring, index|
      ring_name = ring[:name]
      
      # Create SCAD file
      scad_file = File.join(output_dir, "#{ring_name}.scad")
      File.write(scad_file, ring[:scad])
      created_files << { type: :scad, path: scad_file, description: ring[:description] }
      
      if generate_stl
        # Create STL file
        stl_file = File.join(output_dir, "#{ring_name}.stl")
        RingGenerator.convert_scad_to_stl(scad_file, stl_file, timeout: timeout)
        created_files << { type: :stl, path: stl_file, description: ring[:description] }
      end
    end
    
    { rings: rings, files: created_files }
  end
  
  # Get summary information for test kit
  def self.get_test_kit_summary(base_diameter:, is_outer_mode:, thickness:, height:)
    base_clearance = RingGenerator.calculate_dust_collection_clearance(base_diameter)
    clearances = CLEARANCE_MULTIPLIERS.map { |mult| base_clearance * mult }
    
    if is_outer_mode
      test_diameters = clearances.map { |c| base_diameter + c }
      {
        base_type: "outer",
        base_diameter: base_diameter,
        replica_spec: "#{base_diameter}mm outer diameter",
        test_diameters: test_diameters,
        test_type: "inner diameters",
        clearances: clearances,
        thickness: thickness,
        height: height
      }
    else
      test_diameters = clearances.map { |c| base_diameter - c }
      {
        base_type: "inner",
        base_diameter: base_diameter,
        replica_spec: "#{base_diameter}mm inner diameter",
        test_diameters: test_diameters,
        test_type: "outer diameters",
        clearances: clearances,
        thickness: thickness,
        height: height
      }
    end
  end
end
