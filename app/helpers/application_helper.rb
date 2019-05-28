################################################################################
#
# Application Helper
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

module ApplicationHelper

	def flash_class(level)
    case level
	    when "notice"
	    	css_class = "alert-info"
	    when "success" 
	    	css_class = "alert-success"
	    when "error"
	    	css_class = "alert-danger"
	    when "alert"
	    	css_class = "alert-danger"
    end

    return css_class
	end

end
