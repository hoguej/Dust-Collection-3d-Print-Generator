# Dust Collection 3D Print Generator

A comprehensive Ruby-based toolkit for generating 3D printable dust collection adapters, rings, and test fit kits. This toolkit uses OpenSCAD to create precise, customizable parts for woodworking and shop dust collection systems.

## 🚀 Features

- **Smart Clearance Calculation**: Uses empirical data to calculate optimal clearances based on diameter
- **Multiple Ring Types**: Single rings, adapter pairs, test fit kits, and tapered adapters
- **3D Text Integration**: Automatic diameter labeling with curved text on rings
- **Flexible Output**: Generate OpenSCAD files for editing or STL files ready for 3D printing
- **Batch Generation**: Create multiple test rings with different clearances simultaneously

## 📋 Prerequisites

### Required Software

1. **Ruby** (version 2.7 or higher)
   ```bash
   # Check if Ruby is installed
   ruby --version
   
   # Install Ruby if needed (macOS with Homebrew)
   brew install ruby
   
   # Or use rbenv for version management
   rbenv install 3.4.3
   rbenv global 3.4.3
   ```

2. **OpenSCAD** (for STL generation)
   - Download from [OpenSCAD.org](https://openscad.org/downloads.html)
   - **macOS**: Install to `/Applications/OpenSCAD.app`
   - **Important**: You need to set up an alias for the command line

### macOS Setup (Required)

Add this alias to your `~/.zshrc` or `~/.bash_profile`:

```bash
# Add OpenSCAD command line alias (adjust version as needed)
alias openscad="/Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD"

# Optional: Alias to open OpenSCAD GUI
alias oc="open -a /Applications/OpenSCAD-2021.01.app"
```

After adding the alias, reload your shell:
```bash
source ~/.zshrc  # or ~/.bash_profile
```

Test the setup:
```bash
openscad --version
```

## 🛠️ Installation

1. **Clone or download this repository**
   ```bash
   git clone https://github.com/hoguej/Dust-Collection-3d-Print-Generator.git
   cd Dust-Collection-3d-Print-Generator
   ```

2. **Verify the setup**
   ```bash
   # Test Ruby
   ruby --version
   
   # Test OpenSCAD
   openscad --version
   
   # Run a quick test
   ruby clearance_calculator.rb
   ```

## 📚 Scripts Overview

### 1. `ring_maker.rb` - Single Ring Generator
Creates individual rings with embossed diameter text.

**Usage:**
```bash
ruby ring_maker.rb -i 30          # 30mm inner diameter ring
ruby ring_maker.rb -o 55          # 55mm outer diameter ring
ruby ring_maker.rb -i 30 --stl    # Generate both SCAD and STL files
```

**Options:**
- `-i, --inner DIAMETER` - Inner diameter in mm
- `-o, --outer DIAMETER` - Outer diameter in mm  
- `--t THICKNESS` - Wall thickness in mm (default: 2.0)
- `--h HEIGHT` - Height in mm (default: 20.0)
- `--stl` - Generate STL file (also creates SCAD)
- `-f, --file FILE` - Custom output filename

### 2. `make_test_fit_kit.rb` - Test Fit Kit Generator
Creates a set of 5 rings: 1 replica + 4 test rings with different clearances.

**Usage:**
```bash
ruby make_test_fit_kit.rb -o 101        # Test kit for 101mm outer diameter
ruby make_test_fit_kit.rb -i 64 --stl   # Individual STL files for 64mm inner
```

**What it creates:**
- **Replica ring**: Exact copy of your measured part
- **4 test rings**: Tight, snug, optimal, and loose fits
- **Smart layout**: Cross pattern for easy 3D printing
- **Individual files**: With `--stl`, creates separate files for each ring

### 3. `make_adapter_pair.rb` - Adapter Pair Generator  
Creates a replica and its matching adapter (2 rings total).

**Usage:**
```bash
ruby make_adapter_pair.rb -o 101        # Adapter that fits over 101mm part
ruby make_adapter_pair.rb -i 64 --stl   # Adapter that fits inside 64mm part
```

### 4. `create_adapter.rb` - Tapered Adapter Generator
Creates tapered adapters connecting two different diameters.

**Usage:**
```bash
# Connect 4" duct (101mm outer) to 2.5" hose (63mm inner)
ruby create_adapter.rb --o1 101 --i2 63 --stl

# Connect different sizes
ruby create_adapter.rb --i1 50 --o2 76 --stl
```

**Structure:** 2" of side1 + 1" transition + 2" of side2 (5" total length)

### 5. `clearance_calculator.rb` - Clearance Reference
Shows optimal clearances for different diameters.

**Usage:**
```bash
ruby clearance_calculator.rb           # Show full table
ruby clearance_calculator.rb 101       # Clearances for 101mm diameter
```

## 💡 Quick Start Examples

### Example 1: Simple Ring
```bash
# Create a ring for a 4" dust port (101.6mm outer diameter)
ruby ring_maker.rb -o 101.6

# Output: Creates output/ring_od101.6_t2.0_h20.0.scad
```

