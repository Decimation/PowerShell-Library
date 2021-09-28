@{
	# Do not analyze the following rules. Use ExcludeRules when you have
	# commented out the IncludeRules settings above and want to include all
	# the default rules except for those you exclude below.
	# Note: if a rule is in both IncludeRules and ExcludeRules, the rule
	# will be excluded.
	ExcludeRules = @('PSAvoidUsingAliases', 'PSAvoidUsingWriteHost', 'PSUseApprovedVerbs', 'PSReviewUnusedParameter', 'PSAvoidGlobalVars',
		'PSUseShouldProcessForStateChangingFunctions', 'PSUseSingularNouns')
}