﻿<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	27.12.2017 08:40
	 Created by:   	R41Z0R
	 Organization: 	
	 Filename:     	Woocommerce.psd1
	 -------------------------------------------------------------------------
	 Module Manifest
	-------------------------------------------------------------------------
	 Module Name: Woocommerce
	===========================================================================
#>


@{
	
	# Script module or binary module file associated with this manifest
	RootModule             = 'Woocommerce.psm1'
	
	# Version number of this module.
	ModuleVersion          = '1.1.2'
	
	# ID used to uniquely identify this module
	GUID                   = '5455e4ea-11e5-48eb-bd6a-e2855ae12008'
	
	# Author of this module
	Author                 = 'R41Z0R, Thomas Subotitsch'
	
	# Company or vendor of this module
	CompanyName            = ''
	
	# Copyright statement for this module
	Copyright              = '(c) 2017, 2025'
	
	# Description of the functionality provided by this module
	Description            = 'Manage your WooCommerce Shop with REST-API in PowerShell'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion      = '3.0'
	
	# Name of the Windows PowerShell host required by this module
	PowerShellHostName     = ''
	
	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion  = ''
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '2.0'
	
	# Minimum version of the common language runtime (CLR) required by this module
	CLRVersion             = '2.0.50727'
	
	# Processor architecture (None, X86, Amd64, IA64) required by this module
	ProcessorArchitecture  = 'None'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules        = @()
	
	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies     = @()
	
	# Script files (.ps1) that are run in the caller's environment prior to
	# importing this module
	ScriptsToProcess       = @()
	
	# Type files (.ps1xml) to be loaded when importing this module
	TypesToProcess         = @()
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess       = @()
	
	# Modules to import as nested modules of the module specified in
	# ModuleToProcess
	NestedModules          = @()
	
	# Functions to export from this module
	FunctionsToExport      = @(
		'Get-WooCommerceCategory',
		'Get-WooCommerceCustomer',
		'Get-WooCommerceData',
		'Get-WooCommerceOrder',
		'Get-WooCommerceOrderNote',
		'Get-WooCommercePaymentGateway',
		'Get-WooCommerceProduct',
		'Get-WooCommerceProductReview',
		'Get-WooCommerceProductTag',
		'Get-WooCommerceProductVariation',
		'Get-WooCommerceRefund',
		'Get-WooCommerceSetting',
		'Get-WooCommerceSettingOption',
		'Get-WooCommerceShippingMethod',
		'Get-WooCommerceShippingZone',
		'Get-WooCommerceShippingZoneLocation',
		'Get-WooCommerceShippingZoneMethod',
		'Get-WooCommerceWebhook',
		'Invoke-WooCommerceAPICall',
		'New-WooCommerceProduct',
		'Remove-WooCommerceCustomer',
		'Remove-WooCommerceOrderNote',
		'Remove-WooCommerceProductReview',
		'Remove-WooCommerceProduct',
		'Set-WooCommerceCredential',
		'Set-WooCommerceProduct'
	) #For performanace, list functions explicity
	
	# Cmdlets to export from this module
	CmdletsToExport        = @(	)
	
	# Variables to export from this module
	#VariablesToExport		  = @()
	
	# Aliases to export from this module
	#AliasesToExport		      = @() #For performanace, list alias explicity
	
	# List of all modules packaged with this module
	ModuleList             = @()
	
	# List of all files packaged with this module
	FileList               = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData            = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			# Tags = @()
			
			# A URL to the license for this module.
			# LicenseUri = ''
			
			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/R41z0r/Woocommerce_Module'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			# ReleaseNotes = ''
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}







