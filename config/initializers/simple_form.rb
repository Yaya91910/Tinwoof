# Form markup tuned for the Tinwoof design system (see components/_form.scss).
SimpleForm.setup do |config|
  config.wrappers :default, class: "field", error_class: "field--invalid", valid_class: nil do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: "field__label"
    b.use :input, class: "field__input", error_class: "field__input--invalid"
    b.use :full_error, wrap_with: { tag: :p, class: "field__error" }
    b.use :hint, wrap_with: { tag: :p, class: "field__hint" }
  end

  config.wrappers :toggle, class: "field field--toggle", error_class: "field--invalid" do |b|
    b.use :html5
    b.use :input, class: "toggle__input"
    b.use :label, class: "toggle__label"
    b.use :full_error, wrap_with: { tag: :p, class: "field__error" }
  end

  config.default_wrapper = :default
  config.wrapper_mappings = { boolean: :toggle }
  config.boolean_style = :inline
  config.button_class = "btn btn--primary btn--block"
  config.error_notification_tag = :div
  config.error_notification_class = "form-alert"
  config.label_text = ->(label, required, _explicit_label) { "#{label} #{required}" }
  config.required_by_default = false
  config.browser_validations = true
  config.generate_additional_classes_for = []
end
