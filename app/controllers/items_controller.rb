class ItemsController < ApplicationController
  before_action :set_item, only: %i[ show edit update destroy ]

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
    # Old way of creating item, invalid. Item needs college and user association.
    # @item = Item.new(item_params).

    # creating an item associated with the current user directly
    @item = current_user.items.build(item_params) 
    @item.college_id = current_user.college_id # associating item to user's college.

    respond_to do |format|
      if @item.save
        format.html { redirect_to @item, notice: "Item was successfully created." }
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
      params.expect(item: [ :title, :price, :description ])
    end
end
