#!/usr/bin/env ruby
# ring_band_stl.rb
# Generates an ASCII STL for a circular band (ring).
# Units: millimeters.

require 'optparse'

# ---------- Math helpers ----------
def vsub(a,b) [a[0]-b[0], a[1]-b[1], a[2]-b[2]] end
def vcross(a,b) [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]] end
def vnorm(a)
  mag = Math.sqrt(a[0]*a[0] + a[1]*a[1] + a[2]*a[2])
  return [0.0,0.0,0.0] if mag == 0.0
  [a[0]/mag, a[1]/mag, a[2]/mag]
end

def add_tri(facets, a, b, c)
  n = vnorm(vcross(vsub(b, a), vsub(c, a)))
  facets << [n, a, b, c]
end

def write_ascii_stl(path, name, facets)
  File.open(path, 'w') do |f|
    f.puts "solid #{name}"
    facets.each do |n, a, b, c|
      f.puts "  facet normal #{n[0]} #{n[1]} #{n[2]}"
      f.puts "    outer loop"
      f.puts "      vertex #{a[0]} #{a[1]} #{a[2]}"
      f.puts "      vertex #{b[0]} #{b[1]} #{b[2]}"
      f.puts "      vertex #{c[0]} #{c[1]} #{c[2]}"
      f.puts "    endloop"
      f.puts "  endfacet"
    end
    f.puts "endsolid #{name}"
  end
end

# ---------- Text Generation ----------
def create_char_facets(char, x_offset, y_offset, z_offset, scale, extrude_depth)
  # Simple block letter/digit patterns using rectangles
  facets = []
  
  # Define each character as a set of rectangles [x1, y1, x2, y2] normalized to 1x1 square
  patterns = {
    '0' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.8, 1.0, 1.0], [0.0, 0.2, 0.2, 0.8], [0.8, 0.2, 1.0, 0.8]],
    '1' => [[0.4, 0.0, 0.6, 1.0]],
    '2' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.0, 0.6, 0.2, 0.8], [0.8, 0.2, 1.0, 0.4]],
    '3' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.8, 0.2, 1.0, 0.4], [0.8, 0.6, 1.0, 0.8]],
    '4' => [[0.0, 0.4, 1.0, 0.6], [0.0, 0.6, 0.2, 1.0], [0.8, 0.0, 1.0, 1.0]],
    '5' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.0, 0.6, 0.2, 0.8], [0.8, 0.2, 1.0, 0.4]],
    '6' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.0, 0.2, 0.2, 0.8], [0.8, 0.2, 1.0, 0.4]],
    '7' => [[0.0, 0.8, 1.0, 1.0], [0.8, 0.0, 1.0, 0.8]],
    '8' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.0, 0.2, 0.2, 0.4], [0.0, 0.6, 0.2, 0.8], [0.8, 0.2, 1.0, 0.4], [0.8, 0.6, 1.0, 0.8]],
    '9' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.0, 0.6, 0.2, 0.8], [0.8, 0.2, 1.0, 0.8]],
    # Simple block letters
    'I' => [[0.4, 0.0, 0.6, 1.0]],  # Just a vertical line
    'D' => [[0.0, 0.0, 0.8, 0.2], [0.0, 0.8, 0.8, 1.0], [0.0, 0.2, 0.2, 0.8], [0.8, 0.2, 1.0, 0.8]],  # Like 0 but open on right
    'O' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.8, 1.0, 1.0], [0.0, 0.2, 0.2, 0.8], [0.8, 0.2, 1.0, 0.8]],  # Same as 0
    'M' => [[0.0, 0.0, 0.2, 1.0], [0.8, 0.0, 1.0, 1.0], [0.2, 0.8, 0.4, 1.0], [0.6, 0.8, 0.8, 1.0]],  # Two verticals with top connections
    'm' => [[0.0, 0.0, 0.2, 1.0], [0.4, 0.0, 0.6, 1.0], [0.8, 0.0, 1.0, 1.0], [0.0, 0.8, 1.0, 1.0]],  # Lowercase m - three full verticals with top bar
    ' ' => []  # Space - no rectangles
  }
  
  return facets unless patterns[char]
  
  patterns[char].each do |rect|
    x1, y1, x2, y2 = rect
    
    # Create extruded rectangle
    points_bottom = [
      [x_offset + x1 * scale, y_offset + y1 * scale, z_offset],
      [x_offset + x2 * scale, y_offset + y1 * scale, z_offset],
      [x_offset + x2 * scale, y_offset + y2 * scale, z_offset],
      [x_offset + x1 * scale, y_offset + y2 * scale, z_offset]
    ]
    points_top = [
      [x_offset + x1 * scale, y_offset + y1 * scale, z_offset + extrude_depth],
      [x_offset + x2 * scale, y_offset + y1 * scale, z_offset + extrude_depth],
      [x_offset + x2 * scale, y_offset + y2 * scale, z_offset + extrude_depth],
      [x_offset + x1 * scale, y_offset + y2 * scale, z_offset + extrude_depth]
    ]
    
    # Create faces for the extruded rectangle
    # Bottom face
    add_tri(facets, points_bottom[0], points_bottom[2], points_bottom[1])
    add_tri(facets, points_bottom[0], points_bottom[3], points_bottom[2])
    
    # Top face
    add_tri(facets, points_top[0], points_top[1], points_top[2])
    add_tri(facets, points_top[0], points_top[2], points_top[3])
    
    # Side faces
    4.times do |i|
      i2 = (i + 1) % 4
      add_tri(facets, points_bottom[i], points_bottom[i2], points_top[i2])
      add_tri(facets, points_bottom[i], points_top[i2], points_top[i])
    end
  end
  
  facets
