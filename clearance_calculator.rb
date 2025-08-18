#!/usr/bin/env ruby
# clearance_calculator.rb - Calculate optimal clearances for dust collection adapters

require_relative 'lib/ring_generator'

def show_clearance_table
  puts "=== DUST COLLECTION ADAPTER CLEARANCE CALCULATOR ==="
  puts "Based on empirical data: 45.8mm→0.6mm, 101mm→0.1mm clearance"
  puts "Formula: clearance = 3476.1064 * diameter^-2.266"
  puts
  
  # Common dust collection sizes
  sizes = [25, 32, 38, 50, 63, 76, 100, 125, 150]
  
  puts "Common Dust Collection Diameters:"
  puts "Diameter  | Optimal | Tight | Snug  | Loose"
  puts "----------|---------|-------|-------|-------"
  
  sizes.each do |diameter|
    optimal = RingGenerator.calculate_dust_collection_clearance(diameter)
    tight = optimal * 0.5
    snug = optimal * 0.75  
    loose = optimal * 1.5
    
    printf "%6dmm   | %5.2fmm | %4.2fmm | %4.2fmm | %4.2fmm\n", 
           diameter, optimal, tight, snug, loose
  end
  
  puts
  puts "Usage examples:"
  puts "  ruby clearance_calculator.rb 101    # Show clearances for 101mm"
  puts "  ruby make_test_fit_kit.rb -o 101    # Generate test kit with calculated clearances"
end

if ARGV.empty?
  show_clearance_table
else
  diameter = ARGV[0].to_f
  if diameter <= 0
    puts "Error: Please provide a positive diameter in mm"
    exit 1
  end
  
  optimal = RingGenerator.calculate_dust_collection_clearance(diameter)
  
  # Calculate step size (use optimal/4 to create reasonable steps around optimal)
  step = sprintf('%.2f', optimal / 4.0).to_f
  
  puts "Clearances for #{diameter}mm diameter dust collection adapter:"
  puts "  Optimal clearance: #{sprintf('%.2f', optimal)}mm"
  puts "  Step size: #{sprintf('%.2f', step)}mm (optimal ÷ 4)"
  puts "  Test range: optimal-2steps to optimal+2steps"
  puts
  
  puts "🎯 Recommended create_rings.rb commands:"
  puts
  puts "If #{diameter}mm is an OUTER diameter measurement:"
  # Start at optimal clearance, then step down by 2*step to get the starting point
  optimal_diameter = diameter + optimal
  start_diameter = optimal_diameter - (2 * step)
  puts "  ruby create_rings.rb -o #{sprintf('%.2f', start_diameter)} --up --step #{sprintf('%.2f', step)} --count 5 -f test_#{sprintf('%.1f', diameter)}mm_outer"
  puts "  Creates 5 rings with outer diameters:"
  puts "    Ring 1: #{sprintf('%.2f', start_diameter)}mm (optimal-2steps)"
  puts "    Ring 2: #{sprintf('%.2f', start_diameter + step)}mm (optimal-1step)"
  puts "    Ring 3: #{sprintf('%.2f', start_diameter + (2*step))}mm (OPTIMAL)"
  puts "    Ring 4: #{sprintf('%.2f', start_diameter + (3*step))}mm (optimal+1step)"
  puts "    Ring 5: #{sprintf('%.2f', start_diameter + (4*step))}mm (optimal+2steps)"
  puts
  puts "If #{diameter}mm is an INNER diameter measurement:"
  # Start at optimal clearance, then step up by 2*step to get the starting point  
  optimal_diameter = diameter - optimal
  start_diameter = optimal_diameter + (2 * step)
  puts "  ruby create_rings.rb -i #{sprintf('%.2f', start_diameter)} --down --step #{sprintf('%.2f', step)} --count 5 -f test_#{sprintf('%.1f', diameter)}mm_inner"
  puts "  Creates 5 rings with inner diameters:"
  puts "    Ring 1: #{sprintf('%.2f', start_diameter)}mm (optimal-2steps)"
  puts "    Ring 2: #{sprintf('%.2f', start_diameter - step)}mm (optimal-1step)"
  puts "    Ring 3: #{sprintf('%.2f', start_diameter - (2*step))}mm (OPTIMAL)"
  puts "    Ring 4: #{sprintf('%.2f', start_diameter - (3*step))}mm (optimal+1step)"
  puts "    Ring 5: #{sprintf('%.2f', start_diameter - (4*step))}mm (optimal+2steps)"
end
