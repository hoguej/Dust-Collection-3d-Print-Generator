#!/usr/bin/env ruby
# make_test_fit_kit.rb - Creates a test fit kit with 3 rings at different clearances
# For testing fits around machinery parts like dust nozzles

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
  o.banner = "Usage: ruby make_test_fit_kit.rb [options]\n" \
             "Creates a test fit kit with 5 rings (1 replica + 4 test fits).\n" \
             "Test clearances: Auto-calculated based on diameter (dust collection optimized)\n" \
             "Creates combined SCAD file by default.\n" \
             "Use --stl to generate individual SCAD and STL files in a subdirectory."
  
  o.on("-i", "--inner DIAMETER", Float, "Inner diameter in mm (creates rings that fit inside)") { |v| options[:inner] = v }
  o.on("-o", "--outer DIAMETER", Float, "Outer diameter in mm (creates rings that fit around)") { |v| options[:outer] = v }
  o.on("--t T_MM", Float, "Thickness (radial) in mm (default 2.0)") { |v| options[:t] = v }
  o.on("--h H_MM", Float, "Height in mm (default 20.0)") { |v| options[:h] = v }
  o.on("--font-size SIZE", Float, "Font size (default 5.0)") { |v| options[:font_size] = v }
  o.on("--text-depth DEPTH", Float, "Text depth in mm (default 2.0)") { |v| options[:text_depth] = v }
  o.on("--stl", "Generate STL file (default: generate SCAD only)") { |v| options[:generate_stl] = true }
  o.on("--timeout SECONDS", Integer, "STL generation timeout in seconds (default 180)") { |v| options[:timeout] = v }
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

# Calculate base outer diameter (BOD)
base_outer_diameter = nil
if mode_outer
  base_outer_diameter = options[:outer]
  raise "Outer diameter must be > 0" unless base_outer_diameter > 0
else
  base_inner_diameter = options[:inner]
  raise "Inner diameter must be > 0" unless base_inner_diameter > 0
  base_outer_diameter = base_inner_diameter  # For inner mode, treat as the target outer diameter
end

# Ensure output directory exists
output_dir = "output"
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

# Generate output filename
if options[:out].nil?
  base_name = if mode_outer
    "test_fit_kit_od#{format('%.1f', base_outer_diameter)}_t#{format('%.1f', options[:t])}_h#{format('%.1f', options[:h])}"
  else
    "test_fit_kit_id#{format('%.1f', options[:inner])}_t#{format('%.1f', options[:t])}_h#{format('%.1f', options[:h])}"
  end
  extension = options[:generate_stl] ? ".stl" : ".scad"
  options[:out] = File.join(output_dir, "#{base_name}#{extension}")
else
  unless options[:out].include?("/")
    options[:out] = File.join(output_dir, options[:out])
  end
end

