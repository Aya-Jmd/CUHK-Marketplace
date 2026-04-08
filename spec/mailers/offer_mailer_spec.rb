require "rails_helper"

RSpec.describe OfferMailer, type: :mailer do
  # 1. 在内存中创建假数据 (Mock Data)，不影响真实数据库
  let(:seller) { User.new(email: "seller@cuhk.edu") }
  let(:buyer) { User.new(email: "buyer@cuhk.edu") }
  let(:item) { Item.new(title: "Calculus Textbook", price: 200, user: seller) }
  let(:test_offer) { Offer.new(price: 150, item: item, buyer: buyer, seller: seller, status: "accepted", meetup_code: "1234") }

  describe "notify_seller" do
    # 2. 将假数据传入方法中！完美解决参数报错
    let(:mail) { OfferMailer.notify_seller(test_offer) }

    it "renders the headers" do
      expect(mail.subject).to eq("New Offer for your Calculus Textbook!")
      expect(mail.to).to eq(["seller@cuhk.edu"])
      expect(mail.from).to eq(["no-reply@cuhk-marketplace.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("New Offer Received")
    end
  end

  describe "notify_buyer" do
    # 3. 将假数据传入方法中！
    let(:mail) { OfferMailer.notify_buyer(test_offer) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your offer for Calculus Textbook was Accepted 🎉")
      expect(mail.to).to eq(["buyer@cuhk.edu"])
      expect(mail.from).to eq(["no-reply@cuhk-marketplace.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Offer Accepted")
      expect(mail.body.encoded).to match("1234") # 确保提货码能正确显示
    end
  end
end