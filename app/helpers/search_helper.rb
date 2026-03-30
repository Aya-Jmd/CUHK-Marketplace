module SearchHelper
  SEARCH_SORT_OPTIONS = [
    ["Newest first", "recent"],
    ["Oldest first", "oldest"],
    ["Price: Low to High", "price_low"],
    ["Price: High to Low", "price_high"]
  ].freeze

  def search_sort_options
    SEARCH_SORT_OPTIONS
  end

  def search_filter_state(query:, scope:, sort:, selected_category:, price_filter_active:, min_price:, max_price:, price_currency:)
    state = { q: query.presence, scope: scope, sort: sort }
    state[:category_id] = selected_category.id if selected_category.present?

    if price_filter_active
      state[:price_currency] = price_currency
      state[:min_price] = min_price
      state[:max_price] = max_price
    end

    state.compact
  end

  def search_state_path(state, **overrides)
    params = state.merge(overrides)
    params.delete(:category_id) if overrides.key?(:category_id) && overrides[:category_id].blank?
    search_path(params.compact)
  end

  def search_clear_path(query, scope)
    search_path(q: query.presence, scope: marketplace_scope(scope))
  end

  def search_result_heading(query:, selected_category:, result_count:)
    if query.present?
      return %(No result for "#{query}".) if result_count.zero?
      return %(Result for "#{query}" (1)) if result_count == 1

      %(Results for "#{query}" (#{result_count}))
    elsif selected_category.present?
      return %(No result in #{selected_category.name}.) if result_count.zero?
      return %(Result in #{selected_category.name} (1)) if result_count == 1

      %(Results in #{selected_category.name} (#{result_count}))
    else
      return "No available result." if result_count.zero?
      return "All marketplace results (1)" if result_count == 1

      "All marketplace results (#{result_count})"
    end
  end

  def search_result_subcopy(query:, selected_category:, sort:)
    if query.present?
      if selected_category.present?
        "Filtered to #{selected_category.name} and ordered by #{search_sort_label(sort)}."
      else
        "Showing available marketplace listings that match your search."
      end
    elsif selected_category.present?
      "Showing available listings in #{selected_category.name}."
    else
      "Search by keyword, category, or campus scope."
    end
  end

  def search_sort_label(sort)
    {
      "recent" => "latest updates",
      "oldest" => "oldest listings",
      "price_low" => "lowest price first",
      "price_high" => "highest price first"
    }.fetch(sort, "latest updates")
  end

  def search_scope_label(scope)
    marketplace_scope_label(scope)
  end

  def search_active_filters?(selected_category:, sort:, price_filter_active:)
    selected_category.present? || sort != "recent" || price_filter_active
  end
end
