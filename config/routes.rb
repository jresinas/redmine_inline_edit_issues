# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :inline_issues do
  collection do
    get :edit_multiple
    put :update_multiple
  end
end


  
