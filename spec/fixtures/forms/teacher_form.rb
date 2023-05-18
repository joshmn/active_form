class TeacherForm < ActiveForm::Base
  attribute :name, :string

  validates :name, :presence => true
end
