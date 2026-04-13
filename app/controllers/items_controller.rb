class ItemsController < ApplicationController
  before_action :authenticate_user!, except: %i[ index show ]
  before_action :set_item, only: %i[ show edit update destroy ]
  before_action :ensure_item_visible!, only: :show
  before_action :authorize_item_editor!, only: %i[ edit update ]
  before_action :authorize_item_deletion!, only: :destroy

  def index
    @scope = normalized_marketplace_scope(params[:scope])
    @categories = Category.sorted_for_dropdown
    base = apply_marketplace_scope(@scope, marketplace_listing_relation)

    price_floor_hkd = Item.minimum(:price)&.to_d || 0.to_d
    price_ceiling_hkd = Item.maximum(:price)&.to_d || 100_000.to_d

    @price_floor = convert_price_from_hkd(price_floor_hkd).floor.round(2)
    @price_ceiling = convert_price_from_hkd(price_ceiling_hkd).ceil

    submitted_in_current_currency = params[:price_currency] == current_currency_code
    requested_min = submitted_in_current_currency && params[:min_price].present? ? params[:min_price].to_d : nil
    requested_max = submitted_in_current_currency && params[:max_price].present? ? params[:max_price].to_d : nil

    @min_price = requested_min || @price_floor
    @max_price = requested_max || @price_ceiling

    @min_price = [ @min_price, @max_price ].min
    @max_price = [ @min_price, @max_price ].max
    @price_filter_active = (@min_price != @price_floor || @max_price != @price_ceiling)

    min_price_hkd = convert_price_to_hkd(@min_price)
    max_price_hkd = convert_price_to_hkd(@max_price)
    @items = base.where(price: min_price_hkd..max_price_hkd).order(created_at: :desc)
    preload_favorited_item_ids(@items)
  end

  def show
    @active_transaction_offer = @item.active_transaction_offer if @item.reserved_for_transaction?
    @existing_offer = current_user.offers_made.not_declined.find_by(item: @item) if user_signed_in? && current_user != @item.user
    @seller_live_items_count = @item.user.items.available.count

    if user_signed_in? && current_user.has_location? && @item.has_location?
      user_location = current_user.location_coordinates
      @distance = @item.distance_from(user_location)
      @walking_distance = @item.walking_distance_from(user_location)
      @walking_time_minutes = LocationService.estimate_walking_minutes(@walking_distance)
      @distance_text = distance_text(@walking_distance)
    end

    # Nearby listings make the item page feel more complete without extra queries in the view.
    if @item.has_location?
      @nearby_items = Item.available.where.not(id: @item.id)
                         .where.not(latitude: nil, longitude: nil)
                         .select do |item|
                           distance = LocationService.calculate_distance(
                             @item.latitude, @item.longitude,
                             item.latitude, item.longitude
                           )
                           distance <= 1.5
                         end
                         .first(5)
    end

    preload_favorited_item_ids([ @item, *@nearby_items.to_a ])
  end

  def new
    @item = Item.new
  end

  def edit
  end

  def create
    @item = Item.new(item_params)

    @item.user = current_user
    @item.college = current_user.college unless current_user.admin?
    normalize_price_to_hkd(@item)

    respond_to do |format|
      if @item.save
        format.html { redirect_to item_url(@item), notice: "Item was successfully created." }
        format.json { render :show, status: :created, location: @item }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @item.assign_attributes(item_params)
    normalize_price_to_hkd(@item)

    respond_to do |format|
      if @item.save
        format.html { redirect_to @item, notice: "Item was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @item.destroy!
    redirect_target = params[:return_to] == "dashboard" ? dashboard_path : items_path

    respond_to do |format|
      format.html { redirect_to redirect_target, notice: "Item was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

    def set_item
      @item = Item.find(params.expect(:id))
    end

    def item_params
      permitted_attributes = [ :title, :price, :description, :category_id, :is_global, :latitude, :longitude, :location_name, images: [] ]
      permitted_attributes.insert(4, :college_id) if current_user&.admin?

      params.require(:item).permit(*permitted_attributes)
    end

    def authorize_item_editor!
      if item_owner? && @item.reserved_for_transaction?
        redirect_to @item, alert: "You can't edit an item involved in a transaction!"
        return
      end

      return if item_owner?

      redirect_to @item, alert: "Only the seller can edit this item."
    end

    def authorize_item_deletion!
      return if can_delete_item?

      redirect_to @item, alert: "You are not allowed to delete this item."
    end

    def item_owner?
      @item.user == current_user
    end

    def can_delete_item?
      item_owner? ||
        current_user.admin? ||
        (current_user.college_admin? && @item.college_id == current_user.college_id)
    end

    def ensure_item_visible!
      return if @item.visible_to?(current_user)

      redirect_to items_path, alert: item_visibility_alert
    end

    def item_visibility_alert
      return "This item is no longer available." if @item.removed? || @item.user&.banned?

      "This item is not available."
    end

    def normalize_price_to_hkd(item)
      return if item.price.blank?

      item.price = convert_price_to_hkd(item.price)
    end

    def distance_text(distance)
      return nil unless distance

      if distance < 0.5
        "Very close - Easy walk"
      elsif distance < 1.0
        "Close - About 10-15 min walk"
      elsif distance < 1.5
        "Moderate distance - 20 min walk"
      elsif distance < 2.5
        "Bike recommended"
      else
        "Far - Transport recommended"
      end
    end
end
