class FileUploadForm < ActiveForm::Base
  acts_like_model :user

  attribute :file #, ActionDispatch::Http::UploadedFile
end
