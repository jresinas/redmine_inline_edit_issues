Deface::Override.new :virtual_path  => 'issues/index',
                     :name          => 'direct-edit-multiple-link',
                     :original		=> 'df818bfe864c66cf8c89bd594b0c68ddb8cf1b1a',
                     :insert_bottom	=> "div#query_form_with_buttons p.buttons",
                     :text			=> "<%= link_to_function l(:button_edit), 
                     	\"$('#query_form').attr('action', '\"+(@project ? edit_multiple_project_inline_issues_path(@project) : edit_multiple_inline_issues_path)+\"').submit()\", 
                     	:class => 'icon icon-edit' %>"
