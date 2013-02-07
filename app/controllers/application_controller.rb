class ApplicationController < ActionController::Base
	protect_from_forgery

	attr_accessor :current_user

	def current_user
		unless session[:current_user_id].nil?
			User.find(session[:current_user_id])
		end
	end
	helper_method :sessioned_user

	def check_or_create_user
		# session[:current_user] ||= User.create(:email => 'example@example.com')
		if current_user.nil? 
			user = User.create(:email => 'example@example.com')
			session[:current_user_id] = user.id
			logger.debug "created user? #{user.email}, #{user.id}"
			user
		else
			current_user
		end
	end
	helper_method :check_or_create_user

end
