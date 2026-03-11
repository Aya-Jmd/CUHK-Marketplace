class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def category_prices
    @categories = Category.order(:name)
    @selected_category_id = params[:category_id] || @categories.first&.id

    @start_date = (params[:start_date] || 30.days.ago.to_date).to_date
    @end_date   = (params[:end_date] || Date.today).to_date

    return if @selected_category_id.blank?

    category = Category.find(@selected_category_id)
    @selected_category_name = category.name
    all_dates = (@start_date..@end_date).to_a

    posted = Item.where(category: category)
                 .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                 .group("DATE(created_at)")
                 .average(:price)

    sold = Item.where(category: category)
               .where.not(sold_at: nil)
               .where(sold_at: @start_date.beginning_of_day..@end_date.end_of_day)
               .group("DATE(sold_at)")
               .average(:price)

    posted_items = Item.where(category: category)
                       .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                       .order(:created_at)

    sold_items = Item.where(category: category)
                     .where.not(sold_at: nil)
                     .where(sold_at: @start_date.beginning_of_day..@end_date.end_of_day)
                     .order(:sold_at)

    @labels = all_dates
    @avg_posted = @labels.map { |day| posted[day] || 0 }
    @avg_sold = @labels.map { |day| sold[day] || 0 }
    @posted_points = posted_items.map do |item|
      { x: @labels.index(item.created_at.to_date), y: item.price.to_f, title: item.title, day: item.created_at.to_date.to_s }
    end
    @sold_points = sold_items.map do |item|
      { x: @labels.index(item.sold_at.to_date), y: item.price.to_f, title: item.title, day: item.sold_at.to_date.to_s }
    end
  end
end
