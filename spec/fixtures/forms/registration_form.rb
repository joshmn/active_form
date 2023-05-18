class RegistrationForm < ActiveForm::Base
  attribute :email

  validates :email, :presence => true
end