end

def create_text_facets(text, x_center, y_center, z_offset, scale, extrude_depth)
  facets = []
  char_width = scale * 1.2  # Space between characters
  
  # Count all characters for width calculation
  char_count = text.length
  total_width = char_count * char_width
  start_x = x_center - total_width / 2.0
  
  text.each_char.with_index do |char, i|
    x_pos = start_x + i * char_width
    char_facets = create_char_facets(char, x_pos, y_center - scale/2, z_offset, scale, extrude_depth)
    facets.concat(char_facets)
  end
  
  facets
end

def create_circular_text(text, r_in, r_out, ring_height, text_on_inside)
  facets = []
  
  return facets unless text_on_inside  # Only do inner text for now
  
  # Text will be embossed on the inner cylindrical wall
  # Text should be readable when looking down into the ring
  
  # Text dimensions
  text_height = ring_height * 0.6  # Height of text (60% of ring height)
  text_depth = (r_out - r_in) * 0.3  # How deep the text extrudes into the wall
  char_width = text_height * 0.8   # Width of each character
  
  # Calculate angular spacing
  circumference = 2 * Math::PI * r_in
  total_text_width = text.length * char_width * 1.5  # Include spacing
  text_arc_angle = total_text_width / r_in  # Total angle for text
  
  # Limit text to reasonable arc
  if text_arc_angle > Math::PI * 0.8  # Max 144 degrees
    text_arc_angle = Math::PI * 0.8
    char_width = text_arc_angle * r_in / (text.length * 1.5)
  end
  
  angle_per_char = text_arc_angle / text.length
  start_angle = -text_arc_angle / 2.0  # Center the text at bottom of ring
  
  # Position text vertically (bottom of text near bottom of ring)
  text_bottom_z = ring_height * 0.2
  text_top_z = text_bottom_z + text_height
  
  text.each_char.with_index do |char, i|
    char_angle = start_angle + i * angle_per_char
    
    # Create text that's embossed into the inner wall
    char_facets = create_wall_text_char(
      char, 
      r_in, 
      char_angle, 
      text_bottom_z, 
      text_top_z, 
      char_width, 
      text_depth
    )
    facets.concat(char_facets)
  end
  
  facets
