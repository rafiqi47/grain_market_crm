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

  def role_based_dashboard_path(user)
    return root_path unless user

    case user.role.to_sym
    when :super_admin
      admin_root_path
    when :owner, :manager
      dashboard_index_path
    else
      root_path
    end
  end
end
