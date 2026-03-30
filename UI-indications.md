# UI Indications

This file is a map of the main UI pieces in the app.

Use it when you want to know which file to edit for a specific visual or behavior change.

## First rule

Before editing, ask yourself this:

- Is this element shared by multiple pages?
- If yes, edit the shared partial/helper/controller, not one page only.

Important shared pieces:

- Item cards are shared by `items/index` and `search/index`.
- Category boxes are shared by `items/index` and `search/index`.
- The signed-in header is shared.
- The price slider UI is shared.

## Homepage: `items/index`

Main page file:

- `app/views/items/index.html.erb`

Edit this file if you want to change:

- The overall structure of the homepage
- The order of the sections on the homepage
- Whether the page shows hero, category strip, filters card, grid, etc.

## Search page: `search/index`

Main page file:

- `app/views/search/index.html.erb`

Edit this file if you want to change:

- The overall structure of the search results page
- The left/right layout
- The order of the filter sidebar, summary block, and results grid

## Global signed-in header

Header partial:

- `app/views/general/_header.html.erb`

Edit this file if you want to change:

- The top floating header
- The logo `CUHK MRKT`
- The search field in the header
- The currency menu
- The user dropdown

The header styling is in:

- `app/assets/stylesheets/application.css`

Look for selectors starting with:

- `.site-header`
- `.site-header__...`

## Homepage hero section

Hero markup:

- `app/views/items/index.html.erb`

Hero styling:

- `app/assets/stylesheets/application.css`

Look for selectors starting with:

- `.items-hero`
- `.items-hero__...`

## Category boxes

Shared category strip partial:

- `app/views/items/_category_strip.html.erb`

Edit this file if you want to change:

- The category chip markup
- The text shown in each category box
- The click behavior of category boxes
- The active category logic

Category strip styling is in:

- `app/assets/stylesheets/application.css`

Look for selectors starting with:

- `.items-category-strip`
- `.items-category-strip__...`

Important:

- This partial is shared by both `items/index` and `search/index`.
- If you edit it, both pages change.

## Item cards

Shared card partial:

- `app/views/items/_market_card.html.erb`

Edit this file if you want to change:

- The HTML structure of a card
- Where the price appears
- Where the title appears
- Where the description appears
- Whether a placeholder or image is shown

Card helper logic:

- `app/helpers/items_helper.rb`

Edit this file if you want to change:

- How the price text is built
- How the meta line is built
- Currency prefix formatting
- The `Category | College | time ago` line

Card grid wrapper:

- `app/views/items/_market_grid.html.erb`

Edit this file if you want to change:

- How the list of cards is rendered
- Shared card grid wrapper behavior

Card styling is in:

- `app/assets/stylesheets/application.css`

Look for selectors starting with:

- `.market-card`
- `.market-card__...`
- `.items-grid`

Important:

- Item cards are shared by both `items/index` and `search/index`.
- If you want to change card display, start with `_market_card.html.erb`.

## Search bar inside the homepage filter card

Search bar partial:

- `app/views/search/_search_bar.html.erb`

Edit this file if you want to change:

- The search input under the homepage category strip
- The campus scope dropdown
- The search button in that block

## Search page result summary

Summary partial:

- `app/views/search/_results_summary.html.erb`

Helper methods used by that partial:

- `app/helpers/search_helper.rb`

Edit these files if you want to change:

- The `Results for ...` / `No result for ...` text
- The subtext under the title
- The chips shown under the title
- The clear-all link in the summary

## Search filter sidebar

Sidebar partial:

- `app/views/search/_filter_sidebar.html.erb`

Edit this file if you want to change:

- The order of filter groups
- The presence of Price / Sort / Scope / Category sections
- The links shown inside each filter group
- The clear-all button in the sidebar

Sidebar styling is in:

- `app/assets/stylesheets/application.css`

Look for selectors starting with:

- `.search-results-page__sidebar`
- `.search-results-page__filter-group`
- `.search-results-page__filter-summary`
- `.search-results-page__filter-link`

## Price slider

Shared slider markup:

- `app/views/shared/_price_range_filter.html.erb`

Homepage slider wrapper:

- `app/views/items/_price_slider.html.erb`

Search sidebar slider wrapper:

