class Admin::CollegeRulesController < Admin::BaseController
  def update
    @college = managed_college

    unless @college
      redirect_to admin_root_path, alert: "No college is available to manage."
      return
    end

    assign_rule_attributes

    if @college.save
      redirect_to admin_root_path(redirect_scope_params), notice: "College rules updated."
    else
      redirect_to admin_root_path(redirect_scope_params), alert: @college.errors.full_messages.to_sentence
    end
  end

  private

  def assign_rule_attributes
    @college.max_items_per_user = college_rule_params[:max_items_per_user]
    @college.max_item_price = convert_price_to_hkd(college_rule_params[:max_item_price])
  end

  def college_rule_params
    params.require(:college).permit(:max_items_per_user, :max_item_price)
  end

  def managed_college
    return current_user.college if current_user.college_admin?

    colleges = College.order(:name)
    colleges.find_by(id: params[:college_id]) || colleges.first
  end

  def redirect_scope_params
    return {} unless current_user.admin? && @college.present?

    { rule_college_id: @college.id }
  end
end
