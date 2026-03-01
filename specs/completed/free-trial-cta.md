# Spec: Power Queue Tracker — Free Trial CTA Button

## Metadata
- **repo:** /home/gilberto/Desktop/Pinehaven Ventures/pinehaven-ventures-website
- **product:** Power Queue Tracker
- **priority:** high
- **estimated_complexity:** small
- **task_type:** code

---

## What to Build

The current Power Queue Tracker page only has paid "Get Started" Stripe checkout buttons. Add a "Start Free Trial" primary CTA in the hero section that captures email before asking for payment. This is the single highest-leverage conversion change — most SaaS converts 3-5x better with a trial CTA vs. a direct pay wall.

---

## Acceptance Criteria

- [ ] A prominent "Start Free 14-Day Trial →" button appears in the hero section alongside (or above) the existing pricing badges
- [ ] Clicking opens a modal with: heading "Start your free trial", email input, "Start Trial →" button
- [ ] On submit: POST to `/api/subscribe` with `{ email, source: "free-trial-cta", tier: "trial" }`
- [ ] Success: modal closes, shows toast or inline message "Check your inbox — trial access on the way!"
- [ ] Modal has X close button and closes on backdrop click
- [ ] The button styling: `bg-blue-600 text-white px-8 py-4 rounded-xl font-bold text-lg hover:bg-blue-700` — it should be the largest CTA on the page
- [ ] Mobile responsive modal

---

## Technical Details

### Files to Modify
- `src/app/ventures/power-queue-tracker/page.tsx` — add TrialModal component (inline, not a separate file) and trigger button in hero

### Modal Pattern
```typescript
'use client';
const [showModal, setShowModal] = useState(false);
// Render modal as fixed overlay with backdrop
```

### API
POST to existing `/api/subscribe` route. Pass `tier: "trial"` in the body. The route should save `tier` to Airtable if provided (currently hardcodes "Free" — change to use the `tier` field from the request body, defaulting to "Free").

---

## Out of Scope
- Do NOT actually provision trial access (email capture only for now)
- Do NOT integrate with Stripe trials yet
- Do NOT send a welcome email (separate spec)
