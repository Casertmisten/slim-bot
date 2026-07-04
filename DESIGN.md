---
name: Vitality Logic
colors:
  surface: '#f8faf8'
  surface-dim: '#d8dad9'
  surface-bright: '#f8faf8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f2'
  surface-container: '#eceeec'
  surface-container-high: '#e6e9e7'
  surface-container-highest: '#e1e3e1'
  on-surface: '#191c1b'
  on-surface-variant: '#40493d'
  inverse-surface: '#2e3130'
  inverse-on-surface: '#eff1ef'
  outline: '#707a6c'
  outline-variant: '#bfcab9'
  surface-tint: '#106d20'
  primary: '#0b6b1d'
  on-primary: '#ffffff'
  primary-container: '#2e8534'
  on-primary-container: '#f7fff1'
  inverse-primary: '#82db7e'
  secondary: '#5d5f5f'
  on-secondary: '#ffffff'
  secondary-container: '#dfe0e0'
  on-secondary-container: '#616363'
  tertiary: '#276929'
  on-tertiary: '#ffffff'
  tertiary-container: '#418340'
  on-tertiary-container: '#f7fff1'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9df898'
  primary-fixed-dim: '#82db7e'
  on-primary-fixed: '#002204'
  on-primary-fixed-variant: '#005312'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c7'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#acf4a4'
  tertiary-fixed-dim: '#91d78a'
  on-tertiary-fixed: '#002203'
  on-tertiary-fixed-variant: '#0c5216'
  background: '#f8faf8'
  on-background: '#191c1b'
  surface-variant: '#e1e3e1'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  container-max: 1280px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 40px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style
The design system focuses on high-performance health and athletic coaching, blending clinical precision with natural vitality. The target audience includes professional athletes, health coaches, and wellness-conscious individuals who value clarity and data-driven progress. 

The visual style is **Corporate Modern with a Minimalist lean**. It prioritizes breathability and "air" to prevent data-heavy interfaces from feeling overwhelming. By utilizing a high-contrast light mode, the system ensures maximum legibility and a sense of cleanliness. The emotional response should be one of "calm focus"—reducing cognitive load while providing a vibrant, energetic aesthetic through strategic use of the primary green.

## Colors
The palette is rooted in a balanced, vibrant green that bridges the gap between organic nature and digital performance.

- **Primary (#388E3C):** Used for key actions, active states, and brand-critical indicators. It provides enough contrast against white for accessibility while maintaining a "living" feel.
- **Secondary (#FFFFFF):** The foundation of the UI. Used for card backgrounds, page surfaces, and large-scale empty space to create an airy environment.
- **Tertiary (#1B5E20):** A deeper forest shade reserved for high-contrast text on light backgrounds or for "dark mode" accents within small components.
- **Neutral (#F5F7F5):** A very light, sage-tinted grey used for background surfaces and subtle containment to avoid the harshness of pure #000000 on #FFFFFF.

## Typography
This design system utilizes **Inter** exclusively to lean into its systematic, utilitarian strengths. 

- **Headlines:** Use tight letter-spacing (-0.01em to -0.02em) for larger sizes to maintain a modern, "tucked" look. 
- **Body Text:** Standard tracking for maximum readability in coaching logs and health reports.
- **Labels:** Use Medium (500) or SemiBold (600) weights to differentiate from body text. Small labels (caps) are utilized for data categories and metadata.
- **Scale:** On mobile devices, headline sizes should step down one level to ensure content remains readable without excessive wrapping.

## Layout & Spacing
The layout follows a **fluid grid system** with generous safe areas. 

- **Grid:** A 12-column grid for desktop with 24px gutters. For mobile, a 4-column grid with 16px margins.
- **Rhythm:** An 8px-based spatial system (4px, 8px, 16px, 24px, 32px, 48px, 64px). 
- **Density:** High whitespace is mandatory. Avoid packing elements tightly; let the white secondary color provide a "buffer" between different data modules.
- **Alignment:** Consistent left-alignment for all text-heavy content to maintain a professional, document-style flow.

## Elevation & Depth
To maintain the "airy" feel, this design system avoids heavy shadows. 

- **Tonal Layers:** Depth is primarily created through subtle color shifts between the page background (Neutral) and the card surfaces (Pure White).
- **Ambient Shadows:** When elevation is required (e.g., for modals or floating action buttons), use extremely diffused, low-opacity shadows. Use a Y-offset of 4px to 8px with a 15px-20px blur, with a shadow color tinted slightly by the primary green (e.g., #1B5E20 at 5% opacity).
- **Outlines:** Use 1px borders in a very light neutral-grey (#E0E4E0) for cards and inputs to define boundaries without adding visual weight.

## Shapes
The shape language is **Rounded**, striking a balance between friendly approachability and professional discipline.

- **Standard Elements:** 8px (0.5rem) radius for buttons, input fields, and small cards.
- **Large Containers:** 16px (1rem) for main dashboard cards and modals.
- **Interactive Accents:** Active states in navigation or "pills" for status indicators use the `rounded-xl` (1.5rem/24px) setting to create a soft, organic feel.

## Components
- **Buttons:** Primary buttons use a solid Primary Green background with White text. Secondary buttons use a Primary Green outline with a transparent background. All buttons have an 8px corner radius.
- **Input Fields:** Use the 1px neutral outline. Focus states should transition the border to Primary Green and include a 2px "soft glow" shadow using the primary color at 10% opacity.
- **Cards:** White background, 16px corner radius, and a 1px subtle neutral border. Use 24px internal padding to maintain the "airy" aesthetic.
- **Chips/Badges:** Use "Pill" shapes (maximum rounding). Use a light tint of the primary color (10% opacity) for the background with Primary Green text for active or positive states.
- **Lists:** Clean rows separated by a 1px neutral divider. Hover states should use a subtle shift to the Neutral background color.
- **Progress Bars:** Use Primary Green for the fill and the Neutral grey for the track. Keep them thin (8px height) for a modern, sophisticated look.
