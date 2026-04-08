---
name: programmatic-seo
description: >
  SEO at scale — generating hundreds of pages from templates per keyword pattern.
  "[service] + [city]", "[product] vs [product]", "[tool] for [industry]".
  Triggers: "programmatic SEO", "SEO at scale", "template pages", "generate SEO pages",
  "local pages", "city+service", "vs pages", "comparisons", "bulk pages".
---

# Programmatic SEO — Template Pages at Scale

Generating hundreds/thousands of pages from templates targeting long-tail keywords. Proven SaaS tactic: Zapier (integrations pages), Wise (currency pages), Nomadlist (city pages).

## When to Use

- Product has a repeatable keyword pattern (service x city, tool x industry)
- You want to cover hundreds of long-tail keywords with a single template
- You have structured data (city database, integration list, industry catalog)
- User says: "programmatic SEO", "local pages", "bulk pages"

## Dependencies

- **Optional:** `analytics-tracking` — traffic and conversion measurement for generated pages

## Patterns

### Pattern 1: [Service] + [City]
**For:** local services, agencies, SaaS with local focus
```
/services/seo-consulting-new-york
/services/seo-consulting-los-angeles
/services/seo-consulting-chicago
```
**Data:** list of cities x list of services
**Template:** H1 with city, local social proof, map, regional CTA

### Pattern 2: [Product] vs [Competitor]
**For:** SaaS with recognizable competition
```
/comparisons/product-vs-mailchimp
/comparisons/product-vs-sendinblue
/comparisons/product-vs-convertkit
```
**Data:** list of competitors x comparison criteria
**Template:** comparison table, feature-by-feature, verdict

### Pattern 3: [Tool] for [Industry]
**For:** horizontal SaaS with vertical use cases
```
/solutions/crm-for-marketing-agencies
/solutions/crm-for-real-estate
/solutions/crm-for-training-companies
```
**Data:** list of industries x feature highlights per industry
**Template:** industry case study, specific features, industry jargon

### Pattern 4: [Integration] + [Product]
**For:** SaaS with many integrations
```
/integrations/slack
/integrations/google-sheets
/integrations/zapier
```
**Data:** list of integrations x workflow description
**Template:** how to connect, use cases, setup guide

### Pattern 5: Glossary
**For:** industries with extensive terminology
```
/glossary/roi-return-on-investment
/glossary/cac-customer-acquisition-cost
/glossary/ltv-lifetime-value
```
**Data:** list of terms x definitions
**Template:** definition, formula, example, related terms

## Implementation in Next.js

### Step 1: Prepare Data

```typescript
// src/data/cities.ts
export const cities = [
  { name: "New York", slug: "new-york", population: 8336000, region: "northeast" },
  { name: "Los Angeles", slug: "los-angeles", population: 3979000, region: "west" },
  // ...
];

// src/data/services.ts
export const services = [
  { name: "SEO Consulting", slug: "seo-consulting", description: "..." },
  { name: "Web Development", slug: "web-development", description: "..." },
];
```

### Step 2: Dynamic Route

```typescript
// src/app/services/[service]-[city]/page.tsx
import { cities } from "@/data/cities";
import { services } from "@/data/services";

export function generateStaticParams() {
  return cities.flatMap(city =>
    services.map(service => ({
      "service-city": `${service.slug}-${city.slug}`,
    }))
  );
}

export function generateMetadata({ params }) {
  const { city, service } = parseParams(params);
  return {
    title: `${service.name} ${city.name} — Acme Inc. | Local Experts`,
    description: `${service.name} in ${city.name}. ${service.description} Check our offer →`,
  };
}
```

### Step 3: Page Template

Each generated page MUST have:
1. **Unique H1** with keyword + location
2. **Min. 300 words** of unique content (not just a changed city name)
3. **Local social proof** (if available)
4. **Schema markup** (LocalBusiness or Service)
5. **Internal links** to 3+ related pages
6. **CTA** tailored to context

### Step 4: Anti-thin Content

**Problem:** 100 pages with identical content and only a changed city = thin content → penalty.

**Solution — uniqueness layers:**

| Layer | Description | Min. % unique content |
|-------|-------------|----------------------|
| 1 — Variables | City, region, local data | 10% |
| 2 — Conditional | Sections visible only for selected cities/industries | 20% |
| 3 — Data-driven | Local statistics, prices, demographic data | 20% |
| 4 — AI-generated | Unique paragraphs per combination (batch generate) | 30% |

**Goal:** min. 50% unique content per page. The rest is shared template.

## Quality Gates

Before publishing, verify:

- [ ] Min. 300 words per page (500+ preferred)
- [ ] Unique title and meta description per page
- [ ] Min. 50% unique content (not just variables)
- [ ] Schema markup (BreadcrumbList + page type)
- [ ] Canonical URL set correctly
- [ ] Internal links to 3+ pages
- [ ] Sitemap contains all generated pages
- [ ] robots.txt doesn't block generated pages
- [ ] No duplicate content (check a sample of 10 pages)

## Scaling

| Scale | Pages | Approach |
|-------|-------|----------|
| Small | 10-50 | Manual data + template |
| Medium | 50-500 | CSV/JSON + generateStaticParams |
| Large | 500-5000 | Database + ISR (revalidate) |
| Mega | 5000+ | On-demand ISR + sitemap index |

## Pitfalls

- **Thin content** — Google penalizes pages with <50% unique content. Don't generate 1,000 pages with only one changed word
- **Canonicalization** — each generated page has its own canonical. Don't point to a shared page
- **Sitemap** — with 5,000+ pages, use a sitemap index (max 50k URLs per sitemap)
- **noindex test pages** — don't index pages with placeholder data
- **Incremental** — start with 10-20 pages, check if Google indexes them, then scale
