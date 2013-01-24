class ApplicationController < ActionController::Base
	protect_from_forgery

	attr_accessor :current_user

	def current_user
		session[:current_user]
	end
	helper_method :sessioned_user

	def check_or_create_user
		logger.debug "check_or_create_user... #{p session[:current_user]}"
		session[:current_user] ||= User.create(:email => 'example@example.com')
		logger.debug "created user? #{current_user.email}, #{current_user.id}"
		current_user
	end
	helper_method :check_or_create_user

end
