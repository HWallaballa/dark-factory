# Spec: Power Queue Tracker — Add Subscribe CTA to Dashboard

## Metadata
- **repo:** /home/gilberto/Desktop/Pinehaven Ventures/Power Queue Tracker/web
- **product:** Power Queue Tracker
- **priority:** high
- **estimated_complexity:** small (<2h)

---

## What to Build

Add a persistent "Subscribe for weekly email digests" call-to-action banner to the Power Queue Tracker dashboard. The banner should appear at the top of the data table for unauthenticated visitors and disappear once someone submits their email. Captured emails should be saved to the Airtable Subscribers table.

---

## Acceptance Criteria

- [ ] A blue banner appears above the data table with: "Get weekly ERCOT queue changes in your inbox — free." and an email input + "Subscribe" button
- [ ] Submitting a valid email POSTs to `/api/subscribe` and shows a "Thanks! Check your inbox." confirmation
- [ ] Invalid/empty email shows an inline error: "Please enter a valid email address"
- [ ] The banner does not appear if a `subscribed=true` cookie is set (persists 365 days)
- [ ] The `/api/subscribe` route writes the email to the Airtable Subscribers table with `{ email, plan: "free", createdAt: now, active: true }`
- [ ] Mobile responsive — banner stacks vertically on screens < 640px

---

## Technical Details

### Files to Create / Modify

- `src/components/SubscribeBanner.tsx` — create new component
- `src/app/dashboard/page.tsx` — import and render SubscribeBanner above the table
- `src/app/api/subscribe/route.ts` — create new API route

### API Contract

```typescript
// POST /api/subscribe
// Request body:
{ email: string }

// Success response (200):
{ success: true }

// Error response (400):
{ error: string }
```

### Airtable write (using existing AirtableClient pattern):

```typescript
await airtable.createSubscriber({
  email,
  plan: 'free',
  createdAt: new Date(),
  active: true,
});
```

### Environment variables available:
- `AIRTABLE_TOKEN` — in `web/.env.local`
- `AIRTABLE_BASE_ID` — in `web/.env.local`

---

## UI Behavior

- Banner background: `bg-blue-600` text white, full width
- Input: standard `<input type="email">` with placeholder "your@email.com"
- Button: white background, blue text, "Subscribe →"
- Success state: replace banner content with "✅ You're subscribed! Digest arrives every Monday."
- On success: set cookie `subscribed=true; max-age=31536000; path=/`

---

## Tests Required

- Unit test for email validation logic
- API route test: valid email → 200, invalid email → 400, duplicate → 200 (idempotent)

---

## Out of Scope

- Do NOT build a full auth system
- Do NOT send a confirmation email (Resend integration is a separate spec)
- Do NOT add unsubscribe flow yet

---

## References

- Dashboard: `/home/gilberto/Desktop/Pinehaven Ventures/Power Queue Tracker/web/src/app/dashboard/page.tsx`
- Shared types: `/home/gilberto/Desktop/Pinehaven Ventures/Power Queue Tracker/shared/src/types.ts`
