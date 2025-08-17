#!/usr/bin/env ruby
# make_adapter_pair.rb - Create a replica ring and its matching adapter

require 'optparse'
require_relative 'lib/ring_generator'

# CLI Options
options = {
  inner: nil,
  outer: nil,
  t: 2.0,
  h: 20.0,
  font_size: 5.0,
  text_depth: 2.0,
  out: nil,
  generate_stl: false,
  timeout: 180
}

parser = OptionParser.new do |o|
  o.banner = "Usage: ruby make_adapter_pair.rb [options]\n" \
             "Creates 2 rings: a replica + its matching adapter.\n" \
             "Uses dust collection clearance formula for optimal fit.\n" \
             "Creates individual SCAD files by default.\n" \
             "Use --stl to also generate STL files."
  
  o.on("-i", "--inner DIAMETER", Float, "Inner diameter in mm (creates adapter that slides inside)") { |v| options[:inner] = v }
  o.on("-o", "--outer DIAMETER", Float, "Outer diameter in mm (creates adapter that slides over)") { |v| options[:outer] = v }
  o.on("--t T_MM", Float, "Thickness (radial) in mm (default 2.0)") { |v| options[:t] = v }
  o.on("--h H_MM", Float, "Height in mm (default 20.0)") { |v| options[:h] = v }
  o.on("--font-size SIZE", Float, "Font size (default 5.0)") { |v| options[:font_size] = v }
  o.on("--text-depth DEPTH", Float, "Text depth in mm (default 2.0)") { |v| options[:text_depth] = v }
  o.on("--stl", "Generate STL files (also creates SCAD files)") { |v| options[:generate_stl] = true }
  o.on("--timeout SECONDS", Integer, "STL generation timeout in seconds (default 180)") { |v| options[:timeout] = v }
  o.on("-f", "--file FILE", String, "Output directory name (optional)") { |v| options[:out] = v }
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

# Ensure output directory exists
output_dir = "output"
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

# Generate output directory name
if options[:out].nil?
  if mode_inner
    options[:out] = "adapter_pair_id#{options[:inner]}"
  else
    options[:out] = "adapter_pair_od#{options[:outer]}"
  end
end

# Ensure output path includes output directory
unless options[:out].include?("/")
  options[:out] = File.join(output_dir, options[:out])
end

begin
  if mode_outer
    # Given outer diameter - create replica and adapter that fits inside it
    base_outer_diameter = options[:outer]
    
    # Ring 1: Replica of the measured part
    replica_inner_diameter = RingGenerator.calculate_inner_diameter(base_outer_diameter, options[:t])
    replica_rings = [{
      name: "replica_od#{base_outer_diameter}",
      description: "Replica of measured part",
      scad: RingGenerator.generate_scad_script(
        inner_diameter: replica_inner_diameter,
        thickness: options[:t],
        height: options[:h],
        text: "O#{base_outer_diameter}mm",
        font_size: options[:font_size],
        text_depth: options[:text_depth],
        text_on_inner: false
      )
    }]
    
    # Ring 2: Adapter that fits OVER the measured part (slides over the replica)
    optimal_clearance = RingGenerator.calculate_dust_collection_clearance(base_outer_diameter)
    adapter_inner_diameter = base_outer_diameter + optimal_clearance
    adapter_outer_diameter = adapter_inner_diameter + (2 * options[:t])
    
    adapter_rings = [{
      name: "adapter_id#{sprintf('%.1f', adapter_inner_diameter)}",
      description: "Adapter that fits over replica",
      scad: RingGenerator.generate_scad_script(
        inner_diameter: adapter_inner_diameter,
        thickness: options[:t],
        height: options[:h],
        text: "I#{sprintf('%.1f', adapter_inner_diameter)}mm",
        font_size: options[:font_size],
        text_depth: options[:text_depth],
        text_on_inner: true
      )
    }]
    
  else
    # Given inner diameter - create replica and adapter that fits around it
    base_inner_diameter = options[:inner]
    
    # Ring 1: Replica of the measured part  
    replica_rings = [{
      name: "replica_id#{base_inner_diameter}",
      description: "Replica of measured part",
      scad: RingGenerator.generate_scad_script(
        inner_diameter: base_inner_diameter,
        thickness: options[:t],
        height: options[:h],
        text: "I#{base_inner_diameter}mm",
        font_size: options[:font_size],
        text_depth: options[:text_depth],
        text_on_inner: true
      )
    }]
    
    # Ring 2: Adapter that fits INSIDE the measured part (slides into the replica)
    optimal_clearance = RingGenerator.calculate_dust_collection_clearance(base_inner_diameter)
    adapter_outer_diameter = base_inner_diameter - optimal_clearance
    adapter_inner_diameter = RingGenerator.calculate_inner_diameter(adapter_outer_diameter, options[:t])
    
    adapter_rings = [{
      name: "adapter_od#{sprintf('%.1f', adapter_outer_diameter)}",
      description: "Adapter that fits inside replica", 
      scad: RingGenerator.generate_scad_script(
        inner_diameter: adapter_inner_diameter,
        thickness: options[:t],
        height: options[:h],
        text: "O#{sprintf('%.1f', adapter_outer_diameter)}mm",
        font_size: options[:font_size],
        text_depth: options[:text_depth],
        text_on_inner: false
      )
    }]
  end
  
  # Create subdirectory for this adapter pair
  Dir.mkdir(options[:out]) unless Dir.exist?(options[:out])
  
  all_rings = replica_rings + adapter_rings
  
  all_rings.each_with_index do |ring_data, index|
    ring_name = ring_data[:name]
    scad_content = ring_data[:scad]
    description = ring_data[:description]
    
    # Create SCAD file
    scad_file = File.join(options[:out], "#{ring_name}.scad")
    File.write(scad_file, scad_content)
    puts "✅ Created #{scad_file} (#{description})"
    
    if options[:generate_stl]
      # Create STL file
      stl_file = File.join(options[:out], "#{ring_name}.stl")
      puts "Generating STL #{index + 1}/2: #{ring_name} (timeout: #{options[:timeout]}s)..."
      RingGenerator.convert_scad_to_stl(scad_file, stl_file, timeout: options[:timeout])
      puts "✅ Created #{stl_file}"
    end
  end
  
  puts "\n📊 Adapter Pair Summary:"
  if mode_outer
    puts "   Base outer diameter: #{base_outer_diameter}mm"
    puts "   Ring 1 (replica): #{base_outer_diameter}mm outer diameter"
    puts "   Ring 2 (adapter): #{sprintf('%.1f', adapter_inner_diameter)}mm inner diameter (slides over replica)"
    puts "   Optimal clearance: #{sprintf('%.2f', optimal_clearance)}mm"
  else
    puts "   Base inner diameter: #{base_inner_diameter}mm"
    puts "   Ring 1 (replica): #{base_inner_diameter}mm inner diameter"
    puts "   Ring 2 (adapter): #{sprintf('%.1f', adapter_outer_diameter)}mm outer diameter (slides into replica)"
    puts "   Optimal clearance: #{sprintf('%.2f', optimal_clearance)}mm"
  end
  puts "   Thickness: #{options[:t]}mm"
  puts "   Height: #{options[:h]}mm"
  puts "   Files created in: #{options[:out]}/"
  
  if options[:generate_stl]
    puts "   4 files total: 2 SCAD + 2 STL files for independent manipulation"
  else
    puts "   2 SCAD files created"
  end

rescue => e
  warn "Error: #{e.message}"
  exit 1
end
