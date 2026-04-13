class SearchController < ApplicationController
  def index
    @categories = Category.sorted_for_dropdown
    @query = params[:q].to_s.strip
    @scope = normalized_marketplace_scope(params[:scope])
    @sort = params[:sort].presence || "recent"
    @selected_category = Category.find_by(id: params[:category_id])

    base = apply_marketplace_scope(@scope, marketplace_listing_relation)

    base = base.where(category_id: @selected_category.id) if @selected_category.present?

    price_scope = @query.present? ? base.intelligent_search(@query) : base
    configure_price_filter_from_scope(price_scope)

    min_price_hkd = convert_price_to_hkd(@min_price)
    max_price_hkd = convert_price_to_hkd(@max_price)
    @results = apply_sort(price_scope.where(price: min_price_hkd..max_price_hkd)).limit(100)
  end

  private

  def apply_sort(scope)
    case @sort
    when "oldest"
      scope.order(created_at: :asc)
    when "price_low"
      scope.order(price: :asc, updated_at: :desc)
    when "price_high"
      scope.order(price: :desc, updated_at: :desc)
    else
      scope.order(updated_at: :desc)
    end
  end
end