- `app/views/search/_price_filter.html.erb`

Shared slider JavaScript:

- `app/javascript/controllers/range_slider_controller.js`

Search filter open/closed state:

- `app/javascript/controllers/filter_state_controller.js`

Edit these files if you want to change:

- Slider markup
- Hidden fields submitted with the slider
- Slider auto-submit behavior
- Slider label updates
- Slider min/max initialization
- Remembering open filter groups after refresh

Slider styling is in:

- `app/assets/stylesheets/application.css`

Look for selectors starting with:

- `.items-price-slider`
- `.items-price-label`
- `.items-price-actions`
- `.search-results-page__price-slider`
- `.search-results-page__price-label`

Important:

- The visual slider component is shared.
- The homepage and search page use small wrapper partials around the same core slider partial.

## Search page behavior and filtering logic

Search controller:

- `app/controllers/search_controller.rb`

Search helper:

- `app/helpers/search_helper.rb`

Edit these files if you want to change:

- How search results are filtered
- Category filtering
- Scope filtering
- Price filtering
- Sorting
- The search page default state
- The title/subcopy logic for search results

## Currency conversion logic used by prices

Card prices depend on:

- `app/helpers/items_helper.rb`

Search and items price ranges also depend on controller conversion methods in:

- `app/controllers/search_controller.rb`
- `app/controllers/items_controller.rb`

Edit those files if you want to change:

- Which currency is displayed
- How price ranges are interpreted
- How converted values are used for filtering

## CSS: where most visual changes happen

Main stylesheet:

- `app/assets/stylesheets/application.css`

If you only want to change visual appearance, this is often the only file you need.

Examples:

- Card colors, radius, spacing, hover effects
- Header spacing and colors
- Category chip colors
- Search sidebar width and sticky behavior
- Slider appearance
- Typography and margins

## Quick guide: "I want to change..."

I want to change the cards:

- `app/views/items/_market_card.html.erb`
- `app/helpers/items_helper.rb`
- `app/assets/stylesheets/application.css`

I want to change card spacing / cards per row:

- `app/views/items/_market_grid.html.erb`
- `app/assets/stylesheets/application.css`

I want to change the category boxes:

- `app/views/items/_category_strip.html.erb`
- `app/assets/stylesheets/application.css`

I want to change the header:

- `app/views/general/_header.html.erb`
- `app/assets/stylesheets/application.css`

I want to change the homepage hero:

- `app/views/items/index.html.erb`
- `app/assets/stylesheets/application.css`

I want to change the search sidebar filters:

- `app/views/search/_filter_sidebar.html.erb`
- `app/helpers/search_helper.rb`
- `app/controllers/search_controller.rb`

I want to change the price slider:

- `app/views/shared/_price_range_filter.html.erb`
- `app/views/items/_price_slider.html.erb`
- `app/views/search/_price_filter.html.erb`
- `app/javascript/controllers/range_slider_controller.js`
- `app/assets/stylesheets/application.css`

I want to change the search page title text:

- `app/views/search/_results_summary.html.erb`
- `app/helpers/search_helper.rb`

I want to change search filtering logic:

- `app/controllers/search_controller.rb`

## Recommended workflow

When you want to change a UI element:

1. Find it in this file.
2. Start with the shared partial if the element appears in multiple places.
3. Then adjust the helper if the text/logic is generated.
4. Then adjust `application.css` for the final look.

## Safe rule

If two pages show the same component, do not duplicate code.

Edit the shared file instead.

## Current modified/new files in git status

This section is here so you can remember what the recent changes are for.

When `git status` shows one of the files below, this is what it currently controls.

### Stylesheet

- `app/assets/stylesheets/application.css`
  Main stylesheet for all recent UI work. It now contains the styling for:
  header, homepage hero, category chips, shared item cards, search sidebar, shared price slider, search summary card, and the side slider.

### Controllers

- `app/controllers/items_controller.rb`
  Controls homepage item listing data on `items/index`.
  It now prepares:
  categories, homepage items, and homepage price slider bounds and filtering.

- `app/controllers/search_controller.rb`
  Controls search results data on `search/index`.
  It now prepares:
  query, selected category, scope, sort, global price range, active price filter state, and the final filtered/sorted result list.