end

def create_wall_text_char(char, inner_radius, center_angle, bottom_z, top_z, char_width, extrude_depth)
  facets = []
  
  # Get character pattern
  patterns = get_char_patterns
  return facets unless patterns[char]
  
  # Convert character width to angular width
  angular_width = char_width / inner_radius
  half_angular_width = angular_width / 2.0
  
  patterns[char].each do |rect|
    x1_norm, y1_norm, x2_norm, y2_norm = rect
    
    # Convert normalized coordinates to angular and Z coordinates
    angle1 = center_angle - half_angular_width + (x1_norm * angular_width)
    angle2 = center_angle - half_angular_width + (x2_norm * angular_width)
    z1 = bottom_z + (y1_norm * (top_z - bottom_z))
    z2 = bottom_z + (y2_norm * (top_z - bottom_z))
    
    # Create extruded rectangle on the cylindrical surface
    # Outer surface (at inner_radius)
    outer_p1 = [inner_radius * Math.cos(angle1), inner_radius * Math.sin(angle1), z1]
    outer_p2 = [inner_radius * Math.cos(angle2), inner_radius * Math.sin(angle2), z1]
    outer_p3 = [inner_radius * Math.cos(angle2), inner_radius * Math.sin(angle2), z2]
    outer_p4 = [inner_radius * Math.cos(angle1), inner_radius * Math.sin(angle1), z2]
    
    # Inner surface (extruded inward)
    inner_r = inner_radius - extrude_depth
    inner_p1 = [inner_r * Math.cos(angle1), inner_r * Math.sin(angle1), z1]
    inner_p2 = [inner_r * Math.cos(angle2), inner_r * Math.sin(angle2), z1]
    inner_p3 = [inner_r * Math.cos(angle2), inner_r * Math.sin(angle2), z2]
    inner_p4 = [inner_r * Math.cos(angle1), inner_r * Math.sin(angle1), z2]
    
    # Create faces for the extruded rectangle
    # Bottom face (z1)
    add_tri(facets, outer_p1, inner_p2, inner_p1)
    add_tri(facets, outer_p1, outer_p2, inner_p2)
    
    # Top face (z2)
    add_tri(facets, outer_p4, inner_p3, outer_p3)
    add_tri(facets, outer_p4, inner_p4, inner_p3)
    
    # Inner face (recessed surface)
    add_tri(facets, inner_p1, inner_p3, inner_p4)
    add_tri(facets, inner_p1, inner_p2, inner_p3)
    
    # Side faces
    add_tri(facets, outer_p1, inner_p1, inner_p4)
    add_tri(facets, outer_p1, inner_p4, outer_p4)
    
    add_tri(facets, outer_p2, inner_p3, inner_p2)
    add_tri(facets, outer_p2, outer_p3, inner_p3)
  end
  
  facets
end

