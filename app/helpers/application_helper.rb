################################################################################
#
# Application Helper
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

module ApplicationHelper

	# Determines the CSS class of the flash message for display from the 
	# specified level.

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

	#-----------------------------------------------------------------------------

	# Adds a warning message to the specified resource
	
	def warning(resource, message)
		resource_message(:warning, resource, message)
	end

	#-----------------------------------------------------------------------------

	# Adds an error message to the specified resource

	def error(resource, message)
		resource_message(:error, resource, message)
	end

	#-----------------------------------------------------------------------------

	# Adds a message associated with the specified resource.

	def resource_message(level, resource, message)
		resource[level] = Array.new unless resource[level].present?

		resource[level].append(message)
	end
	
end
