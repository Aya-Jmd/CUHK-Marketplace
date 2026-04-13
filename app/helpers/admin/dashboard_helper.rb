module Admin::DashboardHelper
  def admin_manageable_user?(user)
    return false if user == current_user
    return true if current_user.admin?

    current_user.college_admin? && user.student? && user.college_id == current_user.college_id
  end

  def admin_user_status_label(user)
    return "Banned" if user.banned?
    return "Active" if user.setup_completed?

    "Pending"
  end

  def admin_user_status_classes(user)
    if user.banned?
      "text-red-600"
    elsif user.setup_completed?
      "text-green-600"
    else
      "text-amber-500"
    end
  end

  def admin_rule_price_value(college)
    Currency.convert_from_hkd(college.max_item_price, current_currency_code)
  end
end
