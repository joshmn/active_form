class BeforeValidationForm < ActiveForm::Base
  attribute :email

  before_validation do
    self.email = "default@here.com" if email.blank?
  end

  validates :email, :presence => true
end
