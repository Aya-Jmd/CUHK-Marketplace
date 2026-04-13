class User < ApplicationRecord
  ADMIN_INVITE_PIN_LENGTH = 8
  ADMIN_INVITE_PIN_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  enum :role, { student: 0, admin: 1, college_admin: 2 }

  belongs_to :college, optional: true
  belongs_to :banned_by, class_name: "User", optional: true
  belongs_to :invited_by, class_name: "User", optional: true, inverse_of: :invited_admins
  has_many :items
  has_many :item_reports, foreign_key: :reporter_id, inverse_of: :reporter
  has_many :messages
  has_many :conversations_as_buyer, class_name: "Conversation", foreign_key: "buyer_id"
  has_many :conversations_as_seller, class_name: "Conversation", foreign_key: "seller_id"
  has_many :offers_made, class_name: "Offer", foreign_key: "buyer_id"
  has_many :offers_received, class_name: "Offer", foreign_key: "seller_id"
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_items, through: :favorites, source: :item
  has_many :invited_admins, class_name: "User", foreign_key: :invited_by_id, inverse_of: :invited_by

  validates :college, presence: true, unless: :admin?

  scope :active, -> { where(banned_at: nil) }
  scope :banned, -> { where.not(banned_at: nil) }
  scope :pending_admin_invites_for, ->(user) do
    where(invited_by: user, setup_completed: false, role: [ roles[:admin], roles[:college_admin] ])
      .where.not(invite_pin_ciphertext: nil)
      .includes(:college)
      .order(created_at: :desc)
  end

  before_save :clear_admin_invite_pin, if: :setup_completed?

  def banned?
    banned_at.present?
  end

  def ban!(actor:)
    update!(banned_at: Time.current, banned_by: actor)
  end

  def unban!
    update!(banned_at: nil, banned_by: nil)
  end

  def active_for_authentication?
    super && !banned?
  end

  def inactive_message
    banned? ? :locked : super
  end

  def display_name
    email.to_s.split("@").first
  end

  def has_location?
    latitude.present? && longitude.present?
  end

  def location_display_name
    return "Location not set" unless default_location.present?
    default_location.split("_").map(&:capitalize).join(" ")
  end

  def set_location(location_key)
    return nil unless assign_location(location_key)

    save
  end

  def location_coordinates
    return nil unless has_location?
    { lat: latitude, lng: longitude }
  end

  def assign_location(location_key)
    coords = LocationService.get_coordinates(location_key)
    return false unless coords

    self.latitude = coords[:lat]
    self.longitude = coords[:lng]
    self.default_location = location_key
    true
  end

  def apply_college_default_location
    return false if college.blank?
    return false if default_location.present? || latitude.present? || longitude.present?

    assign_location(college.default_location_key)
  end

  def self.generate_admin_invite_pin(length: ADMIN_INVITE_PIN_LENGTH)
    Array.new(length) do
      ADMIN_INVITE_PIN_ALPHABET[SecureRandom.random_number(ADMIN_INVITE_PIN_ALPHABET.length)]
    end.join
  end

  def self.admin_invite_pin_encryptor
    @admin_invite_pin_encryptor ||= begin
      key = Rails.application.key_generator.generate_key("admin invite setup pin", ActiveSupport::MessageEncryptor.key_len)
      ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm")
    end
  end

  def store_admin_invite_pin(pin)
    self.invite_pin_ciphertext = self.class.admin_invite_pin_encryptor.encrypt_and_sign(pin)
  end

  def reveal_admin_invite_pin
    return if invite_pin_ciphertext.blank?

    self.class.admin_invite_pin_encryptor.decrypt_and_verify(invite_pin_ciphertext)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def live_items
    items.where.not(status: %w[removed sold])
  end

  def live_items_count
    live_items.count
  end

  def reached_college_item_limit?
    college.present? && college.posting_limit_reached_by?(self)
  end

  private

  def clear_admin_invite_pin
    self.invite_pin_ciphertext = nil
  end
end
