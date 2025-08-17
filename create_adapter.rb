#!/usr/bin/env ruby
# create_adapter.rb - Create tapered dust collection adapters connecting two different diameters

require 'optparse'
require_relative 'lib/ring_generator'

# CLI Options
options = {
  inner1: nil,
  outer1: nil,
  inner2: nil,
  outer2: nil,
  out: nil,
  generate_stl: false,
  timeout: 180
}

parser = OptionParser.new do |o|
  o.banner = "Usage: ruby create_adapter.rb [options]\n" \
             "Creates a tapered adapter connecting two different diameters.\n" \
             "Structure: 2\" of side1 + 1\" transition + 2\" of side2 (total 5\" long)\n" \
             "Specify one diameter measurement for each side."
  
  o.on("--i1 DIAMETER", Float, "Inner diameter of side 1 in mm") { |v| options[:inner1] = v }
  o.on("--o1 DIAMETER", Float, "Outer diameter of side 1 in mm") { |v| options[:outer1] = v }
  o.on("--i2 DIAMETER", Float, "Inner diameter of side 2 in mm") { |v| options[:inner2] = v }
  o.on("--o2 DIAMETER", Float, "Outer diameter of side 2 in mm") { |v| options[:outer2] = v }
  o.on("--stl", "Generate STL file (also creates SCAD file)") { |v| options[:generate_stl] = true }
  o.on("--timeout SECONDS", Integer, "STL generation timeout in seconds (default 180)") { |v| options[:timeout] = v }
  o.on("-f", "--file FILE", String, "Output file name (without extension)") { |v| options[:out] = v }
  o.on("-h", "--help", "Show help") { puts o; exit }
end

begin
  parser.parse!
rescue OptionParser::ParseError => e
  warn e.message
  warn parser
  exit 1
end

# Show help if no arguments provided
if ARGV.empty? && options[:inner1].nil? && options[:outer1].nil? && options[:inner2].nil? && options[:outer2].nil?
  puts parser
  exit 0
end

# Validation - exactly one measurement per side
side1_count = [options[:inner1], options[:outer1]].compact.size
side2_count = [options[:inner2], options[:outer2]].compact.size

if side1_count != 1
  warn "Error: specify exactly one of --i1 or --o1 for side 1"
  puts parser
  exit 1
end

if side2_count != 1
  warn "Error: specify exactly one of --i2 or --o2 for side 2"
  puts parser
  exit 1
end

# Calculate diameters for both sides
if options[:inner1]
  side1_inner = options[:inner1]
  # For dust collection, assume standard wall thickness of 2mm
  side1_outer = side1_inner + 4.0
else
  side1_outer = options[:outer1]
  side1_inner = side1_outer - 4.0
  if side1_inner <= 0
    warn "Error: outer diameter too small for side 1"
    exit 1
  end
end

if options[:inner2]
  side2_inner = options[:inner2]
  side2_outer = side2_inner + 4.0
else
  side2_outer = options[:outer2]
  side2_inner = side2_outer - 4.0
  if side2_inner <= 0
    warn "Error: outer diameter too small for side 2"
    exit 1
  end
end

# Ensure output directory exists
output_dir = "output"
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

# Generate output filename
if options[:out].nil?
  side1_spec = options[:inner1] ? "i#{options[:inner1]}" : "o#{options[:outer1]}"
  side2_spec = options[:inner2] ? "i#{options[:inner2]}" : "o#{options[:outer2]}"
  options[:out] = "adapter_#{side1_spec}_to_#{side2_spec}"
end

# Ensure output path includes output directory
unless options[:out].include?("/")
  options[:out] = File.join(output_dir, options[:out])
end

# Convert measurements to inches for OpenSCAD (since dust collection is often measured in inches)
# But keep calculations in mm for precision
side1_length_mm = 50.8  # 2 inches
transition_length_mm = 25.4  # 1 inch  
side2_length_mm = 50.8  # 2 inches
total_length_mm = side1_length_mm + transition_length_mm + side2_length_mm

# Generate OpenSCAD script for tapered adapter
scad_content = <<~SCAD
  // Tapered dust collection adapter
  // Side 1: #{side1_inner}mm inner / #{side1_outer}mm outer
  // Side 2: #{side2_inner}mm inner / #{side2_outer}mm outer
  
  side1_inner = #{side1_inner};
  side1_outer = #{side1_outer};
  side2_inner = #{side2_inner};
  side2_outer = #{side2_outer};
  
  side1_length = #{side1_length_mm};  // 2 inches
  transition_length = #{transition_length_mm};  // 1 inch
  side2_length = #{side2_length_mm};  // 2 inches
  total_length = #{total_length_mm};  // 5 inches total
  
  module tapered_adapter() {
      difference() {
          // Outer shape - three distinct sections
          union() {
              // Side 1: constant diameter for 2 inches
              translate([0, 0, 0])
              cylinder(h=side1_length, r=side1_outer/2, $fn=128);
              
              // Transition: tapered section for 1 inch
              translate([0, 0, side1_length])
              hull() {
                  cylinder(h=0.1, r=side1_outer/2, $fn=128);
                  translate([0, 0, transition_length])
                  cylinder(h=0.1, r=side2_outer/2, $fn=128);
              }
              
              // Side 2: constant diameter for 2 inches
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

begin
  # Create SCAD file
  scad_file = "#{options[:out]}.scad"
  File.write(scad_file, scad_content)
  puts "✅ Created #{scad_file}"
  
  if options[:generate_stl]
    # Create STL file
    stl_file = "#{options[:out]}.stl"
    puts "Generating STL (timeout: #{options[:timeout]}s)..."
    puts "This may take a while for complex tapered geometry. Press Ctrl+C to cancel."
    RingGenerator.convert_scad_to_stl(scad_file, stl_file, timeout: options[:timeout])
    puts "✅ Created #{stl_file}"
  end
  
  puts "\n📊 Tapered Adapter Summary:"
  puts "   Side 1: #{side1_inner}mm inner / #{side1_outer}mm outer diameter"
  puts "   Side 2: #{side2_inner}mm inner / #{side2_outer}mm outer diameter"
  puts "   Structure: 2\" side1 + 1\" transition + 2\" side2 (5\" total)"
  puts "   Total length: #{total_length_mm}mm (#{sprintf('%.1f', total_length_mm/25.4)} inches)"
  
  if options[:generate_stl]
    puts "   STL file ready for 3D printing"
  else
    puts "   SCAD file ready for OpenSCAD"
  end

rescue => e
  warn "Error: #{e.message}"
  exit 1
end
