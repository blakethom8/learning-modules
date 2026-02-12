#!/bin/bash

# ui-gen.sh - Generate single-file HTML apps from description
# Usage: ./ui-gen.sh "description" [--dark] [--with-chart] [--with-map] [--with-table]

set -e

# Default values
DESCRIPTION=""
DARK_MODE=false
WITH_CHART=false
WITH_MAP=false
WITH_TABLE=false
OUTPUT_DIR="./output"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dark)
      DARK_MODE=true
      shift
      ;;
    --with-chart)
      WITH_CHART=true
      shift
      ;;
    --with-map)
      WITH_MAP=true
      shift
      ;;
    --with-table)
      WITH_TABLE=true
      shift
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./ui-gen.sh \"description\" [options]"
      echo ""
      echo "Options:"
      echo "  --dark          Use dark theme"
      echo "  --with-chart    Include Chart.js"
      echo "  --with-map      Include Leaflet maps"
      echo "  --with-table    Include table styling helpers"
      echo "  --output DIR    Output directory (default: ./output)"
      echo ""
      echo "Examples:"
      echo "  ./ui-gen.sh \"Admin Dashboard\" --dark"
      echo "  ./ui-gen.sh \"Analytics\" --dark --with-chart"
      echo "  ./ui-gen.sh \"Provider Map\" --dark --with-map"
      exit 0
      ;;
    *)
      DESCRIPTION="$1"
      shift
      ;;
  esac
done

# Validate description
if [ -z "$DESCRIPTION" ]; then
  echo "Error: Description is required"
  echo "Usage: ./ui-gen.sh \"description\" [options]"
  echo "Run with -h or --help for more information"
  exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate filename from description
FILENAME=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-').html
OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"

echo "🔨 Generating: $DESCRIPTION"

# Build HTML content
cat > "$OUTPUT_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>__TITLE__</title>
    
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- Alpine.js for interactivity -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    __EXTRA_LIBS__
</head>
<body class="__BODY_CLASS__ min-h-screen p-8">
    
    <div x-data="app()" class="max-w-6xl mx-auto">
        <h1 class="text-4xl font-bold mb-8">__TITLE__</h1>
        
        <!-- Add your content here -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div class="__CARD_CLASS__ rounded-lg p-6">
                <h2 class="text-xl font-bold mb-2">Feature 1</h2>
                <p class="__TEXT_CLASS__">Description here</p>
            </div>
            <div class="__CARD_CLASS__ rounded-lg p-6">
                <h2 class="text-xl font-bold mb-2">Feature 2</h2>
                <p class="__TEXT_CLASS__">Description here</p>
            </div>
            <div class="__CARD_CLASS__ rounded-lg p-6">
                <h2 class="text-xl font-bold mb-2">Feature 3</h2>
                <p class="__TEXT_CLASS__">Description here</p>
            </div>
        </div>
        
        __TABLE_SECTION__
        
    </div>
    
    <script>
        function app() {
            return {
                message: 'Hello, World!',
                
                async fetchData() {
                    // Fetch data from your API
                    const response = await fetch('/api/data');
                    return await response.json();
                }
            };
        }
    </script>
    
</body>
</html>
EOF

# Replace placeholders
sed -i '' "s/__TITLE__/$DESCRIPTION/g" "$OUTPUT_FILE"

# Apply theme
if [ "$DARK_MODE" = true ]; then
    sed -i '' 's/__BODY_CLASS__/bg-gray-900 text-white/g' "$OUTPUT_FILE"
    sed -i '' 's/__CARD_CLASS__/bg-gray-800 shadow-lg/g' "$OUTPUT_FILE"
    sed -i '' 's/__TEXT_CLASS__/text-gray-400/g' "$OUTPUT_FILE"
else
    sed -i '' 's/__BODY_CLASS__/bg-gray-50 text-gray-900/g' "$OUTPUT_FILE"
    sed -i '' 's/__CARD_CLASS__/bg-white shadow/g' "$OUTPUT_FILE"
    sed -i '' 's/__TEXT_CLASS__/text-gray-600/g' "$OUTPUT_FILE"
fi

# Build extra libraries string
EXTRA_LIBS=""

if [ "$WITH_CHART" = true ]; then
    EXTRA_LIBS="${EXTRA_LIBS}\n    <!-- Chart.js -->"
    EXTRA_LIBS="${EXTRA_LIBS}\n    <script src=\"https://cdn.jsdelivr.net/npm/chart.js\"></script>"
fi

if [ "$WITH_MAP" = true ]; then
    EXTRA_LIBS="${EXTRA_LIBS}\n    <!-- Leaflet Maps -->"
    EXTRA_LIBS="${EXTRA_LIBS}\n    <link rel=\"stylesheet\" href=\"https://unpkg.com/leaflet@1.9.4/dist/leaflet.css\" />"
    EXTRA_LIBS="${EXTRA_LIBS}\n    <script src=\"https://unpkg.com/leaflet@1.9.4/dist/leaflet.js\"></script>"
fi

# Insert extra libraries
if [ ! -z "$EXTRA_LIBS" ]; then
    sed -i '' "s|__EXTRA_LIBS__|$EXTRA_LIBS|g" "$OUTPUT_FILE"
else
    sed -i '' 's/__EXTRA_LIBS__//g' "$OUTPUT_FILE"
fi

# Add table section if requested
if [ "$WITH_TABLE" = true ]; then
    TABLE_HTML='
        <div class="mt-8">
            <h2 class="text-2xl font-bold mb-4">Data Table</h2>
            <div class="__CARD_CLASS__ rounded-lg overflow-hidden">
                <table class="w-full">
                    <thead class="bg-gray-700">
                        <tr>
                            <th class="px-6 py-3 text-left">Name</th>
                            <th class="px-6 py-3 text-left">Email</th>
                            <th class="px-6 py-3 text-left">Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr class="border-b border-gray-700">
                            <td class="px-6 py-4">John Doe</td>
                            <td class="px-6 py-4">john@example.com</td>
                            <td class="px-6 py-4"><span class="text-green-500">Active</span></td>
                        </tr>
                        <tr class="border-b border-gray-700">
                            <td class="px-6 py-4">Jane Smith</td>
                            <td class="px-6 py-4">jane@example.com</td>
                            <td class="px-6 py-4"><span class="text-green-500">Active</span></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>'
    sed -i '' "s|__TABLE_SECTION__|$TABLE_HTML|g" "$OUTPUT_FILE"
else
    sed -i '' 's/__TABLE_SECTION__//g' "$OUTPUT_FILE"
fi

echo "✅ Generated: $OUTPUT_FILE"

# Open in browser
if command -v open &> /dev/null; then
    open "$OUTPUT_FILE"
    echo "🌐 Opened in browser"
elif command -v xdg-open &> /dev/null; then
    xdg-open "$OUTPUT_FILE"
    echo "🌐 Opened in browser"
else
    echo "⚠️  Could not open browser automatically"
    echo "   Open manually: $OUTPUT_FILE"
fi

echo "✨ Done!"
