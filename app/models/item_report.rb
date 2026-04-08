class ItemReport < ApplicationRecord
  enum :status, { pending: "pending", ignored: "ignored", item_deleted: "item_deleted" }

  belongs_to :item
  belongs_to :reporter, class_name: "User"
  belongs_to :resolved_by, class_name: "User", optional: true

  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :message, presence: true, length: { maximum: 1500 }

  validate :reporter_cannot_be_item_owner
  validate :item_must_be_reportable, on: :create

  scope :pending, -> { where(status: "pending") }

  after_create_commit :notify_reviewers

  def resolved?
    !pending?
  end

  def resolution_summary
    case status
    when "ignored"
      "Report ignored"
    when "item_deleted"
      "Item removed from marketplace"
    else
      "Pending review"
    end
  end

  def resolve!(resolver:, resolution:)
    resolution_value = resolution.to_s
    raise ArgumentError, "Unsupported resolution" unless self.class.statuses.key?(resolution_value)
    raise ArgumentError, "Pending reports cannot resolve to pending" if resolution_value == "pending"

    recipient_ids = notifications.where(action: "item_report_created").distinct.pluck(:recipient_id)

    transaction do
      update!(
        status: resolution_value,
        resolved_by: resolver,
        resolved_at: Time.current
      )

      notifications
        .where(action: "item_report_created", read_at: nil)
        .update_all(read_at: Time.current, updated_at: Time.current)

      User.where(id: recipient_ids).find_each do |recipient|
        Notification.create!(
          recipient: recipient,
          actor: resolver,
          action: "item_report_resolved",
          notifiable: self
        )
      end
    end
  end

  private

  def notify_reviewers
    review_recipients.find_each do |recipient|
      Notification.create!(
        recipient: recipient,
        actor: reporter,
        action: "item_report_created",
        notifiable: self
      )
    end
  end

  def review_recipients
    User.admin.or(User.college_admin.where(college_id: item.college_id)).distinct
  end

  def reporter_cannot_be_item_owner
    return unless reporter_id.present? && reporter_id == item&.user_id

    errors.add(:base, "You cannot report your own item.")
  end

  def item_must_be_reportable
    return if item.blank?
    return unless item.removed? || item.user&.banned?

    errors.add(:item, "is no longer available for reporting")
  end
end
