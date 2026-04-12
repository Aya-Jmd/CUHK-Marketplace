class ItemReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    @item = Item.find(params[:item_id])

    unless @item.visible_to?(current_user)
      redirect_to items_path, alert: "You cannot report this item."
      return
    end

    if current_user == @item.user
      redirect_to items_path, alert: "You cannot report this item."
      return
    end

    @item_report = @item.item_reports.build(item_report_params.merge(reporter: current_user))

    if @item_report.save
      redirect_to item_path(@item), notice: "Report submitted for review."
    else
      redirect_to item_path(@item), alert: @item_report.errors.full_messages.to_sentence
    end
  end

  private

  def item_report_params
    params.require(:item_report).permit(:message)
  end
end
