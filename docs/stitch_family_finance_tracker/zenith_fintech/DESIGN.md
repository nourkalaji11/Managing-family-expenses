---
name: Zenith Fintech
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#45464d'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#76777d'
  outline-variant: '#c6c6cd'
  surface-tint: '#565e74'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#131b2e'
  on-primary-container: '#7c839b'
  inverse-primary: '#bec6e0'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#191c1e'
  on-tertiary-container: '#818486'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2fd'
  primary-fixed-dim: '#bec6e0'
  on-primary-fixed: '#131b2e'
  on-primary-fixed-variant: '#3f465c'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#e0e3e5'
  tertiary-fixed-dim: '#c4c7c9'
  on-tertiary-fixed: '#191c1e'
  on-tertiary-fixed-variant: '#444749'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Manrope
    fontSize: 56px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Work Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Work Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Work Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 16px
  margin-desktop: 32px
  gutter: 16px
  container-max-width: 1200px
---

## Brand & Style
This design system embodies a **Modern Corporate** aesthetic tailored for high-end fintech and banking. It prioritizes clarity, precision, and trust through a minimalist framework inspired by Material Design 3 (MD3) principles. 

The visual narrative is "Stability through Simplicity." By utilizing expansive whitespace, refined typography, and a structured layout, the system evokes a sense of institutional reliability while remaining approachable for a digital-first audience. The inclusion of full RTL support for Arabic ensures a premium experience across global financial markets.

## Colors
The palette is anchored by **Deep Navy (#0F172A)**, providing a sense of authority and professional grounding. This is contrasted by **Emerald Green (#10B981)**, used strategically for success states, primary actions, and growth-related data visualizations. 

The background is a crisp, clean white, while the tertiary shade is a very soft cool grey used for subtle surface differentiation. Neutral tones are strictly derived from the slate-blue spectrum to maintain a cohesive, cool-toned professional atmosphere.

## Typography
The typography system balances modern geometry with high legibility. **Manrope** is used for headlines to provide a clean, structural feel. **Work Sans** handles body text for its excellent readability in financial data contexts. **IBM Plex Sans** is utilized for labels and UI metadata to maintain an organized, technical appearance.

For Arabic support, ensure the selected fonts include Noto Sans Arabic or IBM Plex Sans Arabic fallback sets to maintain the weight and vertical alignment consistency across RTL layouts.

## Layout & Spacing
This design system utilizes a **12-column fluid grid** for desktop and a **4-column fluid grid** for mobile. We follow an 8px baseline grid to ensure mathematical harmony across all components.

- **Desktop:** 32px margins with 16px gutters.
- **Mobile:** 16px margins with 12px gutters.
- **RTL Logic:** In Arabic locales, the entire grid mirrors. Horizontal paddings (e.g., `padding-left`) must be implemented as logical properties (`padding-inline-start`) to support bidirectional flow seamlessly.

## Elevation & Depth
Consistent with Material Design 3, depth is communicated through **Tonal Layers** rather than heavy shadows. Surfaces "lift" by becoming slightly lighter or by using extremely soft, diffused ambient shadows (0% spread, 4-8% opacity).

Key depth levels:
1.  **Level 0 (Base):** Pure white background.
2.  **Level 1 (Cards):** Tonal elevation using the Tertiary color (#F8FAFC) or a 1px border (#E2E8F0).
3.  **Level 2 (Modals/Popups):** Soft shadow with a 16px blur, 0px Y-offset, using the Deep Navy color at 5% opacity.

## Shapes
The shape language is **Rounded**, utilizing an 8px (0.5rem) radius for standard components like buttons and input fields. Larger containers and cards use a 16px (1rem) radius. This provides a modern, friendly feel that softens the "coldness" of a corporate fintech palette without feeling overly casual or "bubbly."

## Components
- **Buttons:** Primary buttons use the Deep Navy background with white text. Success actions use Emerald Green. Standard buttons have an 8px radius and a height of 48px for accessibility.
- **Input Fields:** Outlined style with a 1px slate border. Upon focus, the border thickens to 2px and changes to Deep Navy. Labels should float or remain visible to assist users during complex financial forms.
- **Chips:** Small, low-contrast pills (Tertiary color) used for transaction categories or filters.
- **Cards:** White background with a 1px soft border. Avoid heavy shadows; rely on the border to define boundaries against the white background.
- **Data Visualization:** Use Emerald Green for positive trends and a muted Coral (derived from neutral red) for negative trends. Line weights should be thin (2px) to maintain the "Clean" brand aesthetic.
- **RTL Considerations:** All icons that indicate direction (arrows, chevrons) must be flipped in Arabic mode, except for logos and playback controls.