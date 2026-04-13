require "rails_helper"

RSpec.describe "Analytics scope", type: :request do
  it "limits student analytics to global items and their college items" do
    shaw = create_college(name: "Shaw College")
    new_asia = create_college(name: "New Asia College")
    student = create_user(email: "analytics_student@cuhk.edu.hk", college: shaw)
    shaw_seller = create_user(email: "analytics_shaw_seller@cuhk.edu.hk", college: shaw)
    new_asia_seller = create_user(email: "analytics_new_asia_seller@cuhk.edu.hk", college: new_asia)
    category = Category.create!(name: "Analytics Student Category")

    local_item = create_item(user: shaw_seller, title: "Local Camera", category:, college: shaw, is_global: false)
    global_item = create_item(user: new_asia_seller, title: "Global Speaker", category:, college: new_asia, is_global: true, status: "sold")
    hidden_item = create_item(user: new_asia_seller, title: "Hidden Printer", category:, college: new_asia, is_global: false, status: "sold")

    timestamp = Time.zone.local(2026, 4, 8, 12, 0, 0)
    [ local_item, global_item, hidden_item ].each { |item| item.update!(created_at: timestamp, updated_at: timestamp) }
    global_item.update!(sold_at: timestamp)
    hidden_item.update!(sold_at: timestamp)

    sign_in student
    get analytics_path, params: {
      category_ids: [ category.id ],
      chart_mode: "exact",
      start_date: Date.new(2026, 4, 1),
      end_date: Date.new(2026, 4, 10)
    }

    document = Nokogiri::HTML.parse(response.body)
    scope_toggle = document.at_css(".dashboard-scope-control .site-header__scope-toggle")
    scope_input = document.at_css('.dashboard-filters input[name="scope"]')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Local Camera", "Global Speaker")
    expect(response.body).not_to include("Hidden Printer")
    expect(scope_toggle).to be_present
    expect(scope_toggle["href"]).to include("scope=college")
    expect(scope_toggle["href"]).to include("chart_mode=exact")
    expect(scope_input).to be_present
    expect(scope_input["value"]).to eq("all")
  end

  it "applies the same college rules to college admins" do
    shaw = create_college(name: "Admin Shaw College")
    new_asia = create_college(name: "Admin New Asia College")
    college_admin = create_user(email: "analytics_college_admin@cuhk.edu.hk", college: shaw, role: :college_admin)
    college_admin.update!(setup_completed: true)
    shaw_seller = create_user(email: "analytics_college_admin_shaw_seller@cuhk.edu.hk", college: shaw)
    new_asia_seller = create_user(email: "analytics_college_admin_new_asia_seller@cuhk.edu.hk", college: new_asia)
    category = Category.create!(name: "Analytics College Admin Category")

    local_item = create_item(user: shaw_seller, title: "Scoped Desk", category:, college: shaw, is_global: false)
    global_item = create_item(user: new_asia_seller, title: "Global Lamp", category:, college: new_asia, is_global: true)
    hidden_item = create_item(user: new_asia_seller, title: "Outside Drawer", category:, college: new_asia, is_global: false)

    timestamp = Time.zone.local(2026, 4, 7, 10, 0, 0)
    [ local_item, global_item, hidden_item ].each { |item| item.update!(created_at: timestamp, updated_at: timestamp) }

    sign_in college_admin
    get analytics_path, params: {
      scope: "college",
      category_ids: [ category.id ],
      chart_mode: "exact",
      start_date: Date.new(2026, 4, 1),
      end_date: Date.new(2026, 4, 10)
    }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Scoped Desk")
    expect(response.body).not_to include("Global Lamp", "Outside Drawer")
  end

  it "lets system admins view all analytics data or filter it to a selected college" do
    shaw = create_college(name: "Analytics Admin Shaw")
    new_asia = create_college(name: "Analytics Admin New Asia")
    admin = create_user(email: "analytics_system_admin@cuhk.edu.hk", role: :admin)
    admin.update!(setup_completed: true)
    shaw_seller = create_user(email: "analytics_admin_shaw_seller@cuhk.edu.hk", college: shaw)
    new_asia_seller = create_user(email: "analytics_admin_new_asia_seller@cuhk.edu.hk", college: new_asia)
    category = Category.create!(name: "Analytics System Admin Category")

    shaw_item = create_item(user: shaw_seller, title: "Shaw Projector", category:, college: shaw, is_global: false)
    new_asia_item = create_item(user: new_asia_seller, title: "New Asia Mixer", category:, college: new_asia, is_global: false)

    timestamp = Time.zone.local(2026, 4, 9, 14, 0, 0)
    [ shaw_item, new_asia_item ].each { |item| item.update!(created_at: timestamp, updated_at: timestamp) }

    sign_in admin
    get analytics_path, params: {
      category_ids: [ category.id ],
      chart_mode: "exact",
      start_date: Date.new(2026, 4, 1),
      end_date: Date.new(2026, 4, 10)
    }

    document = Nokogiri::HTML.parse(response.body)
    college_select = document.at_css('.dashboard-scope-control select[name="college_scope_id"]')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Shaw Projector", "New Asia Mixer")
    expect(college_select).to be_present
    expect(college_select.text).to include("All colleges")

    get analytics_path, params: {
      college_scope_id: shaw.id,
      category_ids: [ category.id ],
      chart_mode: "exact",
      start_date: Date.new(2026, 4, 1),
      end_date: Date.new(2026, 4, 10)
    }

    document = Nokogiri::HTML.parse(response.body)
    college_scope_input = document.at_css('.dashboard-filters input[name="college_scope_id"]')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Shaw Projector")
    expect(response.body).not_to include("New Asia Mixer")
    expect(college_scope_input).to be_present
    expect(college_scope_input["value"]).to eq(shaw.id.to_s)
  end
end
