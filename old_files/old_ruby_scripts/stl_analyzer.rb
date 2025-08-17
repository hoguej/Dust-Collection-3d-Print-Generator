#!/usr/bin/env ruby
# Simple STL analyzer to verify geometry and text presence

def analyze_stl(filename)
  puts "=== Analyzing #{filename} ==="
  
  unless File.exist?(filename)
    puts "ERROR: File #{filename} does not exist"
    return
  end
  
  facet_count = 0
  vertices = []
  min_x, max_x = Float::INFINITY, -Float::INFINITY
  min_y, max_y = Float::INFINITY, -Float::INFINITY
  min_z, max_z = Float::INFINITY, -Float::INFINITY
  
  # Parse STL file
  File.open(filename, 'r') do |f|
    f.each_line do |line|
      line.strip!
      
      if line.start_with?('facet normal')
        facet_count += 1
      elsif line.start_with?('vertex')
        coords = line.split[1..3].map(&:to_f)
        vertices << coords
        x, y, z = coords
        
        min_x = [min_x, x].min
        max_x = [max_x, x].max
        min_y = [min_y, y].min
        max_y = [max_y, y].max
        min_z = [min_z, z].min
        max_z = [max_z, z].max
      end
    end
  end
  
  puts "Facet count: #{facet_count}"
  puts "Vertex count: #{vertices.length}"
  puts "Bounding box:"
  puts "  X: #{min_x.round(3)} to #{max_x.round(3)} (width: #{(max_x - min_x).round(3)})"
  puts "  Y: #{min_y.round(3)} to #{max_y.round(3)} (depth: #{(max_y - min_y).round(3)})"
  puts "  Z: #{min_z.round(3)} to #{max_z.round(3)} (height: #{(max_z - min_z).round(3)})"
  
  # Calculate ring properties from vertices
  ring_vertices = vertices.select { |x, y, z| z.abs < 0.1 || (z - max_z).abs < 0.1 }
  radii = ring_vertices.map { |x, y, z| Math.sqrt(x*x + y*y) }
  
  if radii.any?
    inner_radius = radii.min
    outer_radius = radii.max
    puts "Detected ring radii: inner=#{inner_radius.round(3)}, outer=#{outer_radius.round(3)}"
    
    # Look for text vertices (should be at intermediate radii)
    text_vertices = vertices.select do |x, y, z|
      r = Math.sqrt(x*x + y*y)
      r > inner_radius + 0.5 && r < outer_radius - 0.5
    end
    
    puts "Potential text vertices: #{text_vertices.length}"
    
    if text_vertices.length > 0
      puts "Text vertex sample (first 5):"
      text_vertices.first(5).each_with_index do |vertex, i|
        x, y, z = vertex
        r = Math.sqrt(x*x + y*y)
        angle = Math.atan2(y, x) * 180 / Math::PI
        puts "  #{i+1}: (#{x.round(2)}, #{y.round(2)}, #{z.round(2)}) r=#{r.round(2)} θ=#{angle.round(1)}°"
      end
      
      # Check if vertices are distributed around the circle (indicating text)
      angles = text_vertices.map { |x, y, z| Math.atan2(y, x) }
      angle_range = (angles.max - angles.min) * 180 / Math::PI
      puts "Text angular spread: #{angle_range.round(1)}° (expecting ~60-180° for text)"
      
      if angle_range > 30
        puts "✓ TEXT APPEARS TO BE PRESENT - vertices distributed around circumference"
      else
        puts "⚠ TEXT MAY BE MISSING - vertices not well distributed"
      end
    else
      puts "✗ NO TEXT DETECTED - no vertices found at text radius"
    end
  end
  
  puts ""
end

def compare_with_and_without_text
  puts "=== Generating test files for comparison ==="
  
  # Generate file without text (modify the script temporarily)
  puts "Generating ring without text..."
  system("ruby -e \"
    load 'doit.rb'
    # Temporarily disable text
    def create_circular_text(*args); []; end
    ARGV.replace(['--id', '46', '--t', '2', '--h', '3', '-o', 'ring_no_text.stl'])
    load 'doit.rb'
  \"")
  
  # Generate file with text
  puts "Generating ring with text..."
  system("ruby doit.rb --id 46 --t 2 --h 3 -o ring_with_text.stl")
  
  # Analyze both
  analyze_stl('ring_no_text.stl')
  analyze_stl('ring_with_text.stl')
  
  # Compare
  if File.exist?('ring_no_text.stl') && File.exist?('ring_with_text.stl')
    no_text_size = File.size('ring_no_text.stl')
    with_text_size = File.size('ring_with_text.stl')
    
    puts "=== File Size Comparison ==="
    puts "Without text: #{no_text_size} bytes"
    puts "With text: #{with_text_size} bytes"
    puts "Difference: #{with_text_size - no_text_size} bytes (#{((with_text_size.to_f / no_text_size - 1) * 100).round(1)}% larger)"
    
    if with_text_size > no_text_size * 1.1
      puts "✓ Significant size increase suggests text geometry is being added"
    else
      puts "⚠ Small size difference - text may not be generating properly"
    end
  end
end

# Run the analysis
if ARGV.length > 0
  ARGV.each { |filename| analyze_stl(filename) }
else
  compare_with_and_without_text
end

