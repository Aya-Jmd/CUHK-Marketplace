class ItemsController < ApplicationController
  before_action :set_item, only: %i[ show edit update destroy ]
  before_action :authorize_item_owner!, only: %i[ edit update destroy ]

  # GET /items or /items.json
  def index
    # FILTERING PRODUCTS DEPENDING ON MIN / MAX PRICE (set by user)
    # CONSTANTS (global max and min prices, defaulting to values if DB is empty)
    @PRICE_FLOOR = Item.minimum(:price).to_i || 0
    @PRICE_CEILING = Item.maximum(:price).to_i || 100000

    @min_price = params.fetch(:min_price, @PRICE_FLOOR)
    @max_price = params.fetch(:max_price, @PRICE_CEILING)
    
    @items = Item.where(price: @min_price..@max_price)
  
  end

  # GET /items/1 or /items/1.json
  def show
  end

  # GET /items/new
  def new
    @item = Item.new
  end

  # GET /items/1/edit
  def edit
  end

  # POST /items or /items.json
  def create
    @item = Item.new(item_params)
    
    # Securely assign the item to the currently logged-in user and their college
    @item.user = current_user
    @item.college = current_user.college 

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

  # PATCH/PUT /items/1 or /items/1.json
  def update
    respond_to do |format|
      if @item.update(item_params)
        format.html { redirect_to @item, notice: "Item was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1 or /items/1.json
  def destroy
    @item.destroy!

    respond_to do |format|
      format.html { redirect_to items_path, notice: "Item was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def item_params
      params.require(:item).permit(:title, :price, :description, :category_id, :is_global, :latitude, :longitude)
    end

    def authorize_item_owner!
      return if @item.user == current_user

      redirect_to @item, alert: "You are not allowed to modify this item."
    end
end
