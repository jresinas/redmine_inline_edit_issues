module InlineIssuesHelper
  include CustomFieldsHelper

  def inline_project_id
    @project.present? ? @project.id : ""
  end
  
  def column_form_content(column, issue, f)
    if(column.class.name == "QueryCustomFieldColumn")      
      custom_field_values = issue.editable_custom_field_values
      value = custom_field_values.detect{|cfv| cfv.custom_field_id == column.custom_field.id}
      custom_field_tag :issues, value, issue if value.present?
    else 
      case column.name
      when :tracker
        f.select :tracker_id, issue.project.trackers.collect {|t| [t.name, t.id]}
      when :status
        f.select :status_id, issue.new_statuses_allowed_to.collect {|p| [p.name, p.id]}
      when :priority
        f.select :priority_id, @priorities.collect {|p| [p.name, p.id]}
      when :subject
        f.text_field :subject, size: 20
      when :assigned_to
        f.select :assigned_to_id, principals_options_for_select(issue.assignable_users, issue.assigned_to), :include_blank => true
      when :estimated_hours
        f.text_field :estimated_hours, size: 3
      when :start_date
        f.text_field(:start_date, size: 8) +
        calendar_for('issues_'+issue.id.to_s+'_start_date') 
      when :due_date
        f.text_field(:due_date, size: 8) +
        calendar_for('issues_'+issue.id.to_s+'_due_date')
      when :done_ratio 
        f.select :done_ratio, ((0..10).to_a.collect {|r| ["#{r*10} %", r*10] })
      when :is_private
        f.check_box :is_private
      when :description
        f.text_area :description
      when :category
        f.select :category_id, [["",""]] + issue.project.issue_categories.collect {|t| [t.name, t.id]}
      when :fixed_version
        f.select :fixed_version_id, [["",""]] + issue.project.versions.collect {|t| [t.name, t.id]}
      else
        column_display_text(column, issue)
      end    
    end
  end
  
  def column_display_text(column, issue)    
    value = column.value(issue)
    
    case value.class.name
    when 'Time'
      format_time(value)
    when 'Date'
      format_date(value)
    when 'Float'
      sprintf "%.2f", value
    when 'TrueClass'
      l(:general_text_Yes)
    when 'FalseClass'
      l(:general_text_No)
    else
      h(value)
    end
  end
  
  def column_total(column, issues)
    case column.name
    when :estimated_hours
      totalEstHours(issues)
    when :spent_hours
      totalSpentHours(issues)
    end    
  end
  
  def group_column_total(column, issues, group)
    case column.name
    when :estimated_hours
      totalGroupEstHours(issues, group)
    when :spent_hours
      totalGroupSpentHours(issues, group)
    end 
  end
  
  def inline_edit_condition
    cond = "issues.id in (#{@ids.map{|i| i.to_i}.join(",")})"
  end
  
  def group_class_name(group)
    begin
      if group.present?
        # strip out white spaces from the group name
        "group_" + group.name.gsub(/\s+/,"")
      else
        ""
      end
    rescue
      ""
    end
  end
  
  def group_total_name(group, column)
    if group.present? && column.present?
      "#{group_class_name(group)}_total_#{column.name}"
    else
      ""
    end
  end
  
  private
  
  def totalEstHours(issues)
    estTotal = 0
    issues.each {|i| estTotal += i.estimated_hours if i.estimated_hours.present?}
    sprintf "%.2f", estTotal
  end
  
  def totalSpentHours(issues)
    spentTotal = 0
    issues.each {|i| spentTotal += i.spent_hours if i.spent_hours.present?}
    sprintf "%.2f", spentTotal
  end
  
  def totalGroupEstHours(issues, group)
    estTotal = 0
    issues.each do |i| 
      if i.estimated_hours.present? &&  @query.group_by_column.value(i) == group
        estTotal += i.estimated_hours
      end
    end
    sprintf "%.2f", estTotal
  end
  
  def totalGroupSpentHours(issues, group)
    spentTotal = 0
    issues.each do |i| 
      if i.spent_hours.present? &&  @query.group_by_column.value(i) == group
        spentTotal += i.spent_hours 
      end
    end
    sprintf "%.2f", spentTotal
  end
  
  
  #####
  # Return custom field html tag corresponding to its format
  #####
  def custom_field_tag(name, custom_value, issue)
    custom_field = custom_value.custom_field
    field_name = "#{name}[#{issue.id}][custom_field_values][#{custom_field.id}]"
    field_name << "[]" if custom_field.multiple?
    field_id = "#{name}_custom_field_values_#{custom_field.id}"

    tag_options = {:id => field_id, :class => "#{custom_field.field_format}_cf"}

    field_format = Redmine::FieldFormat.find(custom_field.field_format)
    case custom_field.field_format
    when "date"
      text_field_tag(field_name, custom_value.value, tag_options.merge(:size => 10)) +
      calendar_for(field_id)
    when "text"
      text_area_tag(field_name, custom_value.value, tag_options.merge(:rows => 4, :cols => 65, :style => "width:auto; resize:both;"))
    when "bool"
      custom_value.custom_field.format.edit_tag self,
        field_id,
        field_name,
        custom_value,
        :class => "#{custom_value.custom_field.field_format}_cf"
    when "list"
    when "enumeration"
      blank_option = ''.html_safe
      unless custom_field.multiple?
        if custom_field.is_required?
          unless custom_field.default_value.present?
            blank_option = content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---", :value => '')
          end
        else
          blank_option = content_tag('option')
        end
      end
      s = select_tag(field_name, blank_option + options_for_select(custom_field.possible_values_options(custom_value.customized), custom_value.value),
        tag_options.merge(:multiple => custom_field.multiple?))
      if custom_field.multiple?
        s << hidden_field_tag(field_name, '')
      end
      s
    else
      text_field_tag(field_name, custom_value.value, tag_options)
    end
  end
  
end
