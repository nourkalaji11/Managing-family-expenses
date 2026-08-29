---
name: Kinship Finance
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
  on-surface-variant: '#424754'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#727785'
  outline-variant: '#c2c6d6'
  surface-tint: '#005ac2'
  primary: '#0058be'
  on-primary: '#ffffff'
  primary-container: '#2170e4'
  on-primary-container: '#fefcff'
  inverse-primary: '#adc6ff'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#825100'
  on-tertiary: '#ffffff'
  tertiary-container: '#a36700'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a42'
  on-primary-fixed-variant: '#004395'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-md:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-padding: 1.25rem
  stack-gap-sm: 0.5rem
  stack-gap-md: 1rem
  stack-gap-lg: 1.5rem
  section-margin: 2rem
---

## Brand & Style
The design system is built on a foundation of trust, clarity, and communal support, tailored specifically for family financial management. The aesthetic follows a **Modern Corporate** direction with a soft, friendly edge—moving beyond cold banking interfaces toward a more approachable, lifestyle-oriented experience.

The visual language utilizes high-quality white space and a "soft-material" approach. It prioritizes legibility and ease of use for multi-generational users, ensuring that tracking expenses feels like a collaborative household habit rather than a chore. The interface is optimized for **RTL (Right-to-Left)** orientation as the primary layout logic, ensuring natural eye flow for Arabic-speaking families.

## Colors
The palette is rooted in a "Trust Blue" and "Growth Green" combination. 
- **Primary (#3B82F6):** Used for key actions, active states, and primary navigation elements. It conveys stability and digital fluency.
- **Success (#10B981):** Represents income, savings goals, and positive budget status.
- **Surface & Background:** A clean white (#FFFFFF) is used for cards to pop against a very light cool-gray (#F8FAFC) background, creating clear structural separation without heavy borders.
- **Functional Neutrals:** A range of slate grays is used for secondary text and icons to maintain a soft hierarchy.

## Typography
This design system employs **IBM Plex Sans Arabic** for its exceptional balance between technical precision and calligraphic heritage. The type scale is optimized for mobile readability, with generous line heights to accommodate Arabic diacritics.

- **Headlines:** Reserved for large currency displays and screen titles.
- **Body Text:** Uses a slightly heavier weight (400) than standard Latin fonts to ensure the intricate strokes of Arabic characters remain legible at small sizes.
- **RTL Alignment:** All text is right-aligned by default. Numbers (Western Arabic numerals) should maintain a clear, legible weight to stand out within financial lists.

## Layout & Spacing
The layout follows a **Mobile-First Fluid Grid** with a strict 4px/8px baseline rhythm. 

- **Margins:** A standard 20px (1.25rem) horizontal margin is applied to the main viewport.
- **RTL Flow:** The layout starts from the right. Sidebars, icons, and progress bars must flip their orientation. Back arrows point to the right (`->`).
- **Grouping:** Use 16px (1rem) spacing between related cards and 24px (1.5rem) between distinct functional sections.

## Elevation & Depth
Depth is created using **Tonal Layers** and **Ambient Shadows** to signify interactable surfaces.

- **Level 0 (Background):** #F8FAFC.
- **Level 1 (Cards/Lists):** White background with a very soft, diffused shadow: `0px 4px 12px rgba(0, 0, 0, 0.05)`.
- **Level 2 (Active/Floating):** Used for the Floating Action Button (FAB) and active modals. Shadow: `0px 8px 24px rgba(59, 130, 246, 0.15)`.
- **Interactions:** On press, cards should visually "sink" by reducing shadow spread and slightly dimming the surface color.

## Shapes
The shape language is consistently **Rounded**, reflecting a friendly and modern fintech persona. 

- **Primary Containers:** Large surfaces like expense cards and charts use a 16px (`rounded-lg`) to 24px (`rounded-xl`) corner radius.
- **Buttons & Inputs:** Use a 12px radius to balance the softer cards with a sense of structural integrity.
- **Interactive Indicators:** Small badges and category tags use a fully rounded (pill-shaped) geometry to distinguish them from structural cards.

## Components
### Buttons
- **Primary:** Solid #3B82F6 with white text. High-emphasis for "Add Expense" or "Save."
- **Secondary:** Light blue tint background with primary blue text. Used for "View Details."

### Cards & Widgets
- **Expense Card:** Features a right-aligned icon (category), followed by the transaction name and date. The amount is left-aligned (in an RTL context, the amount sits at the end of the line).
- **Progress Widgets:** Circular or horizontal bars showing "Budget Spent." Use #10B981 for safe zones and #EF4444 (Error) when a family member exceeds a limit.

### Input Fields
- Filled style with a subtle 1px border. The label floats above the field on focus. In RTL, the label and cursor start at the right.

### Chips/Tags
- Small, rounded-pill elements used to filter by family member (e.g., "Dad," "Mom," "Home"). Each member can be assigned a subtle color-coded border.

### Bottom Navigation
- A clean white bar with 4-5 icons. The "Add" button is often centered and elevated using a FAB (Floating Action Button) with a primary blue fill.