### Example 2: Test Different Fits
```bash
# You measured a table saw port at 64mm inner diameter
# Create a test kit to find the perfect adapter size
ruby make_test_fit_kit.rb -i 64 --stl

# Output: Creates individual STL files for:
# - Replica of your 64mm port
# - 4 test adapters with calculated clearances
```

### Example 3: Connect Two Different Sizes
```bash
# Connect 4" main duct to 2.5" tool hose
ruby create_adapter.rb --o1 101.6 --i2 63.5 --stl

# Output: Creates a tapered adapter STL file
```

### Example 4: Perfect Fit Adapter
```bash
# You have a 101mm outer diameter dust port
# Create a replica and perfectly fitting adapter
ruby make_adapter_pair.rb -o 101 --stl

# Output: Creates 2 rings - replica + adapter that slides over it
```

## 📁 Output Files

All files are created in the `output/` directory:

- **`.scad` files**: Editable in OpenSCAD, perfect for customization
- **`.stl` files**: Ready for 3D printing
- **Subdirectories**: Complex generators create organized folder structures

## 🎯 Understanding Clearances

The toolkit uses a scientifically-derived formula based on real-world testing:

- **Larger diameters** = **smaller clearances** needed
- **101mm diameter** → **0.1mm clearance** (tight fit)
- **45mm diameter** → **0.6mm clearance** (loose fit)

### Fit Types:
- **Tight (50% of optimal)**: Press fit, permanent connection
- **Snug (75% of optimal)**: Firm fit, removable with effort  
- **Optimal (100%)**: Perfect balance of fit and removability
- **Loose (150% of optimal)**: Easy connection/disconnection

## 🔧 Customization Options

### Common Parameters:
- `--t THICKNESS`: Wall thickness (default: 2.0mm)
- `--h HEIGHT`: Ring height (default: 20.0mm)  
- `--font-size SIZE`: Text size (default: 5.0)
- `--text-depth DEPTH`: Text embossing depth (default: 2.0mm)
- `--timeout SECONDS`: STL generation timeout (default: 120-180s)
- `-f, --file NAME`: Custom base name (extensions added automatically)

### Advanced Usage:
```bash
# Thick-walled ring for high-pressure applications
ruby ring_maker.rb -i 50 --t 5 --h 30 --stl

# Quick prototype with minimal text
ruby ring_maker.rb -o 76 --text-depth 0.5 --stl

# Custom filename (extension added automatically)
ruby ring_maker.rb -i 30 -f my_custom_ring --stl
# Creates: output/my_custom_ring.scad and output/my_custom_ring.stl

# Works even if you accidentally add extension
ruby ring_maker.rb -o 55 -f test.scad
# Creates: output/test.scad (extension stripped and re-added correctly)
```

## 🧪 Testing Your Setup

Run the test suite to verify everything works:

```bash
# Run all library tests
ruby test_runner.rb

# Should show: "100% passed" with no failures
```

## 📖 Text Labeling System

All rings automatically include diameter labels:
- **"I30mm"** = Inner diameter measurement
- **"O55mm"** = Outer diameter measurement  
- **Text placement**: Always on outer surface for STL readability

## ⚡ Performance Tips

1. **STL Generation**: Can take 30-120 seconds per ring
2. **Batch Processing**: Use test kits for multiple rings
3. **Preview First**: Check `.scad` files in OpenSCAD before generating STL
4. **Timeout Adjustment**: Increase `--timeout` for complex geometries
5. **Filename Handling**: Use `-f basename` - extensions are added automatically

## 📁 File Naming Convention

The toolkit automatically handles file extensions:

```bash
# These all work the same way:
ruby ring_maker.rb -i 30 -f my_ring
ruby ring_maker.rb -i 30 -f my_ring.scad  
ruby ring_maker.rb -i 30 -f my_ring.stl

# All create: output/my_ring.scad (and .stl if --stl flag used)
```

**Key Points:**
- Just provide the base name with `-f`
- Extensions (`.scad`, `.stl`) are added automatically
- If you accidentally include an extension, it's stripped and re-added correctly
- Output always goes to `output/` directory unless you specify a path

## 🔍 Troubleshooting

### "Command not found: openscad"
- Verify OpenSCAD is installed
- Check the alias in your shell configuration
- Restart your terminal after adding the alias

### "OpenSCAD failed to convert"
- Check that OpenSCAD can run: `openscad --version`
- Try increasing the timeout: `--timeout 300`
- Verify the `.scad` file opens correctly in OpenSCAD GUI

### Ruby errors
- Ensure Ruby 2.7+ is installed: `ruby --version`
- Check file permissions: `chmod +x *.rb`

## 📊 Dust Collection Size Reference

| Tool Type | Typical Port Size | Recommended Ring |
|-----------|------------------|------------------|
| Table Saw | 64mm inner | `ruby make_test_fit_kit.rb -i 64` |
| Miter Saw | 46mm outer | `ruby make_test_fit_kit.rb -o 46` |
| Planer | 63mm inner | `ruby make_adapter_pair.rb -i 63` |
| Main Duct | 101mm outer | `ruby ring_maker.rb -o 101` |
| Flex Hose | 63mm inner | `ruby ring_maker.rb -i 63` |

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Feel free to submit issues, feature requests, or pull requests to improve this toolkit!

---

**Happy 3D Printing!** 🎯✨