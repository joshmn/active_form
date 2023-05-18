class AddressForm < ActiveForm::Base
  attribute :street,    :string
  attribute :town,      :string
  attribute :city,      :string
  attribute :post_code, :string
end
