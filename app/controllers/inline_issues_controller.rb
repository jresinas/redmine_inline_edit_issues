class InlineIssuesController < ApplicationController
  before_filter :find_project, :authorize, :only => [:edit_multiple, :update_multiple]
  unloadable

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  include InlineIssuesHelper

  def edit_multiple
    retrieve_query
    get_ids    
    description_column = @query.columns.select{|c| c.name == :description}.first
    @query_inline_columns = description_column.present? ? 
      @query.inline_columns.insert(1, description_column) :
      @query.inline_columns

    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid? 
      @limit = per_page_option
      @issue_count = @query.issue_count
      @issue_pages = Paginator.new @issue_count, @limit, params['page']
      @offset ||= @issue_pages.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit,
                              :conditions => inline_edit_condition)
                              
      @issue_count_by_group = issue_count_by_group
      
      @priorities = IssuePriority.active
    else
      # respond_to do |format|
        # format.html { render(:template => 'issues/index', :layout => !request.xhr?) }
        # format.any(:atom, :csv, :pdf) { render(:nothing => true) }
        # format.api { render_validation_errors(@query) }
      # end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update_multiple
    errors = []
    Issue.find(params[:issues].keys).each do |i|
      upd = i.update_attributes(params[:issues][i.id.to_s])
      errors += i.errors.full_messages.map{|m| l(:label_issue)+" #{i.id}: "+m} if !upd
    end

    if errors.present?
      flash[:error] = errors.to_sentence
      redirect_to :back
    else
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default _project_issues_path(@project)
    end
  end
  
  private
  
  def get_ids
    @ids = []
    if params[:ids].present?
      if params[:ids].class.name == "Array"
        @ids = params[:ids]
      elsif params[:ids].class.name == "String"
        @ids = params[:ids].split(" ")
      end
    else
      @ids = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version]).map(&:id)
    end
  end
  
  def find_project
    @project = Project.find(params[:project_id]) if params[:project_id].present?
  end
  
  # Returns the issue count by group or nil if query is not grouped
  def issue_count_by_group
    r = nil
    if @query.grouped?
      begin
        # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = Issue.visible.
          joins(:status, :project).
          where(@query.statement).
          joins(joins_for_order_statement(@query.group_by_statement)).
          group(@query.group_by_statement).
          where(inline_edit_condition).
          count
      rescue ActiveRecord::RecordNotFound
        r = {nil => issue_count}
      end
      c = @query.group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
  
  # Additional joins required for the given sort options
  def joins_for_order_statement(order_options)
    joins = []

    if order_options
      if order_options.include?('authors')
        joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{queried_table_name}.author_id"
      end
      order_options.scan(/cf_\d+/).uniq.each do |name|
        column = available_columns.detect {|c| c.name.to_s == name}
        join = column && column.custom_field.join_for_order_statement
        if join
          joins << join
        end
      end
    end

    joins.any? ? joins.join(' ') : nil
  end
  
end
