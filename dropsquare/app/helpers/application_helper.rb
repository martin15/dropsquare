module ApplicationHelper
  def flash_type(type)
     return 'danger' if type == 'alert'
     return 'danger' if type == 'error'
     return 'success' if type == 'notice'
  end
end
