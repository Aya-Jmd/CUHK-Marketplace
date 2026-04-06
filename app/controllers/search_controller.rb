class SearchController < ApplicationController
  before_action :authenticate_user!

  def index
    @categories = Category.sorted_for_dropdown
    @query = params[:q].to_s.strip
    @scope = normalized_marketplace_scope(params[:scope])
    @sort = params[:sort].presence || "recent"
    @selected_category = Category.find_by(id: params[:category_id])

    base = apply_marketplace_scope(@scope, marketplace_listing_relation)

    base = base.where(category_id: @selected_category.id) if @selected_category.present?

    price_floor_hkd = 0.to_d
    price_ceiling_hkd = Item.maximum(:price)&.to_d || 100_000.to_d
    price_ceiling_hkd = 1.to_d if price_ceiling_hkd <= price_floor_hkd

    @price_floor = convert_price_from_hkd(price_floor_hkd).floor
    @price_ceiling = convert_price_from_hkd(price_ceiling_hkd).ceil

    submitted_in_current_currency = params[:price_currency] == current_currency_code
    requested_min = submitted_in_current_currency && params[:min_price].present? ? params[:min_price].to_d : nil
    requested_max = submitted_in_current_currency && params[:max_price].present? ? params[:max_price].to_d : nil

    @min_price = requested_min || @price_floor
    @max_price = requested_max || @price_ceiling

    @min_price = [ [ @min_price, @price_floor ].max, @price_ceiling ].min
    @max_price = [ [ @max_price, @price_floor ].max, @price_ceiling ].min
    @min_price = [ @min_price, @max_price ].min
    @max_price = [ @min_price, @max_price ].max
    @price_filter_active = (@min_price != @price_floor || @max_price != @price_ceiling)

    min_price_hkd = convert_price_to_hkd(@min_price)
    max_price_hkd = convert_price_to_hkd(@max_price)
    base = base.where(price: min_price_hkd..max_price_hkd)

    @results =
      if @query.present?
        apply_sort(base.intelligent_search(@query)).limit(100)
      else
        apply_sort(base).limit(100)
      end
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
