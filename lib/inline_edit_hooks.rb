class InlineEditHooks < Redmine::Hook::ViewListener
  render_on :view_issues_context_menu_start, :partial => "inline_issues/context_menu_hook" 
end