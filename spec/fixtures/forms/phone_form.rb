class PhoneForm < ActiveForm::Base
  attribute :number, :string
  attribute :country_code, :string
end
