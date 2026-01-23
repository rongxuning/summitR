---
name: interaction-designer
description: Provides expertise in app UI/UX design, interaction patterns, user experience principles, and interface design best practices. Use when designing app interfaces, creating user flows, discussing UX/UI design, wireframing, prototyping, or when the user mentions design, user experience, or interface design.
---

# App Interaction Designer

## Core Design Principles

### User-Centered Design
- Design for users, not for yourself
- Understand user needs, goals, and pain points
- Create intuitive and accessible interfaces
- Test designs with real users when possible
- Iterate based on feedback

### Visual Hierarchy
- Guide user attention through size, color, contrast, and spacing
- Use typography to establish information hierarchy
- Group related elements together (proximity)
- Make important actions prominent
- Reduce visual clutter

### Consistency
- Maintain consistent patterns throughout the app
- Use design system components
- Follow platform conventions (iOS Human Interface Guidelines, Material Design)
- Keep terminology and iconography consistent
- Ensure predictable interactions

## Interaction Patterns

### Navigation Patterns
- **Tab Bar**: Primary navigation for main sections (max 5 items)
- **Navigation Stack**: Hierarchical navigation with back button
- **Modal**: Temporary focused tasks or secondary actions
- **Drawer/Sidebar**: Secondary navigation or settings
- **Bottom Sheet**: Contextual actions or additional content

### Input Patterns
- **Forms**: Clear labels, inline validation, helpful error messages
- **Search**: Prominent search bar, autocomplete, recent searches
- **Selection**: Radio buttons, checkboxes, switches, pickers
- **Gestures**: Swipe, pinch, long-press, drag-and-drop

### Feedback Patterns
- **Loading States**: Skeleton screens, progress indicators, spinners
- **Empty States**: Helpful messages with clear next steps
- **Error States**: Clear error messages with recovery actions
- **Success States**: Confirmation messages or visual feedback
- **Haptic Feedback**: Subtle vibrations for important interactions

## Mobile Design Considerations

### Touch Targets
- Minimum 44x44 points (iOS) or 48x48dp (Android)
- Adequate spacing between interactive elements
- Account for thumb zones (easy reach areas)
- Consider one-handed usage

### Screen Sizes
- Design for various screen sizes and orientations
- Use responsive layouts and adaptive components
- Test on different devices
- Handle safe areas and notches appropriately

### Performance Perception
- Optimize perceived performance
- Show content progressively (skeleton screens)
- Preload critical content
- Minimize loading times

## Information Architecture

### Content Organization
- Group related content logically
- Use clear categorization
- Implement effective search and filtering
- Provide multiple ways to access content
- Limit cognitive load

### User Flows
- Map complete user journeys
- Identify key user goals
- Minimize steps to complete tasks
- Provide clear paths forward and back
- Handle edge cases and error states

### Onboarding
- Keep onboarding brief and focused
- Show value, not just features
- Allow skipping when appropriate
- Provide progressive disclosure
- Make it easy to return to onboarding

## Visual Design Elements

### Typography
- Use clear, readable fonts
- Establish type scale (headings, body, captions)
- Ensure sufficient contrast (WCAG AA minimum)
- Support Dynamic Type (iOS) / Accessibility Font Scaling
- Use appropriate line height and letter spacing

### Color
- Use color purposefully (not just decoration)
- Ensure sufficient contrast for accessibility
- Consider color blindness (don't rely solely on color)
- Use color to indicate states and hierarchy
- Support Dark Mode with semantic colors

### Spacing
- Use consistent spacing system (8pt or 4pt grid)
- Provide breathing room between elements
- Group related items with proximity
- Use whitespace to create visual hierarchy

### Icons and Imagery
- Use clear, recognizable icons
- Maintain consistent icon style
- Optimize images for performance
- Provide alt text for accessibility
- Use appropriate image sizes and formats

## Animation and Motion

### Purposeful Animation
- Use animation to guide attention
- Provide feedback for user actions
- Enhance spatial understanding
- Indicate state changes
- Keep animations subtle and fast (200-300ms)

### Transition Patterns
- **Fade**: For content changes
- **Slide**: For navigation and panels
- **Scale**: For modals and popovers
- **Morph**: For related elements

### Micro-interactions
- Button press feedback
- Loading animations
- Success confirmations
- Error indicators
- Pull-to-refresh

## Accessibility

### Inclusive Design
- Support VoiceOver/TalkBack screen readers
- Ensure keyboard navigation
- Provide sufficient color contrast
- Support Dynamic Type
- Include alternative text for images
- Test with accessibility tools

### Usability
- Make interfaces self-explanatory
- Provide clear labels and instructions
- Use familiar patterns
- Offer undo/redo when appropriate
- Handle errors gracefully

## Design Process

### Research and Discovery
- Understand user needs and goals
- Analyze competitors and similar apps
- Identify user pain points
- Define success metrics

### Ideation
- Brainstorm multiple solutions
- Create user flows and journey maps
- Sketch wireframes
- Consider edge cases

### Design
- Create high-fidelity mockups
- Design all states (default, active, disabled, error)
- Consider different screen sizes
- Design loading and empty states

### Prototyping
- Build interactive prototypes
- Test user flows
- Validate interactions
- Gather feedback early

### Testing and Iteration
- Conduct usability testing
- Gather quantitative and qualitative data
- Iterate based on findings
- Measure against success metrics

## Design Tools and Deliverables

### Design Tools
- **Figma**: Collaborative design and prototyping
- **Sketch**: Vector design for Mac
- **Adobe XD**: Design and prototyping
- **Principle/Framer**: Advanced animations

### Deliverables
- User personas and journey maps
- Wireframes and user flows
- High-fidelity mockups
- Interactive prototypes
- Design specifications and style guides
- Component libraries and design systems

## Platform-Specific Guidelines

### iOS (Human Interface Guidelines)
- Follow iOS design language
- Use native iOS components when appropriate
- Respect safe areas and system UI
- Support Dark Mode
- Follow iOS navigation patterns

### Android (Material Design)
- Follow Material Design principles
- Use Material components
- Support different screen densities
- Handle system bars appropriately
- Follow Android navigation patterns

## Common Patterns and Anti-Patterns

### Good Patterns
- ✅ Clear primary actions
- ✅ Progressive disclosure
- ✅ Confirmation for destructive actions
- ✅ Undo/redo capabilities
- ✅ Contextual help and tooltips
- ✅ Consistent iconography

### Anti-Patterns
- ❌ Hidden or unclear navigation
- ❌ Too many steps to complete tasks
- ❌ Inconsistent patterns
- ❌ Poor error handling
- ❌ Overwhelming interfaces
- ❌ Ignoring platform conventions

## Design System Components

### Building Blocks
- Buttons (primary, secondary, tertiary)
- Input fields (text, number, date, etc.)
- Cards and containers
- Lists and tables
- Navigation components
- Feedback components (alerts, toasts, badges)

### Design Tokens
- Colors (primary, secondary, semantic)
- Typography (font families, sizes, weights)
- Spacing (margins, padding, gaps)
- Border radius
- Shadows and elevations
- Animation durations and easings

## Resources

- iOS Human Interface Guidelines
- Material Design Guidelines
- Nielsen's Usability Heuristics
- WCAG Accessibility Guidelines
- Design system examples (Apple, Google, Airbnb, etc.)
