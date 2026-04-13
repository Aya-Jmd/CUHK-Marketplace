class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @favorite_items = current_user.favorited_items.available
      .includes(:college, :category, :user)
      .with_attached_images
      .order("favorites.created_at DESC")
    preload_favorited_item_ids(@favorite_items)
    render "users/show"
  end

  def edit
    @user = current_user
    render "users/edit"
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully"
    else
      render "users/edit", status: :unprocessable_entity
    end
  end

  CATEGORY_COLORS = [
    "#94a3b8",
    "#23d2ff",
    "#ff7a59",
    "#22c55e",
    "#f59e0b",
    "#a855f7",
    "#6366f1",
    "#ef4444",
    "#14b8a6",
    "#0ea5e9",
    "#8b5cf6",
    "#84cc16",
    "#f97316",
    "#ec4899"
  ].freeze

  DATASET_OPACITY = 0.6

  def category_prices
    @scope = normalized_marketplace_scope(params[:scope])
    @categories = Category.order(:name).to_a
    @selected_category_ids = selected_category_ids(@categories)
    @selected_categories = @categories.select { |category| @selected_category_ids.include?(category.id) }
    @chart_currency_code = current_currency_code
    @chart_mode = selected_chart_mode
    @start_date = (params[:start_date] || 30.days.ago.to_date).to_date
    @end_date = (params[:end_date] || Date.today).to_date
    @labels = (@start_date..@end_date).to_a
    @selected_category_summary = selected_category_summary(@selected_categories)
    @chart_payload = build_chart_payload(@selected_categories)
  end

  private

  def profile_params
    params.require(:user).permit(:pseudo, :default_location, :latitude, :longitude)
  end

  def selected_category_ids(categories)
    requested_ids = Array(params[:category_ids]).reject(&:blank?).map(&:to_i)
    available_ids = categories.map(&:id)
    requested_ids & available_ids
  end

  def selected_category_summary(categories)
    names = categories.map(&:name)

    return "your selected category" if names.empty?
    return names.first if names.one?
    return names.join(", ") if names.size <= 3

    "#{names.size} selected categories"
  end

  def selected_chart_mode
    %w[averages exact].include?(params[:chart_mode]) ? params[:chart_mode] : "averages"
  end

  def build_chart_payload(categories)
    category_ids = categories.map(&:id)
    labels = @labels.map { |day| day.strftime("%Y-%m-%d") }

    return { currency_code: @chart_currency_code, initial_mode: @chart_mode, labels: labels, categories: [] } if category_ids.empty?

    posted_averages = average_prices_by_category(category_ids, :created_at)
    sold_averages = average_prices_by_category(category_ids, :sold_at, sold_only: true)
    posted_points = exact_points_by_category(category_ids, :created_at)
    sold_points = exact_points_by_category(category_ids, :sold_at, sold_only: true)

    {
      currency_code: @chart_currency_code,
      initial_mode: @chart_mode,
      labels: labels,
      categories: categories.map do |category|
        colors = category_colors(category)

        {
          id: category.id,
          name: category.name,
          colors: colors,
          averages: {
            posted: average_series_for_days(posted_averages[category.id]),
            sold: average_series_for_days(sold_averages[category.id])
          },
          exact: {
            posted: posted_points[category.id] || [],
            sold: sold_points[category.id] || []
          }
        }
      end
    }
  end

  def average_prices_by_category(category_ids, date_column, sold_only: false)
    grouped_average_scope(category_ids, date_column, sold_only: sold_only)
      .average(:price)
      .each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |((category_id, day), price), result|
        result[category_id][day.to_date] = convert_price_from_hkd(price).to_f.round(2)
      end
  end

  def grouped_average_scope(category_ids, date_column, sold_only: false)
    scope = analytics_item_scope.where(category_id: category_ids)
    scope = scope.where.not(sold_at: nil) if sold_only
    scope = scope.where(date_column => selected_time_window)

    scope.group(:category_id).group(grouped_date_expression(date_column))
  end

  def exact_points_by_category(category_ids, date_column, sold_only: false)
    day_positions = @labels.each_with_index.to_h
    scope = analytics_item_scope.where(category_id: category_ids)
    scope = scope.where.not(sold_at: nil) if sold_only
    scope = scope.where(date_column => selected_time_window).order(date_column)

    scope.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |item, result|
      timestamp = item.public_send(date_column)
      day = timestamp.to_date

      result[item.category_id] << {
        x: day_positions.fetch(day),
        y: convert_price_from_hkd(item.price).to_f.round(2),
        title: item.title,
        day: day.to_s
      }
    end
  end

  def grouped_date_expression(date_column)
    case date_column
    when :created_at
      Arel.sql("DATE(created_at)")
    when :sold_at
      Arel.sql("DATE(sold_at)")
    else
      raise ArgumentError, "Unsupported date column: #{date_column}"
    end
  end

  def selected_time_window
    @start_date.beginning_of_day..@end_date.end_of_day
  end

  def analytics_item_scope
    @analytics_item_scope ||= apply_marketplace_scope(@scope, Item.all)
  end

  def average_series_for_days(values_by_day)
    @labels.map { |day| values_by_day[day] }
  end

  def category_colors(category)
    posted_hex = CATEGORY_COLORS.fetch(category.id, CATEGORY_COLORS.last)
    sold_hex = blend_hex(posted_hex, "#1f2937", 0.35)

    {
      posted: rgba(posted_hex, DATASET_OPACITY),
      posted_border: rgba(posted_hex, 1.0),
      sold: rgba(sold_hex, DATASET_OPACITY),
      sold_border: rgba(sold_hex, 1.0)
    }
  end

  def rgba(hex_color, alpha)
    red, green, blue = hex_to_rgb(hex_color)
    "rgba(#{red}, #{green}, #{blue}, #{alpha})"
  end

  def blend_hex(source_hex, target_hex, ratio)
    source_red, source_green, source_blue = hex_to_rgb(source_hex)
    target_red, target_green, target_blue = hex_to_rgb(target_hex)

    red = blend_channel(source_red, target_red, ratio)
    green = blend_channel(source_green, target_green, ratio)
    blue = blend_channel(source_blue, target_blue, ratio)

    format("#%02x%02x%02x", red, green, blue)
  end

  def blend_channel(source, target, ratio)
    (source + ((target - source) * ratio)).round
  end

  def hex_to_rgb(hex_color)
    hex = hex_color.delete("#")
    [ hex[0..1], hex[2..3], hex[4..5] ].map { |component| component.to_i(16) }
  end
end
