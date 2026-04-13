require "rails_helper"

RSpec.describe NotificationsChannel, type: :channel do
  let(:user) { create_user(email: "notifications_channel_user@cuhk.edu.hk") }

  it "streams from the signed-in user's notifications feed" do
    stub_connection current_user: user

    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("notifications_user_#{user.id}")
  end
end
