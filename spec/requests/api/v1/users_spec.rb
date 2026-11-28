require "rails_helper"

RSpec.describe "Api::V1::Users" do
  let(:valid_params) { { email: "natas@example.com", nickname: "natas", password: "top-secret-password" } }

  def register(params = valid_params, **options)
    post api_v1_users_path, params: params, as: :json, **options
  end

  def set_cookie_header
    response.headers["set-cookie"].to_s
  end

  describe "POST /api/v1/users" do
    context "when everything is valid" do
      it "creates the user" do
        expect { register }.to change(User, :count).by(1)
      end

      it "returns the new user" do
        register
        user = User.last
        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to eq(
          "code" => 0,
          "user" => { "id" => user.id, "email" => "natas@example.com", "nickname" => "natas", "admin" => false }
        )
      end

      it "never returns the password or its hash" do
        register
        expect(response.body).not_to include("password")
      end

      it "saves a password that works for logging in" do
        register
        expect(User.authenticate_by(email: "natas@example.com", password: "top-secret-password")).to eq(User.last)
      end

      it "logs the new user in" do
        expect { register(headers: { "User-Agent" => "Firefox" }) }.to change(Session, :count).by(1)
        expect(User.last.sessions.last).to have_attributes(user_agent: "Firefox", ip_address: "127.0.0.1")
        expect(set_cookie_header).to include("session_id=", "httponly", "samesite=lax")
      end

      it "lets the new user see their account straight away" do
        register
        get api_v1_session_path
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["user"]).to include("email" => "natas@example.com")
      end

      it "does not make the user an admin, even when asked to" do
        register(valid_params.merge(admin: true))
        expect(User.last.admin).to be(false)
      end
    end

    context "when the email has capital letters and spaces" do
      it "saves it cleaned up" do
        register(valid_params.merge(email: "  NATAS@Example.com "))
        expect(User.last.email).to eq("natas@example.com")
      end
    end

    context "when the password is a number" do
      it "saves it as text" do
        register(valid_params.merge(password: 123_456_789_012))
        expect(response).to have_http_status(:created)
        expect(User.authenticate_by(email: "natas@example.com", password: "123456789012")).to eq(User.last)
      end
    end

    shared_examples "rejected sign-up" do
      it "says what is wrong" do
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq("code" => 99, "message" => "Validation failed", "errors" => errors)
      end

      it "does not create a user, a session or a cookie" do
        expect(User.count).to eq(existing_users)
        expect(Session.count).to eq(0)
        expect(set_cookie_header).not_to include("session_id")
      end
    end

    context "when the email is already taken" do
      let(:existing_users) { 1 }
      let(:errors) { { "email" => [ "has already been taken" ] } }

      before do
        create(:user, email: "natas@example.com")
        register
      end

      it_behaves_like "rejected sign-up"
    end

    context "when the password is too short" do
      let(:existing_users) { 0 }
      let(:errors) { { "password" => [ "is too short (minimum is 12 characters)" ] } }

      before { register(valid_params.merge(password: "short")) }

      it_behaves_like "rejected sign-up"
    end

    {
      "the email is missing" => [ { nickname: "natas", password: "top-secret-password" }, "email" ],
      "the nickname is missing" => [ { email: "natas@example.com", password: "top-secret-password" }, "nickname" ],
      "the password is missing" => [ { email: "natas@example.com", nickname: "natas" }, "password" ],
      "the password is empty" => [ { email: "natas@example.com", nickname: "natas", password: "" }, "password" ],
      "the password is an object" => [
        { email: "natas@example.com", nickname: "natas", password: { anything: "x" * 20 } }, "password"
      ]
    }.each do |description, (params, field)|
      context "when #{description}" do
        let(:existing_users) { 0 }
        let(:errors) { { "base" => "param is missing or the value is empty or invalid: #{field}" } }

        before { register(params) }

        it_behaves_like "rejected sign-up"
      end
    end

    describe "rate limit" do
      let(:rate_limit_store) { ActiveSupport::Cache::MemoryStore.new }

      # Tests use a cache that forgets everything, so the attempts are counted in a real store instead.
      before do
        allow(Rails.cache).to receive(:increment) do |*args, **options|
          rate_limit_store.increment(*args, **options)
        end
      end

      it "allows 10 attempts" do
        9.times { register(valid_params.merge(password: "short")) }
        register
        expect(response).to have_http_status(:created)
      end

      context "after 10 attempts" do
        before { 10.times { register(valid_params.merge(password: "short")) } }

        it "blocks the 11th without creating a user" do
          expect { register }.not_to change(User, :count)
          expect(response).to have_http_status(:too_many_requests)
          expect(response.parsed_body).to eq("code" => 121, "message" => "Too many attempts, try again later")
        end

        it "counts separately from logging in" do
          create(:user, email: "other@example.com")
          post api_v1_session_path, params: { email: "other@example.com", password: "top-secret-password" }, as: :json
          expect(response).to have_http_status(:created)
        end
      end
    end
  end

  describe "DELETE /api/v1/users/:id" do
    let!(:user) { create(:user, email: "natas@example.com", password: "top-secret-password") }
    let!(:other_user) { create(:user) }

    def log_in
      post api_v1_session_path, params: { email: "natas@example.com", password: "top-secret-password" }, as: :json
    end

    context "when deleting your own account" do
      before { log_in }

      it "responds with no content" do
        delete api_v1_user_path(user)
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end

      it "deletes only that user" do
        expect { delete api_v1_user_path(user) }.to change(User, :count).by(-1)
        expect(User.exists?(user.id)).to be(false)
      end

      it "deletes the user's sessions on every device" do
        create(:session, user: user)
        expect { delete api_v1_user_path(user) }.to change(Session, :count).from(2).to(0)
      end

      it "clears the cookie" do
        delete api_v1_user_path(user)
        expect(set_cookie_header).to include("session_id=;", "max-age=0")
      end

      it "makes the next request unauthorized" do
        delete api_v1_user_path(user)
        get api_v1_session_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    shared_examples "forbidden deletion" do
      it "says access is denied" do
        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body).to eq("code" => 106, "message" => "Access denied")
      end

      it "does not delete anyone and keeps you logged in" do
        expect(User.count).to eq(2)
        get api_v1_session_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when deleting someone else's account" do
      before do
        log_in
        delete api_v1_user_path(other_user)
      end

      it_behaves_like "forbidden deletion"
    end

    context "when the user does not exist" do
      before do
        log_in
        delete api_v1_user_path(id: 999_999_999)
      end

      it_behaves_like "forbidden deletion"
    end

    context "when you are an admin" do
      before do
        user.update!(admin: true)
        log_in
        delete api_v1_user_path(other_user)
      end

      it_behaves_like "forbidden deletion"
    end

    context "when the id is not a number" do
      before { log_in }

      it "does not find the route" do
        delete "/api/v1/users/abc"
        expect(response).to have_http_status(:not_found)
        expect(User.count).to eq(2)
      end
    end

    context "when not logged in" do
      it "says you must be logged in and deletes nothing" do
        expect { delete api_v1_user_path(user) }.not_to change(User, :count)
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq("code" => 100, "message" => "Unauthorized")
      end
    end
  end
end