def get_char_patterns
  # Same character patterns but organized as a separate method
  {
    '0' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.8, 1.0, 1.0], [0.0, 0.2, 0.2, 0.8], [0.8, 0.2, 1.0, 0.8]],
    '1' => [[0.4, 0.0, 0.6, 1.0]],
    '2' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.0, 0.6, 0.2, 0.8], [0.8, 0.2, 1.0, 0.4]],
    '3' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.8, 0.2, 1.0, 0.4], [0.8, 0.6, 1.0, 0.8]],
    '4' => [[0.0, 0.4, 1.0, 0.6], [0.0, 0.6, 0.2, 1.0], [0.8, 0.0, 1.0, 1.0]],
    '5' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.0, 0.6, 0.2, 0.8], [0.8, 0.2, 1.0, 0.4]],
    '6' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.0, 0.2, 0.2, 0.8], [0.8, 0.2, 1.0, 0.4]],
    '7' => [[0.0, 0.8, 1.0, 1.0], [0.8, 0.0, 1.0, 0.8]],
    '8' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.0, 0.2, 0.2, 0.4], [0.0, 0.6, 0.2, 0.8], [0.8, 0.2, 1.0, 0.4], [0.8, 0.6, 1.0, 0.8]],
    '9' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.4, 1.0, 0.6], [0.0, 0.8, 1.0, 1.0], [0.0, 0.6, 0.2, 0.8], [0.8, 0.2, 1.0, 0.8]],
    'I' => [[0.4, 0.0, 0.6, 1.0]],
    'D' => [[0.0, 0.0, 0.8, 0.2], [0.0, 0.8, 0.8, 1.0], [0.0, 0.2, 0.2, 0.8], [0.8, 0.2, 1.0, 0.8]],
    'O' => [[0.0, 0.0, 1.0, 0.2], [0.0, 0.8, 1.0, 1.0], [0.0, 0.2, 0.2, 0.8], [0.8, 0.2, 1.0, 0.8]],
    'M' => [[0.0, 0.0, 0.2, 1.0], [0.8, 0.0, 1.0, 1.0], [0.2, 0.8, 0.4, 1.0], [0.6, 0.8, 0.8, 1.0]],
    'm' => [[0.0, 0.0, 0.2, 1.0], [0.4, 0.0, 0.6, 1.0], [0.8, 0.0, 1.0, 1.0], [0.0, 0.8, 1.0, 1.0]],
    ' ' => []
  }
end

def create_rotated_char(char, x_center, y_center, z_offset, scale, extrude_depth, rotation_angle)
  # Get the basic character pattern
  base_facets = create_char_facets(char, 0, 0, z_offset, scale, extrude_depth)
  
  # Apply rotation and translation to each facet
  rotated_facets = []
  cos_r = Math.cos(rotation_angle)
  sin_r = Math.sin(rotation_angle)
  
  base_facets.each do |normal, p1, p2, p3|
    # Rotate and translate each point
    new_p1 = rotate_and_translate_point(p1, cos_r, sin_r, x_center, y_center)
    new_p2 = rotate_and_translate_point(p2, cos_r, sin_r, x_center, y_center)
    new_p3 = rotate_and_translate_point(p3, cos_r, sin_r, x_center, y_center)
    
    # Recalculate normal after rotation
    new_normal = vnorm(vcross(vsub(new_p2, new_p1), vsub(new_p3, new_p1)))
    
    rotated_facets << [new_normal, new_p1, new_p2, new_p3]
  end
  
  rotated_facets
end

def rotate_and_translate_point(point, cos_r, sin_r, tx, ty)
  x, y, z = point
  # Apply 2D rotation around Z axis, then translate
  new_x = x * cos_r - y * sin_r + tx
  new_y = x * sin_r + y * cos_r + ty
  [new_x, new_y, z]
end

