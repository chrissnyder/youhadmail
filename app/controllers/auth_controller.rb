class AuthController < ApplicationController

	BC_SSO_API_KEY = 'yef5j93u3fabr67bzv2ehpfv'
	BC_SSO_API_ENDPOINT = 'https://api-stage.bibliocommons.com'

	ERR_INVALID_JSON = 1000
	ERR_INVALID_SESSION_ID = 1001
	ERR_UNKNOWN = 1002

	def login
		uri = log_in_url("#{request.protocol}#{request.host_with_port}#{request.fullpath}")
		uri = log_in_url("http://google.com")
		logger.debug "redirecting to #{uri}"
		redirect_to uri
	end

	def info
		# TODO Hack to grab session id in lieu of proper CNAMES
		# Set up local dns redirect to cause test-sso.nypl.org to load nypl.stage2.bibliocommons.com (206.223.184.30)
		# .. Then nav to login url (see log_in_url), log in
		# .. This will create a 'session_id' cookie for test-sso.nypl.org domain
		# .. Which you should enter below:
		cookies[:sso_session_id] = '2b3d05e6-ad46-4c3b-a486-fc9b89fb0b06'
		cookies[:sso_session_id] = 'd1d4f08f-608a-4757-8178-5a81c7dc1e8a'

		@user = get_user

		unless @error_code.nil?
			if [ERR_UNKNOWN, ERR_INVALID_JSON].include? @error_code
				@error_message = "An internal error occurred (code #{@error_code})"

			elsif [ERR_INVALID_SESSION_ID].include? @error_code
				@error_message = "Biblio has renounced your session id. Perhaps you've timed out. Try logging in again."
			end
		end


		render :action => 'login'
	end


	def log_in_url(dest)
		'https://nypl.stage2.bibliocommons.com/user/login?destination=' + URI.encode(dest)
	end

	def log_out_url(dest)
		'https://nypl.stage2.bibliocommons.com/user/logout?destination=' + URI.encode(dest)
	end
  
	def password_reset_url(dest)
		'https://nypl.stage2.bibliocommons.com/user/forgot?destination=' + URI.encode(dest)
	end


	def get_user
		if session[:sso_user].nil?
			check_sso_cookie
		end

		session[:sso_user]
	end

	# Check designaged sso cookie for presense of session_id dropped by sso page
	# Retrieve/create User instance as appropriate and cache in session
	def check_sso_cookie
		# sso_session_id is the sole determiner of login state; Its absense indicates we're logged out
		if cookies[:sso_session_id].nil? # TODO also check if empty?
			session[:sso_user] = nil
		end

		# This is where the sso page drops the cookie:
		sess_id = cookies[:sso_session_id]
		url = BC_SSO_API_ENDPOINT + '/v1/sessions/' + sess_id + '?api_key=' + BC_SSO_API_KEY

		Curl::Easy.perform(url) do |curl|
			curl.connect_timeout = 1
			curl.timeout = 2
			curl.follow_location = true
			curl.verbose = true	

			curl.on_body do |resp| 
	
				# This data looks like this:
				#   {"session": {"id": 125379051, "name": "nonword", "borrower_id": "5035845"}}
				# Note: session.id above is not a valid id for /v1/sessions/{id} endpoint 

				logger.debug "got api response: #{p resp}"

				data = {}
				begin
					data = JSON.parse resp
				rescue JSON::ParserError => e
					@error_code = ERR_INVALID_JSON
				end
				
				if data.has_key?('error')
					@error_code = ERR_INVALID_SESSION_ID
					# Invalidate session:
					session[:sso_user] = nil
					cookies[:sso_session_id] = nil

					logger.debug "auth api error: #{p data}"

				elsif data.has_key? 'session'
					session = data['session']
					logger.debug "Got session: #{session}"
					# Look up local user account by id (data[:session].id) and (username if necessary - data[:session].name)
					@user = User.find_by_sso_id session['id']
					if @user.nil?
						username = session['name']
						if User.find_by_username session['name']
							# Username was taken; append session id to end to ensure uniqueness
							username = session['name'] + '.' + session['id']
							# TODO Trigger alt. username selection flow in case user wants to overwrite this ugly username
						end
						# Create user
						@user = User.create(:sso_id => session['id'], :username => username)

					elsif @user.username != session.name
						# TODO: handle case where user changed username on biblio, being careful not to overwrite an alt. username they selected locally
					end
					
					# Authenticate user
					session[:sso_user] = @user
				end

				# per curb docs, on_body handler should return resp size (or else failure handler is triggered)
				resp.size
			end
			curl.on_failure do |curl| 
				# If not already set, flag it as an unknown error
				@error_code ||= ERR_UNKNOWN
			end
		end
	end
end
