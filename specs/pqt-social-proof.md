# Spec: Power Queue Tracker — Social Proof & Trust Bar

## Metadata
- **repo:** /home/gilberto/Desktop/Pinehaven Ventures/pinehaven-ventures-website
- **product:** Power Queue Tracker
- **priority:** high
- **estimated_complexity:** medium

---

## What to Build

Add a social proof / trust signals bar to the Power Queue Tracker venture page (`src/app/ventures/power-queue-tracker/page.tsx`). It should appear directly below the hero section. This reduces friction for new visitors and increases conversion to paid plans. Also add an FAQ section above the footer.

---

## Acceptance Criteria

- [ ] A trust bar with 4 stats appears below the hero, white background with subtle border
- [ ] Stats:
  - "5,000+ MW tracked weekly"
  - "ERCOT queue data updated daily"
  - "14-day free trial, no card required"
  - "Cancel anytime"
- [ ] Each stat has a bold number/value and a small gray label beneath
- [ ] An FAQ section titled "Common Questions" appears before the page footer with 5 Q&As:
  1. Q: "What data does Power Queue Tracker monitor?" A: "We track the ERCOT generation interconnection queue, including new filings, MW changes, county locations, status updates, and queue position movements."
  2. Q: "How is the data delivered?" A: "Weekly email digests summarizing what changed, plus access to the live dashboard with full search, filter, and CSV export."
  3. Q: "How current is the data?" A: "Our pipeline refreshes the ERCOT queue data daily. You'll see changes within 24 hours of ERCOT publishing them."
  4. Q: "Can I cancel anytime?" A: "Yes. Cancel from your account dashboard anytime with no fees or penalties."
  5. Q: "Do you cover PJM or other markets?" A: "ERCOT is the current focus. PJM and CAISO are on the roadmap for Q2 2026."
- [ ] FAQ uses an accordion pattern — clicking a question reveals/hides the answer
- [ ] Mobile responsive

---

## Technical Details

### Files to Modify
- `src/app/ventures/power-queue-tracker/page.tsx` — add TrustBar after hero section, add FAQ before closing `</div>`

### Accordion
Use React `useState` to track which FAQ item is open. No external library.

```typescript
const [openFaq, setOpenFaq] = useState<number | null>(null);
```

---

## Out of Scope
- Do NOT change pricing
- Do NOT add real customer testimonials (placeholders are fine for now)
- Do NOT add a chat widget