# Generate the combined SCAD file with replica + 4 test rings (5 total)
def generate_test_fit_kit_scad(base_outer_diameter:, thickness:, height:, font_size:, text_depth:, mode_outer:, base_inner_diameter: nil)
  # Calculate optimal clearances based on dust collection formula
  base_clearance = RingGenerator.calculate_dust_collection_clearance(base_outer_diameter)
  clearances = [
    base_clearance * 0.5,  # Tight fit
    base_clearance * 0.75, # Snug fit  
    base_clearance,        # Optimal fit
    base_clearance * 1.5   # Loose fit
  ]
  
  # Calculate proper spacing based on largest ring diameter + clearance
  max_diameter = if mode_outer
    # Largest test ring will have inner diameter = base + 0.5, outer = inner + thickness*2
    max_inner = base_outer_diameter + 0.5
    max_inner + (thickness * 2)
  else
    # Replica ring will likely be largest, or base outer diameter
    [base_inner_diameter + (thickness * 2), base_inner_diameter].max
  end
  
  spacing = max_diameter + 10.0  # Ring diameter + 10mm clearance
  
  scad_parts = []
  
  # Add the ring generator module functions
  scad_parts << RingGenerator.generate_scad_script(
    inner_diameter: 10,  # Dummy values - we'll override the main module
    thickness: thickness,
    height: height,
    text: "dummy",
    font_size: font_size,
    text_depth: text_depth,
    text_on_inner: true
  ).split("ring_with_text();").first  # Get everything except the final call
  
  # Calculate grid positions for cross layout (5 rings)
  # Position 0: (spacing, spacing) - center (replica)
  # Position 1: (spacing, 0) - bottom
  # Position 2: (0, spacing) - left
  # Position 3: (2*spacing, spacing) - right
  # Position 4: (spacing, 2*spacing) - top
  positions = [
    [spacing, spacing],        # Replica (center)
    [spacing, 0],              # Test ring 1 (+0.2mm) - bottom
    [0, spacing],              # Test ring 2 (+0.3mm) - left  
    [2*spacing, spacing],      # Test ring 3 (+0.4mm) - right
    [spacing, 2*spacing]       # Test ring 4 (+0.5mm) - top
  ]
  
  # Generate the replica ring first (position 0)
  if mode_outer
    # Replica of the outer diameter part
    replica_outer_diameter = base_outer_diameter
    replica_inner_diameter = replica_outer_diameter - (thickness * 2)
    if replica_inner_diameter <= 0
      raise "Thickness too large for replica: inner diameter <= 0"
    end
    replica_text = "O#{format('%.1f', replica_outer_diameter)}mm"
    replica_text_on_inner = false  # Text on outside for outer diameter parts
  else
    # Replica of the inner diameter part  
    replica_inner_diameter = base_inner_diameter
    replica_outer_diameter = replica_inner_diameter + (thickness * 2)
    replica_text = "I#{format('%.1f', replica_inner_diameter)}mm"
    replica_text_on_inner = true  # Text on inside for inner diameter parts
  end
  
  scad_parts << <<~SCAD
    
    // Replica of original part (bottom left)
    translate([#{positions[0][0]}, #{positions[0][1]}, 0]) {
        difference() {
            cylinder(h=#{height}, r=#{replica_outer_diameter / 2}, $fn=128);
            cylinder(h=#{height + 1}, r=#{replica_inner_diameter / 2}, $fn=128);
            
            translate([0, 0, #{height / 2}])
            rotate([0, 0, 180])
            curved_text_outer("#{replica_text}", #{replica_outer_diameter / 2}, #{font_size}, #{text_depth});
        }
    }
  SCAD
  
  # Generate each test ring in grid positions
  clearances.each_with_index do |clearance, index|
    position = positions[index + 1]  # Skip position 0 (replica)
    x_offset = position[0]
    y_offset = position[1]
    
    if mode_outer
      # For outer diameter mode: rings fit AROUND the given diameter
      # Inner diameter = base_outer_diameter + clearance
      ring_inner_diameter = base_outer_diameter + clearance
      ring_outer_diameter = ring_inner_diameter + (thickness * 2)
      text = "I#{format('%.1f', ring_inner_diameter)}mm"
      text_on_inner = true
    else
      # For inner diameter mode: rings fit INSIDE the given diameter
      # Outer diameter = base_inner_diameter - clearance
      ring_outer_diameter = base_inner_diameter - clearance
      ring_inner_diameter = ring_outer_diameter - (thickness * 2)
      if ring_inner_diameter <= 0
        raise "Thickness too large for clearance #{clearance}mm: inner diameter <= 0"
      end
      text = "O#{format('%.1f', ring_outer_diameter)}mm"
      text_on_inner = false
    end
    
    # Determine grid position description
    position_names = ["bottom right", "top left", "top right"]
    
    scad_parts << <<~SCAD
      
      // Test ring #{index + 1}: #{clearance}mm clearance (#{position_names[index]})
      translate([#{x_offset}, #{y_offset}, 0]) {
          difference() {
              cylinder(h=#{height}, r=#{ring_outer_diameter / 2}, $fn=128);
              cylinder(h=#{height + 1}, r=#{ring_inner_diameter / 2}, $fn=128);
              
              translate([0, 0, #{height / 2}])
              rotate([0, 0, 180])
              curved_text_outer("#{text}", #{ring_outer_diameter / 2}, #{font_size}, #{text_depth});
          }
      }
    SCAD
  end
  
  scad_parts.join("\n")
end

# Generate individual ring data for separate files
def generate_individual_rings(base_outer_diameter:, thickness:, height:, font_size:, text_depth:, mode_outer:, base_inner_diameter: nil)
  rings = []
  
  if mode_outer
    # Mode: outer diameter provided, create rings that fit around it
    
    # Ring 1: Replica of the base part
    replica_inner = RingGenerator.calculate_inner_diameter(base_outer_diameter, thickness)
    rings << {
      name: "replica_od#{base_outer_diameter}",
      scad: RingGenerator.generate_scad_script(
        inner_diameter: replica_inner,
        thickness: thickness,
        height: height,
        text: "O#{base_outer_diameter}mm",
        font_size: font_size,
        text_depth: text_depth,
        text_on_inner: false
      )
    }
    
    # Calculate optimal clearances based on dust collection formula
    base_clearance = RingGenerator.calculate_dust_collection_clearance(base_outer_diameter)
    clearances = [
      base_clearance * 0.5,  # Tight fit
      base_clearance * 0.75, # Snug fit  
      base_clearance,        # Optimal fit
      base_clearance * 1.5   # Loose fit
    ]
    
    # Rings 2-5: Test fits with calculated clearances
    clearances.each_with_index do |clearance, i|
      test_inner = base_outer_diameter + clearance
      test_outer = test_inner + (2 * thickness)
      rings << {
        name: "test_fit_#{sprintf('%.1f', clearance)}mm_clearance",
        scad: RingGenerator.generate_scad_script(
          inner_diameter: test_inner,
          thickness: thickness,
          height: height,
          text: "I#{test_inner}mm",
          font_size: font_size,
          text_depth: text_depth,
          text_on_inner: true
        )
      }
    end
  else
    # Mode: inner diameter provided, create rings that fit inside it
    
    # Ring 1: Replica of the base part
    rings << {
      name: "replica_id#{base_inner_diameter}",
      scad: RingGenerator.generate_scad_script(
        inner_diameter: base_inner_diameter,
        thickness: thickness,
        height: height,
        text: "I#{base_inner_diameter}mm",
        font_size: font_size,
        text_depth: text_depth,
        text_on_inner: true
      )
    }
    
    # Calculate optimal clearances based on dust collection formula
    base_clearance = RingGenerator.calculate_dust_collection_clearance(base_inner_diameter)
    clearances = [
      base_clearance * 0.5,  # Tight fit
      base_clearance * 0.75, # Snug fit  
      base_clearance,        # Optimal fit
      base_clearance * 1.5   # Loose fit
    ]
    
    # Rings 2-5: Test fits with calculated clearances
    clearances.each_with_index do |clearance, i|
      test_outer = base_inner_diameter - clearance
      test_inner = RingGenerator.calculate_inner_diameter(test_outer, thickness)
      rings << {
        name: "test_fit_#{sprintf('%.1f', clearance)}mm_clearance",
        scad: RingGenerator.generate_scad_script(
          inner_diameter: test_inner,
          thickness: thickness,
          height: height,
          text: "O#{test_outer}mm",
          font_size: font_size,
          text_depth: text_depth,
          text_on_inner: false
        )
      }
    end
  end
  
  rings
end

begin
  if options[:generate_stl]
    # Create individual ring files in a subdirectory
    base_name = File.basename(options[:out], '.stl')
    kit_dir = File.join('output', base_name)
    Dir.mkdir(kit_dir) unless Dir.exist?(kit_dir)
    
    puts "Creating individual ring files in #{kit_dir}/"
    
    # Generate individual rings
    rings = generate_individual_rings(
      base_outer_diameter: base_outer_diameter,
      thickness: options[:t],
      height: options[:h],
      font_size: options[:font_size],
      text_depth: options[:text_depth],
      mode_outer: mode_outer,
      base_inner_diameter: options[:inner]
    )
    
    rings.each_with_index do |ring_data, index|
      ring_name = ring_data[:name]
      scad_content = ring_data[:scad]
      
      # Create SCAD file
      scad_file = File.join(kit_dir, "#{ring_name}.scad")
      File.write(scad_file, scad_content)
      puts "✅ Created #{scad_file}"
      
      # Create STL file
      stl_file = File.join(kit_dir, "#{ring_name}.stl")
      puts "Generating STL #{index + 1}/5: #{ring_name} (timeout: #{options[:timeout]}s)..."
      RingGenerator.convert_scad_to_stl(scad_file, stl_file, timeout: options[:timeout])
      puts "✅ Created #{stl_file}"
    end
  else
    # Generate combined SCAD file only (original behavior)
    scad_content = generate_test_fit_kit_scad(
      base_outer_diameter: base_outer_diameter,
      thickness: options[:t],
      height: options[:h],
      font_size: options[:font_size],
      text_depth: options[:text_depth],
      mode_outer: mode_outer,
      base_inner_diameter: options[:inner]
    )
    
    File.write(options[:out], scad_content)
    puts "✅ Created #{options[:out]}"
  end
  puts "\n📊 Test Kit Summary:"
  if mode_outer
    puts "   Base outer diameter: #{base_outer_diameter}mm"
    puts "   Ring 1 (replica): #{base_outer_diameter}mm outer diameter"
    # Calculate clearances for display
    base_clearance = RingGenerator.calculate_dust_collection_clearance(base_outer_diameter)
    clearances = [base_clearance * 0.5, base_clearance * 0.75, base_clearance, base_clearance * 1.5]
    test_diameters = clearances.map { |c| base_outer_diameter + c }
    puts "   Ring 2-5 (test fits - inner diameters): #{test_diameters.map { |d| sprintf('%.1f', d) }.join('mm, ')}mm"
    puts "   Calculated clearances: #{clearances.map { |c| sprintf('%.2f', c) }.join('mm, ')}mm (tight, snug, optimal, loose)"
  else
    puts "   Base inner diameter: #{options[:inner]}mm"
    puts "   Ring 1 (replica): #{options[:inner]}mm inner diameter"
    # Calculate clearances for display
    base_clearance = RingGenerator.calculate_dust_collection_clearance(options[:inner])
    clearances = [base_clearance * 0.5, base_clearance * 0.75, base_clearance, base_clearance * 1.5]
    test_diameters = clearances.map { |c| options[:inner] - c }
    puts "   Ring 2-5 (test fits - outer diameters): #{test_diameters.map { |d| sprintf('%.1f', d) }.join('mm, ')}mm"
    puts "   Calculated clearances: #{clearances.map { |c| sprintf('%.2f', c) }.join('mm, ')}mm (tight, snug, optimal, loose)"
  end
  puts "   Thickness: #{options[:t]}mm"
  puts "   Height: #{options[:h]}mm"
  
  if options[:generate_stl]
    puts "   5 individual STL files created for independent manipulation in slicer"
  else
    # Calculate and show spacing info for combined SCAD
    max_diameter = if mode_outer
      max_inner = base_outer_diameter + 0.5
      max_inner + (options[:t] * 2)
    else
      [options[:inner] + (options[:t] * 2), options[:inner]].max
    end
    calculated_spacing = max_diameter + 10.0
    
    puts "   5 rings total, arranged in cross pattern for easy printing"
    puts "   Grid spacing: #{format('%.1f', calculated_spacing)}mm (largest ring #{format('%.1f', max_diameter)}mm + 10mm clearance)"
  end
  
rescue => e
  warn "Error: #{e.message}"
  exit 1
end
