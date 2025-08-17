#!/usr/bin/env ruby
# ring_generator.rb - Reusable ring generation logic
# Separated from CLI for use in other scripts

module RingGenerator
  # Calculate optimal clearance for dust collection adapters based on diameter
  # Derived from empirical data: 45.8mm→0.6mm clearance, 101mm→0.1mm clearance
  # Formula: clearance = 3476.1064 * diameter^-2.266
  def self.calculate_dust_collection_clearance(diameter_mm)
    clearance = 3476.1064 * (diameter_mm ** -2.266)
    # Round to reasonable precision (0.05mm increments)
    (clearance * 20).round / 20.0
  end
  # Generate OpenSCAD script content with curved text
  # Always places text on outer surface for better STL readability
  def self.generate_scad_script(inner_diameter:, thickness:, height:, text:, font_size: 5.0, text_depth: 1.0, text_on_inner: true)
    <<~SCAD
      // Generated ring with curved text
      inner_diameter = #{inner_diameter};
      thickness = #{thickness};
      height = #{height};
      text_content = "#{text}";
      font_size = #{font_size};
      text_depth = #{text_depth};
      text_on_inner = #{text_on_inner};
      
      // Calculated values
      outer_diameter = inner_diameter + (thickness * 2);
      inner_radius = inner_diameter / 2;
      outer_radius = outer_diameter / 2;
      
      module ring_with_text() {
          difference() {
              // Main ring
              cylinder(h=height, r=outer_radius, $fn=128);
              
              // Inner hole
              cylinder(h=height+1, r=inner_radius, $fn=128);
              
              // Text cutout - always on outer surface for better STL readability
              translate([0, 0, height/2])
              rotate([0, 0, 180]) // Position text at bottom of ring
              curved_text_outer(text_content, outer_radius, font_size, text_depth);
          }
      }
      
      module curved_text_inner(text, radius, size, depth) {
          // Calculate spacing for each character
          text_length = len(text);
          // More generous character spacing
          char_width = size * 1.2; // Good spacing for readability
          total_arc_length = text_length * char_width;
          
          // Convert to angle (radians)
          total_angle = total_arc_length / radius;
          angle_per_char = total_angle / text_length;
          
          // Center the text
          start_angle = -total_angle / 2;
          
          for (i = [0 : text_length - 1]) {
              char = text[i];
              angle = start_angle - i * angle_per_char; // Subtract to reverse order for inner
              
              // Skip spaces - don't render them but keep the spacing
              if (char != " ") {
                  rotate([0, 0, angle * 180 / PI])
                  translate([0, -radius + depth/2, 0])
                  rotate([90, 0, 0])
                  mirror([1, 0, 0]) // Mirror text so it reads correctly from inside
                  linear_extrude(height=depth, center=true)
                  text(char, size=size, halign="center", valign="center");
              }
          }
      }
      
      module curved_text_outer(text, radius, size, depth) {
          // Calculate spacing for each character
          text_length = len(text);
          // More generous character spacing
          char_width = size * 1.2; // Good spacing for readability
          total_arc_length = text_length * char_width;
          
          // Convert to angle (radians)
          total_angle = total_arc_length / radius;
          angle_per_char = total_angle / text_length;
          
          // Center the text
          start_angle = -total_angle / 2;
          
          for (i = [0 : text_length - 1]) {
              char = text[i];
              angle = start_angle + i * angle_per_char; // Add for normal order on outer
              
              // Skip spaces - don't render them but keep the spacing
              if (char != " ") {
                  rotate([0, 0, angle * 180 / PI])
                  translate([0, radius - depth/2, 0]) // Position on outer surface
                  rotate([90, 0, 180]) // Rotate for outer surface text orientation
                  // No mirror needed for outer text - it was causing horizontal mirroring
                  linear_extrude(height=depth, center=true)
                  text(char, size=size, halign="center", valign="center");
              }
          }
      }
      
      // Generate the ring
      ring_with_text();
    SCAD
  end

  # Calculate inner diameter from outer diameter and thickness
  def self.calculate_inner_diameter(outer_diameter, thickness)
    inner_diameter = outer_diameter - (thickness * 2)
    raise "Thickness too large: inner diameter <= 0" unless inner_diameter > 0
    inner_diameter
  end

  # Generate default text based on diameter and mode
  def self.generate_default_text(diameter)
    "#{diameter.to_i}mm"
  end

  # Generate filename based on parameters
  def self.generate_filename(inner_diameter, thickness, height, is_inner_mode, outer_diameter: nil, extension: ".scad")
    if is_inner_mode
      "ring_id#{format('%.1f', inner_diameter)}_t#{format('%.1f', thickness)}_h#{format('%.1f', height)}#{extension}"
    else
      "ring_od#{format('%.1f', outer_diameter)}_t#{format('%.1f', thickness)}_h#{format('%.1f', height)}#{extension}"
    end
  end

  # Create SCAD file
  def self.create_scad_file(filepath, inner_diameter:, thickness:, height:, text:, font_size: 5.0, text_depth: 1.0, text_on_inner: true)
    scad_content = generate_scad_script(
      inner_diameter: inner_diameter,
      thickness: thickness,
      height: height,
      text: text,
      font_size: font_size,
      text_depth: text_depth,
      text_on_inner: text_on_inner
    )
    
    File.write(filepath, scad_content)
  end

  # Create STL file using OpenSCAD
  def self.create_stl_file(stl_filepath, inner_diameter:, thickness:, height:, text:, font_size: 5.0, text_depth: 1.0, text_on_inner: true)
    require 'tempfile'
    
    Tempfile.create(['ring', '.scad']) do |scad_file|
      scad_content = generate_scad_script(
        inner_diameter: inner_diameter,
        thickness: thickness,
        height: height,
        text: text,
        font_size: font_size,
        text_depth: text_depth,
        text_on_inner: text_on_inner
      )
      
      scad_file.write(scad_content)
      scad_file.flush
      
      success = system("openscad", "-o", stl_filepath, scad_file.path)
      raise "OpenSCAD failed to generate STL" unless success
    end
  end

  # Convert existing SCAD file to STL with timeout
  def self.convert_scad_to_stl(scad_filepath, stl_filepath = nil, timeout: 120)
    require 'timeout'
    
    # Generate STL filename if not provided
    if stl_filepath.nil?
      stl_filepath = scad_filepath.gsub(/\.scad$/i, '.stl')
    end
    
    begin
      Timeout::timeout(timeout) do
        success = system("openscad", "-o", stl_filepath, scad_filepath)
        raise "OpenSCAD failed to convert SCAD to STL" unless success
      end
    rescue Timeout::Error
      raise "OpenSCAD conversion timed out after #{timeout} seconds. Try reducing complexity or increasing timeout."
    end
    
    stl_filepath
  end
end
