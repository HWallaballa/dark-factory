# Spec: Homepage Lead Capture Section

## Metadata
- **repo:** /home/gilberto/Desktop/Pinehaven Ventures/pinehaven-ventures-website
- **product:** Pinehaven Ventures Website
- **priority:** high
- **estimated_complexity:** medium

---

## What to Build

Add a "Stay in the Loop" email capture section to the homepage (`src/app/page.tsx`). It should appear between the Products section and the footer. Visitors who aren't ready to pay should be able to subscribe for free weekly insights about power infrastructure, data center site selection, and ERCOT queue changes. These leads convert to Power Queue Tracker paid subscribers over time.

---

## Acceptance Criteria

- [ ] A full-width section with dark background (bg-gray-900) appears on the homepage between products and footer
- [ ] Heading: "Stay ahead of the power queue."
- [ ] Subtext: "Free weekly insights on ERCOT interconnection queue changes, data center site selection signals, and power infrastructure trends. No spam. Unsubscribe anytime."
- [ ] Email input + "Get Free Insights →" button, same pattern as SubscribeBanner component
- [ ] On submit: POST to `/api/subscribe` with `{ email, source: "homepage" }`
- [ ] Success state: "✅ You're in. First digest arrives Monday." replaces form
- [ ] Mobile responsive — stacks vertically on small screens
- [ ] Error state: shows inline error message below input

---

## Technical Details

### Files to Modify
- `src/app/page.tsx` — add LeadCapture section before closing `</main>` or before footer

### Reuse Pattern
Use the same fetch pattern as `src/app/components/SubscribeBanner.tsx` but inline in the section (no separate component needed — keep it simple).

### API
POST `/api/subscribe` already exists at `src/app/api/subscribe/route.ts`. Update it to also accept and store an optional `source` field — save it to Airtable as a field called `source`.

---

## UI Spec

```
[dark bg section]
  Stay ahead of the power queue.
  Free weekly insights on ERCOT...

  [ your@email.com        ] [ Get Free Insights → ]

  No spam. Unsubscribe anytime.
```

Text colors: white heading, gray-400 subtext, gray-400 fine print.

---

## Out of Scope
- Do NOT add auth
- Do NOT send a welcome email (separate spec)
- Do NOT redesign the homepage
