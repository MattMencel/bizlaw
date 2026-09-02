class ApplicationRecord < ActiveRecord::Base
  include Retention

  primary_abstract_class
end
