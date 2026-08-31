require "rails_helper"

RSpec.describe RegistrationConfirmationJob do
  include ActiveJob::TestHelper

  self.use_transactional_tests = false

  around do |example|
    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs
    clear_performed_jobs
    User.delete_all
    example.run
  ensure
    User.delete_all
    clear_enqueued_jobs
    clear_performed_jobs
    ActionMailer::Base.deliveries.clear
  end

  it "enqueues only after the surrounding transaction commits" do
    enqueue_confirmation_inside_open_transaction

    expect_confirmation_job_to_wait_for_commit
    expect_confirmation_email_after_job_runs
  end

  it "skips confirmation delivery when duplicate registration work is enqueued" do
    enqueue_duplicate_registration_work

    expect_no_confirmation_email_to_be_sent
  end

  private

  def enqueue_confirmation_inside_open_transaction
    User.transaction do
      user = build_pending_user(email: "student@example.com")
      user.save!

      described_class.perform_later(user.id)

      expect(enqueued_jobs).to be_empty
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  def expect_confirmation_job_to_wait_for_commit
    expect(enqueued_jobs.size).to eq(1)
    expect(enqueued_jobs.first[:job]).to eq(described_class)
  end

  def expect_confirmation_email_after_job_runs
    perform_enqueued_jobs(only: described_class)

    confirmation_email = ActionMailer::Base.deliveries.last
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(confirmation_email.to).to eq([ "student@example.com" ])
    expect(confirmation_email.body.to_s).to include("/register/confirm?confirmation_token=")
  end

  def enqueue_duplicate_registration_work
    user = build_pending_user(email: "student@example.com")
    user.save!

    perform_enqueued_jobs do
      described_class.perform_later(user.id, send_confirmation: false)
    end
  end

  def expect_no_confirmation_email_to_be_sent
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  def build_pending_user(email:)
    User.new(
      email:,
      password: "correct horse battery",
      password_confirmation: "correct horse battery",
      role: :student
    ).tap(&:skip_confirmation_notification!)
  end
end
