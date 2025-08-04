# Tapir Installation Guide

Tapir provides automated installation using Igniter to set up everything you need for chart functionality.

## Automatic Installation (Recommended)

Simply run:

```bash
mix igniter.install tapir
```

This single command will:
- ✅ Add Tapir and Ash to your `mix.exs` dependencies
- ✅ Run `mix deps.get` to fetch dependencies
- ✅ Add Chart.js to your `assets/package.json`
- ✅ Create `assets/js/chart_hook.js` with Chart.js integration
- ✅ Update `assets/js/app.js` to import and configure the hook
- ✅ Update `mix.exs` aliases to include `npm install --prefix assets`
- ✅ Run `npm install` to install JavaScript dependencies



## What the Installer Does

### 1. Package.json Setup
Creates or updates `assets/package.json`:
```json
{
  "dependencies": {
    "chart.js": "^4.5.0"
  }
}
```

### 2. Chart Hook Creation
Creates `assets/js/chart_hook.js` with a complete Chart.js LiveView hook that supports:
- All Chart.js chart types (bar, line, pie, doughnut, radar)
- Responsive charts
- Custom colors
- Real-time updates
- Proper cleanup on destroy

### 3. App.js Integration
Updates your `assets/js/app.js` to:
- Import the TapirChartHook
- Add it to the LiveSocket hooks configuration

### 4. Mix Aliases
Updates your `mix.exs` to add npm install to the `assets.setup` alias:
```elixir
"assets.setup": [
  "tailwind.install --if-missing", 
  "esbuild.install --if-missing", 
  "cmd npm install --prefix assets"
]
```

## Alternative Installation Methods

### Using mix tapir.install

If you already have Tapir in your dependencies, you can run:

```bash
mix deps.get
mix tapir.install
```

### Manual Installation

If you prefer manual setup or the automatic installer doesn't work perfectly:

### 1. Add Chart.js Dependency

Create or update `assets/package.json`:
```json
{
  "dependencies": {
    "chart.js": "^4.5.0"
  }
}
```

### 2. Install npm Dependencies

```bash
cd assets && npm install
```

### 3. Copy Chart Hook

Copy the Chart.js hook from the Tapir package or create `assets/js/chart_hook.js` with the hook implementation.

### 4. Update App.js

Add to your `assets/js/app.js`:
```javascript
import TapirChartHook from "./chart_hook"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {Chart: TapirChartHook, ...otherHooks}
})
```

### 5. Update Web Module

Add to your web module's `html_helpers/0`:
```elixir
import Tapir.Components
```

## Usage After Installation

Once installed, you can use Tapir components in your LiveViews:

```elixir
<.ash_chart 
  resource={MyApp.SalesData}
  chart_type={:bar}
  x_field={:product_name}
  y_field={:sales_amount}
  title="Sales by Product"
/>
```

## Troubleshooting

### Charts Not Rendering
- Ensure Chart.js is installed: `cd assets && npm list chart.js`
- Check browser console for JavaScript errors
- Verify the Chart hook is loaded in app.js

### Import Errors
- Make sure `import Tapir.Components` is in your web module
- Restart your Phoenix server after installation

### Build Issues
- Run `mix assets.setup` to ensure all assets are properly installed
- Clear build artifacts: `mix clean && mix deps.clean tapir && mix deps.get`

## Development Setup

For development with real data:

1. Create an Ash resource
2. Set up a data layer (ETS for development, Ecto for production)
3. Seed some sample data
4. Use Tapir components in your LiveViews

Example resource:
```elixir
defmodule MyApp.Analytics.SalesData do
  use Ash.Resource, 
    domain: MyApp.Analytics, 
    data_layer: Ash.DataLayer.Ets
  
  attributes do
    uuid_primary_key :id
    attribute :product_name, :string, public?: true
    attribute :sales_amount, :integer, public?: true
    attribute :category, :string, public?: true
  end
  
  actions do
    defaults [:read, :create, :update, :destroy]
  end
end
```