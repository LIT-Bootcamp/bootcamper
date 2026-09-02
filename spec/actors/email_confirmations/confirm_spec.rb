require "rails_helper"

RSpec.describe EmailConfirmations::Confirm do
  self.use_transactional_tests = false

  before { ActionMailer::Base.deliveries.clear }
  after { User.delete_all }

  it "returns a sign-in-ready variant for an active account", :aggregate_failures do
    create(:user, email: "student@example.com")

    result = described_class.result(confirmation_token: current_confirmation_token)

    expect(result).to be_success
    expect(result.user.reload).to be_email_verified
    expect(result.success_variant).to eq(:success_message_sign_in_available)
  end

  it "returns a blocked variant for a blocked account", :aggregate_failures do
    create(:user, email: "student@example.com", blocked: true)

    result = described_class.result(confirmation_token: current_confirmation_token)

    expect(result).to be_success
    expect(result.user.reload).to be_email_verified
    expect(result.success_variant).to eq(:success_message_still_blocked)
  end

  it "fails with the confirmation errors for an invalid token" do
    result = described_class.result(confirmation_token: "not-a-real-token")

    expect(result).to have_attributes(success?: false, user: have_attributes(errors: be_present))
  end

  it "rejects a proof superseded after lookup", :aggregate_failures do
    result, user = superseded_proof_attempt

    expect(result).to have_attributes(success?: false, user: have_attributes(errors: be_present))
    expect(user.reload).to have_attributes(confirmed_at: nil, confirmation_token: "superseded-token")
  end

  it "allows only one concurrent confirmation for a proof", :aggregate_failures do
    user = create(:user, email: "student@example.com")
    token = current_confirmation_token
    outcomes = concurrent_confirmation_results(token)

    expect_one_confirmation_to_succeed(outcomes)
    expect(user.reload).to be_email_verified
  end

  private

  def concurrent_confirmation_results(token)
    mutex = Mutex.new
    condition = ConditionVariable.new
    confirmations = 0
    module_double = Module.new do
      define_method(:confirm) do |args = {}|
        wait_for_peer = mutex.synchronize do
          confirmations += 1
          if confirmations == 2
            condition.broadcast
            false
          else
            true
          end
        end
        mutex.synchronize { condition.wait(mutex, 0.2) } if wait_for_peer
        super(args)
      end
    end
    User.prepend(module_double)

    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.result(confirmation_token: token)
        end
      end
    end
    Timeout.timeout(2) { threads.map(&:value) }
  ensure
    threads&.each { |thread| thread.kill if thread.alive? }
    module_double&.send(:remove_method, :confirm)
  end

  def expect_one_confirmation_to_succeed(outcomes)
    expect(outcomes.count(&:success?)).to eq(1)
    expect(outcomes.count { |result| !result.success? }).to eq(1)
  end

  def superseded_proof_attempt
    user = create(:user, email: "student@example.com")
    token = current_confirmation_token
    allow(User).to receive(:find_by).and_wrap_original do |original, *args, **kwargs|
      found = original.call(*args, **kwargs)
      criteria = args.first || kwargs
      user.update_columns(confirmation_token: "superseded-token", updated_at: Time.current) if found && criteria == { confirmation_token: token }
      found
    end
    [ described_class.result(confirmation_token: token), user ]
  end

  def current_confirmation_token
    ActionMailer::Base.deliveries.last.body.to_s[/confirmation_token=([^&"]+)/, 1]
  end
end
