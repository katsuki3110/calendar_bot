class Calendar < ApplicationRecord

  validates :user,    presence: true
  validates :date,    presence: true
  validates :content, presence: true

end