### Helpers

- `app/helpers/items_helper.rb`
  Shared presentation helper for item cards.
  It formats:
  card price text and the card meta line.

- `app/helpers/search_helper.rb`
  Shared helper for search-page UI logic.
  It centralizes:
  sort options, scope options, search-state params, search result heading text, search subcopy text, and "clear all" related logic.

### Layout and global partials

- `app/views/layouts/application.html.erb`
  Global layout wrapper.
  It loads:
  the noUiSlider library, the global stylesheet/importmap, the shared header, and the shared side slider.

- `app/views/general/_header.html.erb`
  Shared signed-in header used across pages.
  It owns:
  the floating pill header, header search, logo, currency selector, and user dropdown.

- `app/views/general/_side_slider.html.erb`
  Shared quick-action rail on the right side of the page.
  It currently renders:
  the floating purple side handle and the Financial Analytics quick link.

### Homepage files

- `app/views/items/index.html.erb`
  Main homepage composition file.
  It now assembles:
  hero, shared category strip, homepage search block, homepage price filter, and shared item grid.

- `app/views/items/_price_slider.html.erb`
  Homepage-specific wrapper around the shared price slider partial.
  It defines:
  homepage slider params such as reset path and whether the Apply button is shown.

- `app/views/search/_search_bar.html.erb`
  Search bar block rendered inside the homepage filter card.
  It owns:
  the homepage search input, scope dropdown, and search button.

### Search page files

- `app/views/search/index.html.erb`
  Main search-page composition file.
  It now assembles:
  search hero band, shared category strip, sticky filter sidebar, search summary card, and shared item grid.

- `app/views/search/_filter_sidebar.html.erb`
  Sticky left filter menu for the search page.
  It owns:
  the Price, Sort by, Scope, and Category filter groups plus the sidebar clear-all link.

- `app/views/search/_price_filter.html.erb`
  Search-specific wrapper around the shared price slider partial.
  It defines:
  search slider hidden fields, reset path, and auto-submit behavior.

- `app/views/search/_results_summary.html.erb`
  Search result heading block above the results grid.
  It renders:
  the main result title, subcopy, active chips, and clear-all link.

### Shared UI partials

- `app/views/items/_category_strip.html.erb`
  Shared category chip strip used on both homepage and search page.
  It controls:
  category chip rendering, active category state, and the toggle back to "all categories".

- `app/views/items/_market_card.html.erb`
  Shared item card partial used on both homepage and search page.
  It controls:
  card markup, title, price, meta line, and description layout.

- `app/views/items/_market_grid.html.erb`
  Shared wrapper that renders a collection of shared item cards.
  It controls:
  the common grid container used by homepage and search page.

- `app/views/shared/_price_range_filter.html.erb`
  Shared core price-slider partial.
  It controls:
  slider markup, hidden fields, slider label, apply button slot, and reset link slot.

Note:

- `git status` may show `app/views/shared/` as new because this folder now contains the shared partial above.

### JavaScript controllers

- `app/javascript/controllers/range_slider_controller.js`
  Shared Stimulus controller for the price sliders.
  It initializes:
  the noUiSlider instance, updates hidden min/max inputs, updates the visible range label, and optionally auto-submits the form.

- `app/javascript/controllers/filter_state_controller.js`
  Search sidebar state persistence controller.
  It remembers:
  which filter groups are open or closed, even after the page refreshes.

- `app/javascript/controllers/glass_header_controller.js`
  Floating-header behavior controller.
  It handles:
  the scroll-based shrink/transition behavior of the glass header.

## Quick reminder: which changes are shared?

If you edit one of these, multiple pages change:

- `app/views/items/_market_card.html.erb`
- `app/views/items/_market_grid.html.erb`
- `app/views/items/_category_strip.html.erb`
- `app/views/shared/_price_range_filter.html.erb`
- `app/helpers/items_helper.rb`
- `app/helpers/search_helper.rb`
- `app/views/general/_header.html.erb`
- `app/assets/stylesheets/application.css`

## Quick reminder: which files are mostly page composition?

These files mostly assemble other shared pieces:

- `app/views/items/index.html.erb`
- `app/views/search/index.html.erb`
