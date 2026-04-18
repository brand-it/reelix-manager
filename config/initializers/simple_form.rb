# frozen_string_literal: true

SimpleForm.setup do |config|
  config.button_class             = 'btn btn-primary'
  config.boolean_label_class      = 'form-check-label'
  config.boolean_style            = :inline
  config.label_text               = ->(label, required, _explicit_label) { "#{label} #{required}" }
  config.item_wrapper_tag         = :div
  config.include_default_input_wrapper_class = false
  config.error_notification_tag   = :div
  config.error_notification_class = 'alert alert-danger'
  config.error_method             = :to_sentence
  config.input_field_error_class  = 'is-invalid'
  config.input_field_valid_class  = 'is-valid'
  config.browser_validations      = true
end

# Prevents accidental double-submissions by disabling the submit button after
# the first click. Falls back to "Processing..." if no label value is found.
module DisableDoubleClickOnSimpleForms
  PROCESSING = 'Processing...'

  def submit(field, options = {})
    if field.is_a?(Hash)
      field[:data] ||= {}
      field[:data][:disable_with] ||= field[:value] || PROCESSING
    else
      options[:data] ||= {}
      options[:data][:disable_with] ||= options[:value] || PROCESSING
    end
    super
  end
end

SimpleForm::FormBuilder.prepend(DisableDoubleClickOnSimpleForms)
