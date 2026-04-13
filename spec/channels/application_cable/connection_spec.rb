require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create_user(email: "cable_user@cuhk.edu.hk") }

  it "connects with the authenticated warden user" do
    connect "/cable", env: { "warden" => double(user:) }

    expect(connection.current_user).to eq(user)
  end

  it "rejects connections without an authenticated user" do
    expect {
      connect "/cable", env: { "warden" => double(user: nil) }
    }.to have_rejected_connection
  end
end