def create_text_tab(text, ring_radius, ring_height, text_on_inside)
  facets = []
  
  # Tab dimensions
  tab_width = ring_radius * 0.8   # Width of the tab
  tab_height = 4.0                # Fixed height of 4mm
  tab_thickness = ring_radius * 0.15  # Thickness extending outward
  
  # Position tab at the bottom of the ring (negative Y direction)
  tab_center_x = 0.0
  tab_center_y = -(ring_radius + tab_thickness / 2.0)  # Extend outward from ring
  
  # Tab corners (bottom face at z=0, top face at z=tab_height)
  half_width = tab_width / 2.0
  half_thick = tab_thickness / 2.0
  
  # Define the 8 corners of the rectangular tab
  corners = [
    # Bottom face (z=0)
    [tab_center_x - half_width, tab_center_y - half_thick, 0.0],  # 0: bottom-left-back
    [tab_center_x + half_width, tab_center_y - half_thick, 0.0],  # 1: bottom-right-back
    [tab_center_x + half_width, tab_center_y + half_thick, 0.0],  # 2: bottom-right-front
    [tab_center_x - half_width, tab_center_y + half_thick, 0.0],  # 3: bottom-left-front
    # Top face (z=tab_height)
    [tab_center_x - half_width, tab_center_y - half_thick, tab_height],  # 4: top-left-back
    [tab_center_x + half_width, tab_center_y - half_thick, tab_height],  # 5: top-right-back
    [tab_center_x + half_width, tab_center_y + half_thick, tab_height],  # 6: top-right-front
    [tab_center_x - half_width, tab_center_y + half_thick, tab_height],  # 7: top-left-front
  ]
  
  # Create faces for the rectangular tab
  # Bottom face (z=0, normal pointing down)
  add_tri(facets, corners[0], corners[2], corners[1])
  add_tri(facets, corners[0], corners[3], corners[2])
  
  # Top face (z=tab_height, normal pointing up)
  add_tri(facets, corners[4], corners[5], corners[6])
  add_tri(facets, corners[4], corners[6], corners[7])
  
  # Side faces
  # Front face (toward ring center, positive Y direction)
  add_tri(facets, corners[3], corners[6], corners[7])
  add_tri(facets, corners[3], corners[2], corners[6])
  
  # Back face (away from ring center, negative Y direction)
  add_tri(facets, corners[0], corners[4], corners[5])
  add_tri(facets, corners[0], corners[5], corners[1])
  
  # Left face (negative X direction)
  add_tri(facets, corners[0], corners[7], corners[4])
  add_tri(facets, corners[0], corners[3], corners[7])
  
  # Right face (positive X direction)
  add_tri(facets, corners[1], corners[5], corners[6])
  add_tri(facets, corners[1], corners[6], corners[2])
  
  # Add text on the top face of the tab
  text_scale = [tab_width, tab_height].min * 0.25  # Larger scale text to fit on tab (increased from 0.15)
  text_height = 0.8  # Larger extrusion height for text (increased from 0.3)
  text_x = tab_center_x
  text_y = tab_center_y
  text_z = tab_height  # On top of the tab
  
  text_facets = create_text_facets(text, text_x, text_y, text_z, text_scale, text_height)
  facets.concat(text_facets)
  
  facets
end

# ---------- Geometry ----------
def ring_facets(r_in:, r_out:, height:, segments:, diameter_text: nil, text_on_inside: true)
  raise "r_out must be > r_in" unless r_out > r_in && r_in >= 0.0
  raise "height must be > 0" unless height > 0.0
  raise "segments must be >= 16" unless segments >= 16

  facets = []
  two_pi = 2.0 * Math::PI
  hz0 = 0.0
  hz1 = height

  # Precompute rings
  cos = []
  sin = []
  (0..segments).each do |i|
    a = two_pi * i / segments.to_f
    cos << Math.cos(a)
    sin << Math.sin(a)
  end

  # For each segment, make quads (two triangles per quad)
  segments.times do |i|
    i2 = i + 1

    ob0 = [r_out * cos[i],  r_out * sin[i],  hz0]
    ob1 = [r_out * cos[i2], r_out * sin[i2], hz0]
    ot0 = [r_out * cos[i],  r_out * sin[i],  hz1]
    ot1 = [r_out * cos[i2], r_out * sin[i2], hz1]

    ib0 = [r_in * cos[i],  r_in * sin[i],  hz0]
    ib1 = [r_in * cos[i2], r_in * sin[i2], hz0]
    it0 = [r_in * cos[i],  r_in * sin[i],  hz1]
    it1 = [r_in * cos[i2], r_in * sin[i2], hz1]

    # --- Outer wall (normal points outward) ---
    add_tri(facets, ob0, ob1, ot1)
    add_tri(facets, ob0, ot1, ot0)

    # --- Inner wall (normal should point toward the hole center = inward).
    # Wind triangles the opposite way to flip normals.
    add_tri(facets, ib1, ib0, it0)
    add_tri(facets, it1, ib1, it0)

    # --- Top face (z = height, normal +Z) ---
    # CCW seen from above: outer ring -> inner ring
    add_tri(facets, ot0, ot1, it1)
    add_tri(facets, ot0, it1, it0)

    # --- Bottom face (z = 0, normal -Z) ---
    # CW seen from above to get normal -Z
    add_tri(facets, ob1, ob0, ib0)
    add_tri(facets, ib1, ob1, ib0)
  end

  # Add diameter text along the ring circumference if specified
  if diameter_text
    circular_text_facets = create_circular_text(diameter_text, r_in, r_out, height, text_on_inside)
    facets.concat(circular_text_facets)
  end

  facets
