#!/usr/bin/env ruby
# create_rings.rb - Create a series of rings with incremental diameter changes
# Perfect for precision testing and finding the perfect fit

require_relative 'lib/cli_parser/ring_series_cli_parser'
require_relative 'lib/ring_generator'

# Create the specialized CLI parser
parser = RingSeriesCLIParser.new(
  script_name: "create_rings.rb",
  description: "Creates a series of rings with incremental diameter changes.\n" \
               "Perfect for precision testing and finding the perfect fit.\n" \
               "Each ring is created in individual files within a subdirectory.",
  examples: [
    "ruby create_rings.rb -o 64 --up --step 0.1 --count 5",
    "ruby create_rings.rb -i 30 --down --step 0.05 --count 3 --stl",
    "ruby create_rings.rb -o 55 --up --count 4 -f precision_test"
  ]
)

# Parse and validate options
options = parser.parse!
parser.validate!

# Calculate base dimensions
base_dims = options.calculate_dimensions

# Generate output directory name if not provided
if options.output_file.nil?
  base_diameter = options.primary_diameter
  direction_str = options.up_direction? ? "up" : "down"
  mode_str = options.inner_mode? ? "id" : "od"
  options.output_file = "ring_series_#{mode_str}#{base_diameter}_#{direction_str}_#{options.count}rings"
end

# Ensure output directory exists and create series subdirectory
series_dir = options.resolve_output_path(options.base_name || options.output_file, "")
Dir.mkdir(series_dir) unless Dir.exist?(series_dir)

puts "Creating ring series with incremental diameters:"
puts "  Base diameter: #{options.primary_diameter}mm (#{options.inner_mode? ? 'inner' : 'outer'})"
puts "  Step size: #{options.step}mm #{options.up_direction? ? 'up' : 'down'}"
puts "  Count: #{options.count} rings"
puts "  Thickness: #{options.thickness}mm"
puts "  Height: #{options.height}mm"
puts "  Output directory: #{series_dir}/"
puts ""

created_files = []
ring_data = []

# Generate each ring in the series
(0...options.count).each do |i|
  # Calculate diameter for this ring
  if options.up_direction?
    current_diameter = options.primary_diameter + (i * options.step)
  else
    current_diameter = options.primary_diameter - (i * options.step)
  end
  
  # Calculate dimensions for this ring
  if options.inner_mode?
    ring_inner = current_diameter
    ring_outer = ring_inner + (options.thickness * 2)
    ring_mode = :inner
    diameter_text = "I#{sprintf('%.1f', ring_inner)}mm"
  else
    ring_outer = current_diameter
    ring_inner = ring_outer - (options.thickness * 2)
    if ring_inner <= 0
      warn "Warning: Ring #{i + 1} would have inner diameter <= 0 (#{ring_inner}mm). Skipping."
      next
    end
    ring_mode = :outer
    diameter_text = "O#{sprintf('%.1f', ring_outer)}mm"
  end
  
  # Store ring data
  ring_info = {
    index: i + 1,
    inner_diameter: ring_inner,
    outer_diameter: ring_outer,
    diameter: current_diameter,
    text: diameter_text,
    mode: ring_mode
  }
  ring_data << ring_info
  
  # Generate filename for this ring
  ring_filename = if options.inner_mode?
    "ring_id#{sprintf('%.2f', current_diameter)}"
  else
    "ring_od#{sprintf('%.2f', current_diameter)}"
  end
  
  # Create SCAD file
  scad_file = File.join(series_dir, "#{ring_filename}.scad")
  RingGenerator.create_scad_file(
    scad_file,
    inner_diameter: ring_inner,
    thickness: options.thickness,
    height: options.height,
    text: diameter_text,
    font_size: options.font_size,
    text_depth: options.text_depth,
    text_on_inner: options.inner_mode?
  )
  
  created_files << { type: :scad, path: scad_file, ring: ring_info }
  puts "✅ Created #{scad_file}"
  
  # Create STL file if requested
  if options.generate_stl
    stl_file = File.join(series_dir, "#{ring_filename}.stl")
    puts "Generating STL #{i + 1}/#{options.count}: #{ring_filename} (timeout: #{options.timeout}s)..."
    
    begin
      RingGenerator.convert_scad_to_stl(scad_file, stl_file, timeout: options.timeout)
      created_files << { type: :stl, path: stl_file, ring: ring_info }
      puts "✅ Created #{stl_file}"
    rescue => e
      warn "⚠️  Failed to create STL for ring #{i + 1}: #{e.message}"
    end
  end
end

# Summary
puts "\n📊 Ring Series Summary:"
puts "   Total rings created: #{ring_data.length}"
puts "   Diameter range: #{sprintf('%.1f', ring_data.first[:diameter])}mm to #{sprintf('%.1f', ring_data.last[:diameter])}mm"
puts "   Step size: #{options.step}mm #{options.up_direction? ? 'increasing' : 'decreasing'}"
puts "   Ring dimensions:"

ring_data.each do |ring|
  puts "     Ring #{ring[:index]}: #{sprintf('%.1f', ring[:diameter])}mm #{ring[:mode]} → " \
       "Inner: #{sprintf('%.1f', ring[:inner_diameter])}mm, Outer: #{sprintf('%.1f', ring[:outer_diameter])}mm"
end

puts "\n   Files created in: #{series_dir}/"
scad_count = created_files.count { |f| f[:type] == :scad }
stl_count = created_files.count { |f| f[:type] == :stl }

if options.generate_stl
  puts "   #{scad_count} SCAD files + #{stl_count} STL files = #{created_files.length} total files"
  puts "   Individual files ready for independent manipulation in slicer"
else
  puts "   #{scad_count} SCAD files created"
  puts "   Use --stl flag to also generate STL files"
end

puts "\n🎯 Perfect for finding the exact fit you need!"
