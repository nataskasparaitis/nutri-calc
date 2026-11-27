require "rails_helper"

RSpec.describe "Sessions" do
  include ActiveSupport::Testing::TimeHelpers

  let(:password) { "top-secret-password" }
  let!(:user) { create(:user, email: "natas@example.com", password: password) }

  def log_in(email: user.email, password: self.password, **options)
    post session_path, params: { email: email, password: password }, as: :json, **options
  end

  def user_json(user)
    { "id" => user.id, "email" => user.email, "nickname" => user.nickname, "admin" => user.admin }
  end

  def set_cookie_header
    response.headers["set-cookie"].to_s
  end

  describe "POST /session" do
    context "when the email and password are right" do
      it "returns the user" do
        log_in
        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to eq(user_json(user))
      end

      it "never returns the password hash" do
        log_in
        expect(response.body).not_to include("password")
      end

      it "creates a session with the browser name and IP address" do
        expect { log_in(headers: { "User-Agent" => "Firefox" }) }.to change(user.sessions, :count).by(1)
        expect(user.sessions.last).to have_attributes(user_agent: "Firefox", ip_address: "127.0.0.1")
      end

      it "sets a session cookie that JavaScript can't read and other sites can't send" do
        log_in
        expect(set_cookie_header).to include("session_id=", "httponly", "samesite=lax")
      end

      it "keeps the cookie for years" do
        log_in
        expires = Time.httpdate(set_cookie_header[/expires=([^;]+)/, 1])
        expect(expires).to be > 19.years.from_now
      end

      it "does not require HTTPS outside production" do
        log_in
        expect(set_cookie_header).not_to include("secure")
      end

      it "requires HTTPS in production" do
        allow(Rails.env).to receive(:production?).and_return(true)
        https! # Rails only sends a secure cookie over HTTPS
        log_in
        expect(set_cookie_header).to include("secure")
      end
    end

    context "when the email has different case and spaces" do
      it "logs in" do
        log_in(email: "  NATAS@Example.com ")
        expect(response).to have_http_status(:created)
      end
    end

    context "when already logged in on another device" do
      it "adds a second session" do
        create(:session, user: user)
        expect { log_in }.to change(user.sessions, :count).from(1).to(2)
      end
    end

    shared_examples "rejected login" do
      it "says the email or password is wrong" do
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq("error" => "Invalid email or password")
      end

      it "does not create a session or set a cookie" do
        expect(Session.count).to eq(0)
        expect(set_cookie_header).not_to include("session_id")
      end
    end

    context "when the password is wrong" do
      before { log_in(password: "wrong-password") }

      it_behaves_like "rejected login"
    end

    context "when no user has that email" do
      before { log_in(email: "nobody@example.com") }

      it_behaves_like "rejected login"
    end

    context "when the password is a number" do
      before { log_in(password: 123) }

      it_behaves_like "rejected login"
    end

    {
      "the password is missing" => { email: "natas@example.com" },
      "the email is missing" => { password: "top-secret-password" },
      "the password is empty" => { email: "natas@example.com", password: "" },
      "the email is an object" => { email: { name: "natas" }, password: "top-secret-password" }
    }.each do |description, params|
      context "when #{description}" do
        it "says the request is bad" do
          post session_path, params: params, as: :json
          expect(response).to have_http_status(:bad_request)
          expect(Session.count).to eq(0)
        end
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

      def fail_to_log_in(times, **options)
        times.times { log_in(password: "wrong-password", **options) }
      end

      it "allows 10 attempts" do
        fail_to_log_in(9)
        log_in
        expect(response).to have_http_status(:created)
      end

      context "after 10 attempts" do
        before { fail_to_log_in(10) }

        it "blocks the 11th, even with the right password" do
          log_in
          expect(response).to have_http_status(:too_many_requests)
          expect(response.parsed_body).to eq("error" => "Too many login attempts, try again later")
          expect(Session.count).to eq(0)
        end

        it "allows logging in again after 3 minutes" do
          travel 3.minutes + 1.second
          log_in
          expect(response).to have_http_status(:created)
        end

        it "still blocks before 3 minutes have passed" do
          travel 3.minutes - 1.second
          log_in
          expect(response).to have_http_status(:too_many_requests)
        end

        it "does not block other IP addresses" do
          log_in(env: { "REMOTE_ADDR" => "10.0.0.2" })
          expect(response).to have_http_status(:created)
        end
      end

      it "does not limit the other session endpoints" do
        log_in
        11.times { get session_path }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /session" do
    context "when logged in" do
      before { log_in }

      it "returns the current user" do
        get session_path
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(user_json(user))
      end
    end

    shared_examples "not logged in" do
      it "says you must be logged in" do
        get session_path
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq("error" => "You must be logged in")
      end
    end

    context "when there is no cookie" do
      it_behaves_like "not logged in"
    end

    context "when the cookie was made up" do
      before do
        create(:session, user: user)
        cookies[:session_id] = Session.last.id.to_s
      end

      it_behaves_like "not logged in"
    end

    context "when the cookie was changed" do
      before do
        log_in
        cookies[:session_id] = cookies[:session_id].sub(/\A./) { |first| first == "a" ? "b" : "a" }
      end

      it_behaves_like "not logged in"
    end

    context "when the session was deleted" do
      before do
        log_in
        Session.delete_all
      end

      it_behaves_like "not logged in"
    end

    context "when the user's account was deleted" do
      before do
        log_in
        user.destroy!
      end

      it_behaves_like "not logged in"
    end
  end

  describe "DELETE /session" do
    context "when logged in" do
      before { log_in }

      it "logs out" do
        delete session_path
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end

      it "deletes the session" do
        expect { delete session_path }.to change(Session, :count).by(-1)
      end

      it "clears the cookie" do
        delete session_path
        expect(set_cookie_header).to include("session_id=;", "max-age=0")
      end

      it "makes the next request unauthorized" do
        delete session_path
        get session_path
        expect(response).to have_http_status(:unauthorized)
      end

      it "makes a copy of the old cookie useless" do
        old_cookie = cookies[:session_id]
        delete session_path
        cookies[:session_id] = old_cookie
        get session_path
        expect(response).to have_http_status(:unauthorized)
      end

      it "keeps the user's sessions on other devices" do
        other_device = create(:session, user: user)
        delete session_path
        expect(Session.exists?(other_device.id)).to be(true)
      end
    end

    context "when not logged in" do
      it "says you must be logged in" do
        delete session_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
