# Small Screens and Keyboard

Many users are on a phone. Some never touch a mouse. WCAG is the standard to judge against.

**Interfaces:** browser.

## Signals

The change adds or changes visible layout: a page, a form, a table, a modal, a menu, or new controls.

## Moves

- `browser_resize` to about 375 x 667, then 768 x 1024. Do the core flow at each size.
- Look for content cut off, horizontal scrolling, buttons off screen or under a fixed header, tables you can't read, and modals taller than the screen with the submit button out of reach.
- **Keyboard only:** Tab through the changed area. Can you reach every control, in a sensible order, with a visible focus ring? Can you submit with Enter, close a modal with Escape, and land focus somewhere sensible afterward?
- **Zoom:** emulate 200% zoom (or a narrow viewport) and check that text reflows instead of overlapping.
- **Names:** in `browser_snapshot`, check that new controls have names a screen reader would announce ("Save claim", not "button"), and that images that carry meaning have text alternatives.
- **Feedback:** after each action, is the result shown in text, not by color alone?

## Findings

- A user on a phone can't finish the core flow.
- A control can't be reached or used with the keyboard.
- Focus is lost or trapped after an action.
- A new control has no accessible name, or meaning is carried by color alone.

## False positives

- Staff-only screens the app doesn't support on mobile anywhere. Check sibling pages first.
- Layouts that look different but still work.
