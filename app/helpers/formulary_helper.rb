################################################################################
#
# Formulary Helper
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

module FormularyHelper

	def display_list(list)
		list.map{ |element| element.display }.join(', ')
	end

	#-----------------------------------------------------------------------------

	def code_list(list)
		list.map{ |element| element.code }.join(', ')
	end

end
