require 'spec_helper'

describe 'HasOne' do
  class OrderForm < ActiveForm::Base
    has_many :barcodes, class_name: "BarcodeForm"
  end

  class BarcodeForm < ActiveForm::Base
    attribute :code

    validates :code, presence: true
  end

  context 'validations' do
    it 'validates' do
      order = OrderForm.new
      order.barcodes.new
      order.validate
      expect(order.valid?).to be_falsey
    end
  end
end
