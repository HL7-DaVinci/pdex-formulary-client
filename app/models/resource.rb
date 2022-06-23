class Resource
	require "hash_dot"
	# Adds a warning message to the specified resource

	def warning(message)
		@warnings = Array.new unless @warnings.present?
		@warnings.append(message)
	end

	#-----------------------------------------------------------------------------

	# Adds an error message to the specified resource

	def error(message)
		@errors = Array.new unless @errors.present?
		@errors.append(message)
	end

end
