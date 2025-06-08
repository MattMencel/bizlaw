class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include HasUuid
  include SoftDeletable

  # Add timestamp helpers
  def touch_with_version
    touch if has_attribute?(:updated_at)
  end

  # Add enum helpers
  def self.enum_i18n_key(enum_name, enum_value)
    "activerecord.enums.#{model_name.i18n_key}.#{enum_name}.#{enum_value}"
  end
end
