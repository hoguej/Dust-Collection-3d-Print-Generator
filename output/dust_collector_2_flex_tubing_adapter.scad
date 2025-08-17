// Tapered dust collection adapter
// Side 1: 55.0mm inner / 59.0mm outer
// Side 2: 101.1mm inner / 105.1mm outer

side1_inner = 55.0;
side1_outer = 59.0;
side2_inner = 101.1;
side2_outer = 105.1;

side1_length = 50.8;  // 2 inches
transition_length = 25.4;  // 1 inch
side2_length = 50.8;  // 2 inches
total_length = 126.99999999999999;  // 5 inches total

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
