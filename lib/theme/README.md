# App Theme Documentation

## Overview

The `AppTheme` system provides a centralized, consistent design system across the entire application. It includes colors, typography, spacing, and component styling.

## File Structure

- `lib/theme/app_theme.dart` - Main theme file containing all theme-related classes

## Theme Components

### 1. **AppColors**
Centralized color palette for the entire app.

```dart
import 'package:countpluse/theme/app_theme.dart';

// Using colors
Container(
  color: AppColors.primary,      // Yellow (#FFD700)
  child: Text(
    'Primary Color',
    style: TextStyle(color: AppColors.textPrimary), // White
  ),
)
```

**Available Colors:**
- **Primary Colors:** `primary`, `primaryLight`, `primaryDark`
- **Background Colors:** `backgroundDark`, `backgroundDarker`, `surface`
- **Card Colors:** `cardBackground`, `cardBorder`
- **Text Colors:** `textPrimary`, `textSecondary`, `textTertiary`
- **Status Colors:** `success`, `danger`, `warning`, `info`
- **Semantic Colors:** `divider`, `disabled`

### 2. **AppTypography**
Predefined text styles for consistency across screens.

```dart
import 'package:countpluse/theme/app_theme.dart';

Text(
  'Heading',
  style: AppTypography.headlineLarge,
)

Text(
  'Body text',
  style: AppTypography.bodyMedium,
)

Text(
  'Label',
  style: AppTypography.labelSmall,
)
```

**Style Categories:**
- **Display Styles:** `displayLarge`, `displayMedium`, `displaySmall`
- **Heading Styles:** `headlineLarge`, `headlineMedium`, `headlineSmall`
- **Title Styles:** `titleLarge`, `titleMedium`, `titleSmall`
- **Body Styles:** `bodyLarge`, `bodyMedium`, `bodySmall`
- **Label Styles:** `labelLarge`, `labelMedium`, `labelSmall`
- **Special Styles:** `caption`, `overline`

### 3. **AppSpacing**
Consistent spacing values for layouts.

```dart
import 'package:countpluse/theme/app_theme.dart';

Padding(
  padding: const EdgeInsets.all(AppSpacing.lg),
  child: Text('Content'),
)

SizedBox(height: AppSpacing.md),
```

**Spacing Values:**
- `xs` = 4.0
- `sm` = 8.0
- `md` = 12.0
- `lg` = 16.0
- `xl` = 20.0
- `xxl` = 24.0
- `xxxl` = 32.0

### 4. **AppRadius**
Border radius values for consistent corner rounding.

```dart
import 'package:countpluse/theme/app_theme.dart';

Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
)
```

**Radius Values:**
- `xs` = 4.0
- `sm` = 8.0
- `md` = 12.0
- `lg` = 16.0
- `xl` = 20.0
- `full` = 9999.0

### 5. **AppShadows**
Predefined shadow styles for elevation effects.

```dart
import 'package:countpluse/theme/app_theme.dart';

Container(
  decoration: BoxDecoration(
    boxShadow: [AppShadows.lg],
  ),
)
```

**Shadow Options:**
- `sm` - Small shadow
- `md` - Medium shadow
- `lg` - Large shadow
- `xl` - Extra large shadow

### 6. **AppTheme**
Complete Material Theme configuration.

The theme is automatically applied in `main.dart`:

```dart
MaterialApp(
  theme: AppTheme.theme,
)
```

## Best Practices

### ✅ Do Use Theme Constants

```dart
// Good
Container(
  color: AppColors.cardBackground,
  padding: const EdgeInsets.all(AppSpacing.lg),
  child: Text('Content', style: AppTypography.bodyMedium),
)
```

### ❌ Don't Use Hardcoded Values

```dart
// Bad
Container(
  color: Color(0xFF1F5548),
  padding: const EdgeInsets.all(16),
  child: Text('Content', style: TextStyle(fontSize: 14)),
)
```

## Usage Examples

### Creating a Card

```dart
import 'package:countpluse/theme/app_theme.dart';

Container(
  padding: const EdgeInsets.all(AppSpacing.lg),
  decoration: BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.cardBorder),
  ),
  child: Column(
    children: [
      Text('Card Title', style: AppTypography.headlineSmall),
      SizedBox(height: AppSpacing.md),
      Text('Card content', style: AppTypography.bodyMedium),
    ],
  ),
)
```

### Creating a Button

```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Button', style: AppTypography.labelLarge),
)
```

### Creating Text with Different Styles

```dart
Column(
  children: [
    Text('Display', style: AppTypography.displayLarge),
    Text('Heading', style: AppTypography.headlineLarge),
    Text('Title', style: AppTypography.titleLarge),
    Text('Body', style: AppTypography.bodyMedium),
    Text('Label', style: AppTypography.labelSmall),
  ],
)
```

### Applying Color Overlays

```dart
Icon(
  Icons.star,
  color: AppColors.primary.withOpacity(0.8),
)
```

## Extending the Theme

To add new colors or styles, update `lib/theme/app_theme.dart`:

```dart
class AppColors {
  // Add new colors
  static const Color newColor = Color(0xFF123456);
}

class AppTypography {
  // Add new text styles
  static const TextStyle newStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
```

## Color Palette Reference

| Name | Color | Hex Code | Usage |
|------|-------|----------|-------|
| Primary | 🟡 Yellow | #FFD700 | Buttons, Icons, Active States |
| Success | 🟢 Green | #34C759 | Success Messages, Trends |
| Danger | 🔴 Red | #FF453A | Errors, Negative Trends |
| Warning | 🟠 Orange | #FF9500 | Warnings |
| Background | 🟢 Dark Green | #1B4D3E | App Background |
| Card | 🟢 Teal | #1F5548 | Card Backgrounds |
| Text Primary | ⚪ White | #FFFFFF | Primary Text |
| Text Secondary | ⚫ Gray | #9CA3AF | Secondary Text |

