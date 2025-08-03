# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-08-03

### Added
- Initial release of AshCharts
- Core chart components for Ash Framework integration
- Support for Bar, Line, Pie, Doughnut, and Radar charts
- Phoenix LiveView integration with Chart.js
- Data transformation utilities for Ash resources
- Responsive chart design
- Custom color configuration
- Date grouping functionality for time-series data
- Group-by support for multi-dataset charts
- Aggregation functions (count, sum, avg, min, max)
- Convenience components (bar_chart, line_chart, pie_chart)
- Comprehensive documentation and examples
- JavaScript hook for Chart.js integration
- Helper functions for common chart operations

### Features
- **Easy Integration**: Simple component-based API
- **Multiple Chart Types**: Comprehensive chart type support
- **Customizable**: Extensive styling and configuration options
- **Responsive**: Mobile-friendly responsive design
- **Real-time**: LiveView integration for dynamic updates
- **Flexible**: Support for complex data transformations

### Components
- `AshCharts.Components.ash_chart/1` - Main chart component
- `AshCharts.Components.bar_chart/1` - Quick bar chart
- `AshCharts.Components.line_chart/1` - Quick line chart
- `AshCharts.Components.pie_chart/1` - Quick pie chart

### Modules
- `AshCharts` - Main module with documentation
- `AshCharts.Components` - Phoenix LiveView components
- `AshCharts.DataHelper` - Data transformation utilities
- `AshCharts.Helpers` - Helper functions and utilities

### Assets
- `priv/static/js/chart_hook.js` - JavaScript integration hook

### Documentation
- Comprehensive README with examples
- Full module documentation
- Installation and setup guides
- Usage examples and best practices