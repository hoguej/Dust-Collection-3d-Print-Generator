#!/usr/bin/env ruby
# ring_maker.rb - CLI for ring generator using OpenSCAD
# Uses RingGenerator module for the core functionality

require 'optparse'
require_relative 'lib/ring_generator'

# CLI Options
options = {
  inner: nil,
  outer: nil,
  t: 2.0,
  h: 20.0,
  text: nil,
  font_size: 5.0,
  text_depth: 2.0,
  out: nil,
  generate_stl: false,
  timeout: 120
}

parser = OptionParser.new do |o|
  o.banner = "Usage: ruby ring_maker.rb [options]\n" \
             "Creates a ring SCAD file by default. Use --stl to generate both SCAD and STL files."
  
  o.on("-i", "--inner DIAMETER", Float, "Inner diameter in mm") { |v| options[:inner] = v }
  o.on("-o", "--outer DIAMETER", Float, "Outer diameter in mm") { |v| options[:outer] = v }
  o.on("--t T_MM", Float, "Thickness (radial) in mm (default 2.0)") { |v| options[:t] = v }
  o.on("--h H_MM", Float, "Height in mm (default 20.0)") { |v| options[:h] = v }
  o.on("--text TEXT", String, "Text to emboss (optional)") { |v| options[:text] = v }
  o.on("--font-size SIZE", Float, "Font size (default 5.0)") { |v| options[:font_size] = v }
  o.on("--text-depth DEPTH", Float, "Text depth in mm (default 2.0)") { |v| options[:text_depth] = v }
  o.on("--stl", "Generate STL file (default: generate SCAD only)") { |v| options[:generate_stl] = true }
  o.on("--timeout SECONDS", Integer, "STL generation timeout in seconds (default 120)") { |v| options[:timeout] = v }
  o.on("-f", "--file FILE", String, "Output file path (optional)") { |v| options[:out] = v }
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
if ARGV.empty? && options[:inner].nil? && options[:outer].nil?
  puts parser
  exit 0
end

# Validation
if options[:t] <= 0
  warn "Error: thickness must be > 0"
  exit 1
end

mode_inner = !options[:inner].nil?
mode_outer = !options[:outer].nil?
if mode_inner == mode_outer
  warn "Error: specify exactly one of -i/--inner or -o/--outer"
  puts parser
  exit 1
end

# Calculate dimensions
inner_diameter = nil
outer_diameter = nil
if mode_inner
  inner_diameter = options[:inner]
  raise "Inner diameter must be > 0" unless inner_diameter > 0
  outer_diameter = inner_diameter + (options[:t] * 2)
else
  outer_diameter = options[:outer]
  raise "Outer diameter must be > 0" unless outer_diameter > 0
  inner_diameter = RingGenerator.calculate_inner_diameter(outer_diameter, options[:t])
end

# Generate text if not provided, with I/O indicator
text = options[:text]
if text.nil?
  diameter = mode_inner ? inner_diameter : outer_diameter
  base_text = RingGenerator.generate_default_text(diameter)
  # Add I/O indicator for better identification when text is always on outer surface
  text = mode_inner ? "I#{base_text}" : "O#{base_text}"
end

# Ensure output directory exists
output_dir = "output"
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

# Generate output filename
if options[:out].nil?
  extension = options[:generate_stl] ? ".stl" : ".scad"
  base_name = RingGenerator.generate_filename(
    inner_diameter, 
    options[:t], 
    options[:h], 
    mode_inner, 
    outer_diameter: outer_diameter, 
    extension: extension
  )
  options[:out] = File.join(output_dir, base_name)
else
  # If user specified a filename, still put it in output directory unless it's already a full path
  unless options[:out].include?("/")
    options[:out] = File.join(output_dir, options[:out])
  end
end

begin
  if options[:generate_stl]
    puts "Generating SCAD and STL files with OpenSCAD (timeout: #{options[:timeout]}s)..."
    puts "This may take a while for complex models. Press Ctrl+C to cancel."
    
    # Create SCAD file first
    scad_filepath = options[:out].gsub(/\.stl$/i, '.scad')
    RingGenerator.create_scad_file(
      scad_filepath,
      inner_diameter: inner_diameter,
      thickness: options[:t],
      height: options[:h],
      text: text,
      font_size: options[:font_size],
      text_depth: options[:text_depth],
      text_on_inner: mode_inner
    )
    
    puts "✅ Created #{scad_filepath}"
    
    # Convert to STL with timeout
    RingGenerator.convert_scad_to_stl(scad_filepath, options[:out], timeout: options[:timeout])
    
    puts "✅ Created #{options[:out]}"
  else
    RingGenerator.create_scad_file(
      options[:out],
      inner_diameter: inner_diameter,
      thickness: options[:t],
      height: options[:h],
      text: text,
      font_size: options[:font_size],
      text_depth: options[:text_depth],
      text_on_inner: mode_inner
    )
  end
  
  puts "✅ Successfully created #{options[:out]}"
  puts "   Inner diameter: #{inner_diameter}mm"
  puts "   Thickness: #{options[:t]}mm"
  puts "   Height: #{options[:h]}mm"
  puts "   Text: '#{text}'"
  
rescue => e
  warn "Error: #{e.message}"
  exit 1
end