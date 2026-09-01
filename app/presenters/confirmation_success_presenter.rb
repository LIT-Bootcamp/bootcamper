class ConfirmationSuccessPresenter
  def initialize(success_variant:)
    @success_variant = success_variant
  end

  def message_key
    "confirmation.#{success_variant || :success_message}"
  end

  private

  attr_reader :success_variant
end
