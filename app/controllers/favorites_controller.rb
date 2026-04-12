class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item

  def create
    unless @item.visible_to?(current_user)
      redirect_to items_path, alert: "This item is no longer available."
      return
    end

    current_user.favorites.create_or_find_by!(item: @item)
    respond_to_toggle("Added to favorites.")
  end

  def destroy
    current_user.favorites.where(item: @item).destroy_all
    respond_to_toggle("Removed from favorites.")
  end

  private

  def set_item
    @item = Item.find(params[:item_id])
  end

  def respond_to_toggle(notice)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: favorite_turbo_streams }
      format.html { redirect_back fallback_location: item_path(@item), notice: notice }
    end
  end

  def favorite_turbo_streams
    context = params[:context].to_s

    if context == "dashboard_favorites"
      favorite_items = current_user.favorited_items.available
        .includes(:college, :category, :user)
        .with_attached_images
        .order("favorites.created_at DESC")

      preload_favorited_item_ids(favorite_items)

      [
        turbo_stream.replace(
          "dashboard_favorite_items_section",
          partial: "users/favorite_items_section",
          locals: { favorite_items: favorite_items }
        )
      ]
    else
      preload_favorited_item_ids([ @item ])

      [
        turbo_stream.replace(
          view_context.favorite_button_dom_id(@item, context),
          partial: "items/favorite_button",
          locals: { item: @item, favorite_context: context }
        )
      ]
    end
  end
end
