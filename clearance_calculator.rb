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
  tight = optimal * 0.5
  snug = optimal * 0.75
  loose = optimal * 1.5
  
  puts "Clearances for #{diameter}mm diameter dust collection adapter:"
  puts "  Tight fit:   #{sprintf('%.2f', tight)}mm clearance"
  puts "  Snug fit:    #{sprintf('%.2f', snug)}mm clearance" 
  puts "  Optimal fit: #{sprintf('%.2f', optimal)}mm clearance"
  puts "  Loose fit:   #{sprintf('%.2f', loose)}mm clearance"
  puts
  puts "For outer adapter: make rings with inner diameters #{diameter + tight}mm, #{diameter + snug}mm, #{diameter + optimal}mm, #{diameter + loose}mm"
  puts "For inner adapter: make rings with outer diameters #{diameter - tight}mm, #{diameter - snug}mm, #{diameter - optimal}mm, #{diameter - loose}mm"
end