end

# ---------- CLI ----------
options = {
  id: nil,    # inside diameter
  ow: nil,    # outside diameter/width
  t:  nil,    # thickness (radial)
  h:  2.0,    # height
  seg: 128,
  out: nil
}

parser = OptionParser.new do |o|
  o.banner = "Usage: ruby ring_band_stl.rb [options]\n" \
             "Creates a circular band STL (default height 2mm)."

  o.on("--id ID_MM", Float, "Inside diameter in mm") { |v| options[:id] = v }
  o.on("--ow OW_MM", Float, "Outside width/diameter in mm") { |v| options[:ow] = v }
  o.on("--t T_MM", Float, "Thickness (radial) in mm (required)") { |v| options[:t] = v }
  o.on("--h H_MM", Float, "Height in mm (default 2.0)") { |v| options[:h] = v }
  o.on("--segments N", Integer, "Circle resolution (default 128)") { |v| options[:seg] = v }
  o.on("-o", "--out FILE", String, "Output .stl path (optional)") { |v| options[:out] = v }
  o.on("-h", "--help", "Show help") { puts o; exit }
end

begin
  parser.parse!
rescue OptionParser::ParseError => e
  warn e.message
  warn parser
  exit 1
end

if options[:t].nil? || options[:t] <= 0
  warn "Error: --t (thickness) is required and must be > 0"
  warn parser
  exit 1
end

mode_id = !options[:id].nil?
mode_ow = !options[:ow].nil?
if mode_id == mode_ow
  warn "Error: specify exactly one of --id or --ow"
  warn parser
  exit 1
end

r_in, r_out = nil, nil
t = options[:t].to_f

if mode_id
  id = options[:id].to_f
  raise "Inside diameter must be > 0" unless id > 0
  r_in = id / 2.0
  r_out = r_in + t
else
  ow = options[:ow].to_f
  raise "Outside width must be > 0" unless ow > 0
  r_out = ow / 2.0
  r_in  = r_out - t
  raise "Thickness too large: r_in <= 0" unless r_in > 0
end

height   = options[:h].to_f
segments = options[:seg].to_i

name = if mode_id
  "ring_id#{format('%.3f', options[:id])}_t#{format('%.3f', t)}_h#{format('%.3f', height)}"
else
  "ring_ow#{format('%.3f', options[:ow])}_t#{format('%.3f', t)}_h#{format('%.3f', height)}"
end

outfile = options[:out] || "#{name}.stl"

# Prepare diameter text
diameter_text = nil
text_on_inside = true

if mode_id
  diameter_text = "ID#{options[:id].to_i}MM"
  text_on_inside = true  # Inside diameter goes on the inside
else
  diameter_text = "OD#{options[:ow].to_i}MM"
  text_on_inside = false  # Outside diameter goes on the outside
end

begin
  facets = ring_facets(r_in: r_in, r_out: r_out, height: height, segments: segments, 
                       diameter_text: diameter_text, text_on_inside: text_on_inside)
  write_ascii_stl(outfile, name, facets)
  puts "Wrote #{outfile}"
  puts "  r_in = #{r_in} mm, r_out = #{r_out} mm, height = #{height} mm, segments = #{segments}"
  puts "  Text: '#{diameter_text}' positioned on #{text_on_inside ? 'inside' : 'outside'}"
rescue => e
  warn "Failed: #{e.message}"
  exit 1
end
