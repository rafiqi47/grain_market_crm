module ApplicationHelper
  def custom_button(color: "primary", variant: "contained", disabled: false, is_submit: false, full_width: false, &block)
    content = capture(&block)
    render(
      "components/button",
      color: color,
      variant: variant,
      disabled: disabled,
      is_submit: is_submit,
      full_width: full_width,
      content: content
    )
  end
end
