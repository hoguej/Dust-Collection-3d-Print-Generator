// Generated ring with curved text
inner_diameter = 59.4;
thickness = 2.0;
height = 20.0;
text_content = "I59.4mm";
font_size = 5.0;
text_depth = 2.0;
text_on_inner = true;

// Calculated values
outer_diameter = inner_diameter + (thickness * 2);
inner_radius = inner_diameter / 2;
outer_radius = outer_diameter / 2;

module ring_with_text() {
    difference() {
        // Main ring
        cylinder(h=height, r=outer_radius, $fn=128);
        
        // Inner hole
        cylinder(h=height+1, r=inner_radius, $fn=128);
        
        // Text cutout - always on outer surface for better STL readability
        translate([0, 0, height/2])
        rotate([0, 0, 180]) // Position text at bottom of ring
        curved_text_outer(text_content, outer_radius, font_size, text_depth);
    }
}

module curved_text_inner(text, radius, size, depth) {
    // Calculate spacing for each character
    text_length = len(text);
    // More generous character spacing
    char_width = size * 1.2; // Good spacing for readability
    total_arc_length = text_length * char_width;
    
    // Convert to angle (radians)
    total_angle = total_arc_length / radius;
    angle_per_char = total_angle / text_length;
    
    // Center the text
    start_angle = -total_angle / 2;
    
    for (i = [0 : text_length - 1]) {
        char = text[i];
        angle = start_angle - i * angle_per_char; // Subtract to reverse order for inner
        
        // Skip spaces - don't render them but keep the spacing
        if (char != " ") {
            rotate([0, 0, angle * 180 / PI])
            translate([0, -radius + depth/2, 0])
            rotate([90, 0, 0])
            mirror([1, 0, 0]) // Mirror text so it reads correctly from inside
            linear_extrude(height=depth, center=true)
            text(char, size=size, halign="center", valign="center");
        }
    }
}

module curved_text_outer(text, radius, size, depth) {
    // Calculate spacing for each character
    text_length = len(text);
    // More generous character spacing
    char_width = size * 1.2; // Good spacing for readability
    total_arc_length = text_length * char_width;
    
    // Convert to angle (radians)
    total_angle = total_arc_length / radius;
    angle_per_char = total_angle / text_length;
    
    // Center the text
    start_angle = -total_angle / 2;
    
    for (i = [0 : text_length - 1]) {
        char = text[i];
        angle = start_angle + i * angle_per_char; // Add for normal order on outer
        
        // Skip spaces - don't render them but keep the spacing
        if (char != " ") {
            rotate([0, 0, angle * 180 / PI])
            translate([0, radius - depth/2, 0]) // Position on outer surface
            rotate([90, 0, 180]) // Rotate for outer surface text orientation
            // No mirror needed for outer text - it was causing horizontal mirroring
            linear_extrude(height=depth, center=true)
            text(char, size=size, halign="center", valign="center");
        }
    }
}

// Generate the ring
ring_with_text();
