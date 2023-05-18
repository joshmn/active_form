require_relative "teacher_form"

class SchoolForm < ActiveForm::Base
  has_one :head, class_name: "TeacherForm", required: true
end
