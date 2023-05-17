# ActiveForm

If Rectify's form object and ActiveRecord had a baby.

## Major WIP

Most of the association stuff is copied from ActiveRecord. It's not tidy, it's not maintainable, it's not nice. But it works... 

## Usage

They work just like models.

```ruby
class TicketForm < ActiveForm::Base 
  acts_like_model :ticket 
  
  attribute :name 
  attribute :price_in_cents, :integer
  
  validates :name, presence: true  
  validates :price_in_cents, presence: true, numericality: { greater_than: 0 }
end
```

What if `#price_in_cents` is on a `TicketPrice`?

```ruby
class TicketPriceForm < ActiveForm::Base
  acts_like_model :ticket_price

  attribute :price_in_cents, :integer

  validates :price_in_cents, presence: true, numericality: { greater_than: 0 }
end

class TicketForm < ActiveForm::Base 
  acts_like_model :ticket 
  
  attribute :name

  has_many :ticket_prices, class_name: "TicketPriceForm"
  accepts_nested_attributes_for :ticket_prices

  validates :name, presence: true  
end
```
