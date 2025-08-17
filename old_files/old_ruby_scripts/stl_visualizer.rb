#!/usr/bin/env ruby
# STL Visualizer - Creates ASCII art visualization of STL geometry

def visualize_stl(filename, view_from_top: true)
  puts "=== Visualizing #{filename} ==="
  
  unless File.exist?(filename)
    puts "ERROR: File #{filename} does not exist"
    return
  end
  
  vertices = []
  
  # Parse STL file and collect all vertices
  File.open(filename, 'r') do |f|
    f.each_line do |line|
      line.strip!
      if line.start_with?('vertex')
        coords = line.split[1..3].map(&:to_f)
        vertices << coords
      end
    end
  end
  
  puts "Loaded #{vertices.length} vertices"
  
  if view_from_top
    # Top-down view (looking down Z axis)
    x_coords = vertices.map { |v| v[0] }
    y_coords = vertices.map { |v| v[1] }
    
    min_x, max_x = x_coords.minmax
    min_y, max_y = y_coords.minmax
    
    puts "X range: #{min_x.round(2)} to #{max_x.round(2)}"
    puts "Y range: #{min_y.round(2)} to #{max_y.round(2)}"
    
    # Create ASCII grid
    width = 80
    height = 40
    grid = Array.new(height) { Array.new(width, ' ') }
    
    vertices.each do |x, y, z|
      # Map to grid coordinates
      grid_x = ((x - min_x) / (max_x - min_x) * (width - 1)).round
      grid_y = ((y - min_y) / (max_y - min_y) * (height - 1)).round
      
      # Clamp to grid bounds
      grid_x = [[grid_x, 0].max, width - 1].min
      grid_y = [[grid_y, 0].max, height - 1].min
      
      grid[height - 1 - grid_y][grid_x] = '*'
    end
    
    puts "\nTop-down view (Z-axis looking down):"
    puts "+" + "-" * width + "+"
    grid.each do |row|
      puts "|" + row.join + "|"
    end
    puts "+" + "-" * width + "+"
    
    # Also create a polar visualization to better show text
    puts "\nPolar analysis (looking for text distribution):"
    text_candidates = vertices.select do |x, y, z|
      r = Math.sqrt(x*x + y*y)
      r > 20 && r < 30 && z > 0.5 && z < 2.5  # Text should be in this range
    end
    
    if text_candidates.length > 0
      # Group by angle
      angle_buckets = Hash.new(0)
      text_candidates.each do |x, y, z|
        angle = Math.atan2(y, x) * 180 / Math::PI
        bucket = (angle / 10).round * 10  # 10-degree buckets
        angle_buckets[bucket] += 1
      end
      
      puts "Vertex distribution by angle (10° buckets):"
      (-180..180).step(10) do |angle|
        count = angle_buckets[angle]
        if count > 0
          bar = "*" * [count / 5, 1].max
          puts "#{angle.to_s.rjust(4)}°: #{bar} (#{count})"
        end
      end
    else
      puts "No text candidates found in expected radius/height range"
    end
  end
end

def create_simple_test_visualization
  puts "=== Creating simple test to verify text generation ==="
  
  # Generate a simple ring with known text
  puts "Generating test ring..."
  system("ruby doit.rb --id 50 --t 3 --h 4 -o viz_test.stl")
  
  if File.exist?('viz_test.stl')
    visualize_stl('viz_test.stl')
    
    # Also create a detailed vertex dump for the text area
    puts "\n=== Detailed vertex analysis ==="
    vertices = []
    
    File.open('viz_test.stl', 'r') do |f|
      f.each_line do |line|
        line.strip!
        if line.start_with?('vertex')
          coords = line.split[1..3].map(&:to_f)
          vertices << coords
        end
      end
    end
    
    # Look specifically for text vertices
    text_vertices = vertices.select do |x, y, z|
      r = Math.sqrt(x*x + y*y)
      r > 22 && r < 28 && z > 1 && z < 3  # Expected text range
    end
    
    puts "Found #{text_vertices.length} potential text vertices"
    
    if text_vertices.length > 10
      puts "Sample text vertices (showing position and angle):"
      text_vertices.first(20).each_with_index do |vertex, i|
        x, y, z = vertex
        r = Math.sqrt(x*x + y*y)
        angle = Math.atan2(y, x) * 180 / Math::PI
        puts "#{(i+1).to_s.rjust(2)}: (#{x.round(2).to_s.rjust(6)}, #{y.round(2).to_s.rjust(6)}, #{z.round(2)}) r=#{r.round(2)} θ=#{angle.round(1)}°"
      end
      
      # Check for character-like clustering
      angles = text_vertices.map { |x, y, z| Math.atan2(y, x) * 180 / Math::PI }
      angles.sort!
      
      puts "\nAngle distribution analysis:"
      puts "Min angle: #{angles.first.round(1)}°"
      puts "Max angle: #{angles.last.round(1)}°"
      puts "Spread: #{(angles.last - angles.first).round(1)}°"
      
      # Look for gaps that might indicate character spacing
      gaps = []
      (1...angles.length).each do |i|
        gap = angles[i] - angles[i-1]
        gaps << gap if gap > 1  # Significant gaps
      end
      
      if gaps.length > 0
        puts "Character gaps found: #{gaps.map{|g| g.round(1)}.join(', ')}°"
        puts "Average character spacing: #{(gaps.sum / gaps.length).round(1)}°"
      end
    else
      puts "❌ Very few text vertices found - text generation may be failing"
    end
  end
end

# Run visualization
if ARGV.length > 0
  ARGV.each { |filename| visualize_stl(filename) }
else
  create_simple_test_visualization
end

