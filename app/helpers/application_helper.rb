module ApplicationHelper
  def active_at(*locations)
    locations.each do |location|
      current_controller, current_action = location.split('#')

      if current_action
        if [params[:controller], params[:action]] == [current_controller, current_action]
          return 'active'
        end
      elsif controller_name == current_controller
        return 'active'
      end
    end

    return nil
  end
end
