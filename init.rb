
require_dependency 'inline_edit_hooks'

Redmine::Plugin.register :redmine_inline_edit_issues do
  name 'Inline Edit Issues plugin'
  author 'Ron Elledge - Quoin, Inc.'
  description 'This is a plugin for Redmine.  It allows inline edit of issues in the issues index page.'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://www.quoininc.com'
  
  # Minimum version of Redmine.
  requires_redmine :version_or_higher => '2.0.0'
  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'
  
  project_module :issue_tracking do
  permission :issues_inline_edit, :inline_issues => [:edit_multiple, :update_multiple]
  end
end
