class HomeController < ApplicationController

  def help
    respond_to do |format|
			format.html
		end
  end
 
  def about
    respond_to do |format|
			format.html
		end
  end
  
end
