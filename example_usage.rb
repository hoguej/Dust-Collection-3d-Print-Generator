#!/usr/bin/env ruby
# example_usage.rb - Example of using the RingGenerator module

require_relative 'lib/ring_generator'

# Example 1: Simple SCAD file generation
puts "Creating a simple ring SCAD file..."
RingGenerator.create_scad_file(
  "output/example_ring.scad",
  inner_diameter: 18.0,
  thickness: 2.0,
  height: 15.0,
  text: "EXAMPLE",
  font_size: 4.0,
  text_depth: 0.8,
  text_on_inner: true
)
puts "✅ Created output/example_ring.scad"

# Example 2: Generate multiple rings programmatically
sizes = [16, 18, 20, 22]
sizes.each do |size|
  filename = "output/ring_set_#{size}mm.scad"
  text = RingGenerator.generate_default_text(size, true)
  
  RingGenerator.create_scad_file(
    filename,
    inner_diameter: size,
    thickness: 2.0,
    height: 20.0,
    text: text,
    text_on_inner: true
  )
  puts "✅ Created #{filename}"
end

# Example 3: Calculate dimensions
puts "\nDimension calculations:"
outer_dia = 25.0
thickness = 2.5
inner_dia = RingGenerator.calculate_inner_diameter(outer_dia, thickness)
puts "Outer diameter: #{outer_dia}mm, Thickness: #{thickness}mm → Inner diameter: #{inner_dia}mm"

# Example 4: Generate filenames
filename = RingGenerator.generate_filename(18.0, 2.0, 15.0, true, extension: ".scad")
puts "Generated filename: #{filename}"

puts "\nDone! Check the output/ directory for generated files."
