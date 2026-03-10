class SearchController < ApplicationController
  before_action :authenticate_user! 

  def index
    @query = params[:q].to_s.strip
    @scope = params[:scope].presence || 'all' # 'all' or 'college'

    base = Item.available.includes(:college) 

    base =
      if @scope == 'college' && current_user&.college_id.present?
        base.where(college_id: current_user.college_id)
      else
        base
      end

    @results =
      if @query.blank?
        []
      else
        base.intelligent_search(@query)
            .order(updated_at: :desc)
            .limit(100) # safety cap; replace with pagination (kaminari) later
      end
  end
end
