class Admin::DashboardController < Admin::BaseController
  def index
    if current_user.admin?
      @total_users = User.count
      @total_items = Item.available.count
      @colleges = College.order(:name)
      @rule_college_options = College.order(:id)
      @report_scope = ItemReport.includes(:item)
      @users = User.includes(:college).order(created_at: :desc)
    elsif current_user.college_admin?
      @total_users = User.where(college_id: current_user.college_id).count
      @total_items = Item.available.where(college_id: current_user.college_id).count
      @report_scope = ItemReport.joins(:item).where(items: { college_id: current_user.college_id })

      @users = User.where(college_id: current_user.college_id).order(created_at: :desc)
    end

    @total_reports = @report_scope.count
    @pending_reports = @report_scope.pending.count
    @new_admin = User.new
    @rule_college = selected_rule_college
    @invite_results_visible = flash[:revealed_pending_invites].present?
    @revealed_invites = @invite_results_visible ? revealed_pending_invites : []

    secure_invite_reveal_response! if @invite_results_visible
  end

  def invite
    role_to_invite = invite_params[:role]

    if current_user.college_admin? && role_to_invite == "admin"
      redirect_to admin_root_path(redirect_scope_params), alert: "Unauthorized: You can only invite other College Admins."
      return
    end

    assigned_college_id = current_user.college_admin? ? current_user.college_id : invite_params[:college_id]

    setup_pin = User.generate_admin_invite_pin

    @new_admin = User.new(
      email: invite_params[:email],
      pseudo: User.pseudo_from_email(invite_params[:email]),
      role: role_to_invite,
      college_id: assigned_college_id,
      password: setup_pin,
      password_confirmation: setup_pin,
      setup_completed: false,
      invited_by: current_user
    )
    @new_admin.store_admin_invite_pin(setup_pin)

    if @new_admin.save
      redirect_to admin_root_path(redirect_scope_params), notice: "Invitation created for #{@new_admin.email}. Use Manage invite to reveal the setup pin when needed."
    else
      redirect_to admin_root_path(redirect_scope_params), alert: "Error sending invite: #{@new_admin.errors.full_messages.join(', ')}"
    end
  end

  def reveal_invites
    unless current_user.valid_password?(invite_access_params[:password].to_s)
      redirect_to admin_root_path(redirect_scope_params.merge(anchor: "admin-invite-access")), alert: "Incorrect password. Pending invites stayed hidden."
      return
    end

    redirect_to admin_root_path(redirect_scope_params.merge(anchor: "admin-pending-invites")), flash: { revealed_pending_invites: true }
  end

  private

  def selected_rule_college
    return current_user.college if current_user.college_admin?

    colleges = College.order(:id)
    return colleges.first if params[:rule_college_id].blank?

    colleges.find_by(id: params[:rule_college_id]) || colleges.first
  end

  def revealed_pending_invites
    User.pending_admin_invites_for(current_user).filter_map do |invite|
      setup_pin = invite.reveal_admin_invite_pin
      next if setup_pin.blank?

      { user: invite, college_name: invite.college&.name || "Global", setup_pin: setup_pin }
    end
  end

  def secure_invite_reveal_response!
    response.headers["Cache-Control"] = "no-store, no-cache, max-age=0, private"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end

  def invite_params
    params.require(:user).permit(:email, :role, :college_id)
  end

  def invite_access_params
    params.fetch(:invite_access, ActionController::Parameters.new).permit(:password)
  end

  def redirect_scope_params
    return {} unless current_user.admin? && params[:rule_college_id].present?

    { rule_college_id: params[:rule_college_id] }
  end
end
