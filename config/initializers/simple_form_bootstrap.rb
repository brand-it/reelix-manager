# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.error_notification_class = "alert alert-danger"
  config.button_class = "btn btn-primary"
  config.boolean_label_class = "form-check-label"

  config.label_text = lambda { |label, required, _explicit_label| "#{label} #{required}" }
  config.boolean_style = :inline
  config.error_method = :to_sentence
  config.input_field_error_class = "is-invalid"
  config.input_field_valid_class = "is-valid"

  config.wrappers :default, class: "mb-3" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: "form-label"
    b.use :input, class: "form-control", error_class: "is-invalid", valid_class: "is-valid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint, wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  config.wrappers :form_check, class: "mb-3 form-check" do |b|
    b.use :html5
    b.use :label, class: "form-check-label"
    b.use :input, class: "form-check-input", error_class: "is-invalid", valid_class: "is-valid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint, wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  config.default_wrapper = :default
end
