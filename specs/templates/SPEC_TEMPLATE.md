# Spec: [Feature Name]

<!--
INSTRUCTIONS FOR HUNTER:
1. Fill in all sections below
2. Be specific — vague specs produce vague code
3. Save this file to /specs/ (not /specs/templates/)
4. The orchestrator picks it up automatically
-->

## Metadata
- **repo:** /home/gilberto/Desktop/Pinehaven Ventures/[target-repo]
- **product:** [Power Queue Tracker | AutoReels | Crypto Log | Pinehaven Website]
- **priority:** [high | medium | low]
- **estimated_complexity:** [small (<2h) | medium (2-8h) | large (8h+)]

---

## What to Build

<!-- One clear paragraph. What is this feature? What problem does it solve? -->

---

## Acceptance Criteria

<!-- Each line is a testable requirement. Claude will verify these are met. -->

- [ ] ...
- [ ] ...
- [ ] ...

---

## Technical Details

### Files to Create / Modify
<!-- List the specific files affected. Be explicit. -->

- `src/components/...` — create/modify
- `src/app/api/...` — create/modify

### API / Data Contracts
<!-- If this touches an API, define the request/response shape. -->

```typescript
// Example:
interface MyRequest {
  id: string;
}
```

### Edge Cases to Handle
<!-- What should happen in error states, empty states, loading states? -->

- Empty state: ...
- Error state: ...
- Loading state: ...

---

## UI Behavior (if applicable)

<!-- Describe what the user sees. Reference existing components where possible. -->

---

## Tests Required

<!-- What automated tests should be written? -->

- Unit test: ...
- Integration test: ...

---

## Out of Scope

<!-- Explicitly list what NOT to build. Prevents scope creep. -->

- Do NOT ...
- Do NOT ...

---

## References

<!-- Link to relevant existing files, docs, or prior specs. -->

- Dark Factory Plan: `/src/app/reference/dark-factory-transition-plan/page.tsx`
- Stripe Spec: `/src/app/reference/stripe-integration-spec/page.tsx`
