# frozen_string_literal: true

# All wrapper definitions for SimpleForm + Bootstrap 5.
# Global SimpleForm options (button_class, error_notification_class, etc.) live
# in simple_form.rb so they are not duplicated here.
SimpleForm.setup do |config|
  # ── Vertical wrappers (default layout) ──────────────────────────────────────

  # Standard text / email / number / password / textarea inputs.
  config.wrappers :default, tag: "div", class: "mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label,      class: "form-label"
    b.use :input,      class: "form-control", error_class: "is-invalid", valid_class: "is-valid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # Select inputs — Bootstrap 5 uses form-select, not form-control.
  config.wrappers :select_input, tag: "div", class: "mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.use :label,      class: "form-label"
    b.use :input,      class: "form-select", error_class: "is-invalid", valid_class: "is-valid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # File inputs — same markup as :default but called out explicitly.
  config.wrappers :file_input, tag: "div", class: "mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly
    b.use :label,      class: "form-label"
    b.use :input,      class: "form-control", error_class: "is-invalid", valid_class: "is-valid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # Range inputs — Bootstrap 5 uses form-range.
  config.wrappers :range_input, tag: "div", class: "mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :readonly
    b.optional :step
    b.use :label,      class: "form-label"
    b.use :input,      class: "form-range", error_class: "is-invalid", valid_class: "is-valid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback d-block" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # Single boolean — form-check pattern (input then label).
  config.wrappers :form_check, tag: "div", class: "mb-3 form-check",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.use :input,      class: "form-check-input", error_class: "is-invalid", valid_class: "is-valid"
    b.use :label,      class: "form-check-label"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # Toggle switch — visually renders as a pill switch instead of a checkbox.
  config.wrappers :form_switch, tag: "div", class: "mb-3 form-check form-switch",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.use :input,      class: "form-check-input", error_class: "is-invalid", valid_class: "is-valid"
    b.use :label,      class: "form-check-label"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # Stacked radio buttons or check box group — fieldset + legend.
  config.wrappers :collection, item_wrapper_class: "form-check",
                  item_label_class: "form-check-label",
                  tag: "fieldset", class: "mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :legend_tag, tag: "legend", class: "form-label" do |ba|
      ba.use :label_text
    end
    b.use :input,      class: "form-check-input", error_class: "is-invalid", valid_class: "is-valid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback d-block" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # Inline radio buttons or check box group.
  config.wrappers :collection_inline, item_wrapper_class: "form-check form-check-inline",
                  item_label_class: "form-check-label",
                  tag: "fieldset", class: "mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :legend_tag, tag: "legend", class: "form-label" do |ba|
      ba.use :label_text
    end
    b.use :input,      class: "form-check-input", error_class: "is-invalid", valid_class: "is-valid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback d-block" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # Multi-select — side-by-side select boxes (e.g. has_many pickers).
  config.wrappers :multi_select, tag: "div", class: "mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: "form-label"
    b.wrapper tag: "div", class: "d-flex gap-2" do |ba|
      ba.use :input,     class: "form-select", error_class: "is-invalid", valid_class: "is-valid"
    end
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback d-block" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # ── Horizontal wrappers ─────────────────────────────────────────────────────

  # Standard horizontal — label col-sm-3, input col-sm-9.
  config.wrappers :horizontal_form, tag: "div", class: "row mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: "col-sm-3 col-form-label"
    b.wrapper :grid_wrapper, tag: "div", class: "col-sm-9" do |ba|
      ba.use :input,      class: "form-control", error_class: "is-invalid", valid_class: "is-valid"
      ba.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
      ba.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
    end
  end

  # Horizontal boolean.
  config.wrappers :horizontal_boolean, tag: "div", class: "row mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper tag: "label", class: "col-sm-3 col-form-label" do |ba|
      ba.use :label_text
    end
    b.wrapper :grid_wrapper, tag: "div", class: "col-sm-9" do |wr|
      wr.wrapper :form_check_wrapper, tag: "div", class: "form-check" do |bb|
        bb.use :input,      class: "form-check-input", error_class: "is-invalid", valid_class: "is-valid"
        bb.use :label,      class: "form-check-label"
        bb.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback d-block" }
        bb.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
      end
    end
  end

  # Horizontal stacked radio/checkbox collection.
  config.wrappers :horizontal_collection, item_wrapper_class: "form-check",
                  item_label_class: "form-check-label",
                  tag: "div", class: "row mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: "col-sm-3 col-form-label pt-0"
    b.wrapper :grid_wrapper, tag: "div", class: "col-sm-9" do |ba|
      ba.use :input,      class: "form-check-input", error_class: "is-invalid", valid_class: "is-valid"
      ba.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback d-block" }
      ba.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
    end
  end

  # Horizontal inline radio/checkbox collection.
  config.wrappers :horizontal_collection_inline, item_wrapper_class: "form-check form-check-inline",
                  item_label_class: "form-check-label",
                  tag: "div", class: "row mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: "col-sm-3 col-form-label pt-0"
    b.wrapper :grid_wrapper, tag: "div", class: "col-sm-9" do |ba|
      ba.use :input,      class: "form-check-input", error_class: "is-invalid", valid_class: "is-valid"
      ba.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback d-block" }
      ba.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
    end
  end

  # Horizontal select.
  config.wrappers :horizontal_select, tag: "div", class: "row mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: "col-sm-3 col-form-label"
    b.wrapper :grid_wrapper, tag: "div", class: "col-sm-9" do |ba|
      ba.use :input,      class: "form-select", error_class: "is-invalid", valid_class: "is-valid"
      ba.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
      ba.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
    end
  end

  # ── Inline wrapper ──────────────────────────────────────────────────────────

  config.wrappers :inline_form, tag: "span",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label,      class: "visually-hidden"
    b.use :input,      class: "form-control", error_class: "is-invalid", valid_class: "is-valid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.optional :hint,  wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # ── Floating labels ─────────────────────────────────────────────────────────
  # Bootstrap 5 floating labels: input before label, placeholder required.

  config.wrappers :floating_labels_form, tag: "div", class: "form-floating mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :input,      class: "form-control", error_class: "is-invalid", valid_class: "is-valid"
    b.use :label
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  config.wrappers :floating_labels_select, tag: "div", class: "form-floating mb-3",
                  error_class: "form-group-invalid", valid_class: "form-group-valid" do |b|
    b.use :html5
    b.optional :readonly
    b.use :input,      class: "form-select", error_class: "is-invalid", valid_class: "is-valid"
    b.use :label
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint,       wrap_with: { tag: "div", class: "form-text text-muted" }
  end

  # ── Auto-select the right wrapper per input type ────────────────────────────

  config.wrapper_mappings = {
    boolean:       :form_check,
    check_boxes:   :collection,
    radio_buttons: :collection,
    file:          :file_input,
    range:         :range_input,
    select:        :select_input
  }

  config.default_wrapper = :default
end
