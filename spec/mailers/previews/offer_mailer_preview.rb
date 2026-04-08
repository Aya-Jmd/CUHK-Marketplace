# Preview all emails at http://localhost:3000/rails/mailers/offer_mailer_mailer
class OfferMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/offer_mailer_mailer/notify_seller
  def notify_seller
    OfferMailer.notify_seller
  end

  # Preview this email at http://localhost:3000/rails/mailers/offer_mailer_mailer/notify_buyer
  def notify_buyer
    OfferMailer.notify_buyer
  end

end
