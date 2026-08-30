RSpec.shared_context "with authenticated request" do
  let(:authenticated_user) { create(:user, :confirmed) }

  def sign_in_as(user = authenticated_user)
    get login_path
    csrf_token = response.body[/name="csrf-token" content="([^"]+)/, 1]
    post login_path,
      params: { user: { email: user.email, password: "correct horse battery" } },
      headers: { "X-CSRF-Token" => csrf_token }
    follow_redirect!
  end
end
