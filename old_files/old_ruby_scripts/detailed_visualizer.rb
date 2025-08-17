#!/usr/bin/env ruby
# Detailed STL Visualizer with side view and text height analysis

def analyze_and_visualize_stl(filename)
  puts "=" * 80
  puts "DETAILED STL ANALYSIS: #{filename}"
  puts "=" * 80
  
  unless File.exist?(filename)
    puts "ERROR: File #{filename} does not exist"
    return
  end
  
  vertices = []
  
  # Parse STL file
  File.open(filename, 'r') do |f|
    f.each_line do |line|
      line.strip!
      if line.start_with?('vertex')
        coords = line.split[1..3].map(&:to_f)
        vertices << coords
      end
    end
  end
  
  puts "Total vertices: #{vertices.length}"
  
  # Get bounds
  x_coords = vertices.map { |v| v[0] }
  y_coords = vertices.map { |v| v[1] }
  z_coords = vertices.map { |v| v[2] }
  
  min_x, max_x = x_coords.minmax
  min_y, max_y = y_coords.minmax  
  min_z, max_z = z_coords.minmax
  
  puts "Bounding box:"
  puts "  X: #{min_x.round(2)} to #{max_x.round(2)} (width: #{(max_x - min_x).round(2)}mm)"
  puts "  Y: #{min_y.round(2)} to #{max_y.round(2)} (depth: #{(max_y - min_y).round(2)}mm)"
  puts "  Z: #{min_z.round(2)} to #{max_z.round(2)} (height: #{(max_z - min_z).round(2)}mm)"
  
  ring_height = max_z - min_z
  expected_text_height = ring_height * 0.8
  puts "Expected text height (80%): #{expected_text_height.round(2)}mm"
  
  # Identify ring vs text vertices
  ring_radii = vertices.map { |x, y, z| Math.sqrt(x*x + y*y) }
  inner_radius = ring_radii.min
  outer_radius = ring_radii.max
  
  puts "Ring radii: inner=#{inner_radius.round(2)}mm, outer=#{outer_radius.round(2)}mm"
  
  # Find text vertices (should be at intermediate radius and various Z heights)
  text_radius_min = inner_radius + (outer_radius - inner_radius) * 0.1
  text_radius_max = outer_radius - (outer_radius - inner_radius) * 0.1
  
  text_vertices = vertices.select do |x, y, z|
    r = Math.sqrt(x*x + y*y)
    r >= text_radius_min && r <= text_radius_max && z > min_z + 0.5 && z < max_z - 0.5
  end
  
  puts "Text vertices found: #{text_vertices.length} (radius #{text_radius_min.round(1)}-#{text_radius_max.round(1)}mm)"
  
  if text_vertices.length > 0
    # Analyze text height distribution
    text_z_coords = text_vertices.map { |v| v[2] }
    text_min_z, text_max_z = text_z_coords.minmax
    actual_text_height = text_max_z - text_min_z
    
    puts "Actual text Z range: #{text_min_z.round(2)} to #{text_max_z.round(2)}mm"
    puts "Actual text height: #{actual_text_height.round(2)}mm"
    puts "Text height ratio: #{(actual_text_height / ring_height * 100).round(1)}%"
    
    if actual_text_height < expected_text_height * 0.5
      puts "⚠️  WARNING: Text height is much smaller than expected!"
    elsif actual_text_height >= expected_text_height * 0.7
      puts "✅ Text height looks good"
    end
    
    # Angular distribution
    text_angles = text_vertices.map { |x, y, z| Math.atan2(y, x) * 180 / Math::PI }
    angle_min, angle_max = text_angles.minmax
    angle_spread = angle_max - angle_min
    
    puts "Text angular spread: #{angle_spread.round(1)}° (from #{angle_min.round(1)}° to #{angle_max.round(1)}°)"
    
    # Create side view visualization (X-Z plane, looking along Y axis)
    puts "\n" + "=" * 60
    puts "SIDE VIEW (X-Z plane, looking along Y-axis)"
    puts "Shows text height relative to ring height"
    puts "=" * 60
    
    # Filter vertices near Y=0 for side view (within ±2mm of Y=0)
    side_vertices = vertices.select { |x, y, z| y.abs < 2.0 }
    
    if side_vertices.length > 10
      width = 80
      height = 30
      grid = Array.new(height) { Array.new(width, ' ') }
      
      side_x = side_vertices.map { |v| v[0] }
      side_z = side_vertices.map { |v| v[2] }
      
      side_min_x, side_max_x = side_x.minmax
      side_min_z, side_max_z = side_z.minmax
      
      side_vertices.each do |x, y, z|
        grid_x = ((x - side_min_x) / (side_max_x - side_min_x) * (width - 1)).round
        grid_z = ((z - side_min_z) / (side_max_z - side_min_z) * (height - 1)).round
        
        grid_x = [[grid_x, 0].max, width - 1].min
        grid_z = [[grid_z, 0].max, height - 1].min
        
        # Use different characters for different radii
        r = Math.sqrt(x*x + y*y)
        if r < text_radius_min
          grid[height - 1 - grid_z][grid_x] = '='  # Inner ring
        elsif r > text_radius_max  
          grid[height - 1 - grid_z][grid_x] = '='  # Outer ring
        else
          grid[height - 1 - grid_z][grid_x] = 'T'  # Text area
        end
      end
      
      puts "Legend: = = ring structure, T = text vertices"
      puts "+" + "-" * width + "+"
      grid.each_with_index do |row, i|
        z_value = side_max_z - (i.to_f / (height - 1)) * (side_max_z - side_min_z)
        puts "|" + row.join + "| #{z_value.round(1)}"
      end
      puts "+" + "-" * width + "+"
      
      x_labels = []
      (0...width).step(10) do |i|
        x_value = side_min_x + (i.to_f / (width - 1)) * (side_max_x - side_min_x)
        x_labels << x_value.round(1).to_s.center(10)
      end
      puts " " + x_labels.join
    end
    
    # Create top view with text highlighted
    puts "\n" + "=" * 60
    puts "TOP VIEW (X-Y plane, looking down Z-axis)"
    puts "Text vertices highlighted with 'T'"
    puts "=" * 60
    
    width = 80
    height = 40
    grid = Array.new(height) { Array.new(width, ' ') }
    
    vertices.each do |x, y, z|
      grid_x = ((x - min_x) / (max_x - min_x) * (width - 1)).round
      grid_y = ((y - min_y) / (max_y - min_y) * (height - 1)).round
      
      grid_x = [[grid_x, 0].max, width - 1].min
      grid_y = [[grid_y, 0].max, height - 1].min
      
      r = Math.sqrt(x*x + y*y)
      if r >= text_radius_min && r <= text_radius_max && z > min_z + 0.5 && z < max_z - 0.5
        grid[height - 1 - grid_y][grid_x] = 'T'  # Text
      else
        grid[height - 1 - grid_y][grid_x] = '*'  # Ring
      end
    end
    
    puts "Legend: * = ring structure, T = text vertices"
    puts "+" + "-" * width + "+"
    grid.each do |row|
      puts "|" + row.join + "|"
    end
    puts "+" + "-" * width + "+"
    
  else
    puts "❌ NO TEXT VERTICES FOUND!"
    puts "This suggests text generation is not working properly."
  end
  
  puts "\n" + "=" * 80
end

# Run the detailed analysis
filename = ARGV[0] || 'tall_ring_test.stl'
analyze_and_visualize_stl(filename)

