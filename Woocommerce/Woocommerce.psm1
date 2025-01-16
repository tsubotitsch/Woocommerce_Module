<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	27.12.2017 08:40
	 Created by:   	R41Z0R
	 Updated by:   	TSubotitsch
	 Organization: 	
	 Filename:     	Woocommerce.psm1
	-------------------------------------------------------------------------
	 Module Name: Woocommerce
	===========================================================================
#>

$filterParameter = @(
	"Verbose",
	"Debug",
	"ErrorAction",
	"WarningAction",
	"InformationAction",
	"ErrorVariable",
	"WarningVariable",
	"InformationVariable",
	"OutVariable",
	"OutBuffer",
	"PipelineVariable",
	"WhatIf",
	"Confirm"
)
$script:woocommerceApiPrefix = "wp-json/wc/v3"

#region Helper Functions

#region Credentials
<#
	.SYNOPSIS
		Check for the WooCommerce credentials and uri
	
	.DESCRIPTION
		Check the local variables, if the WooCommerce Base-Authentication and uri is provided to connect to the remote uri
	
	.EXAMPLE
		PS C:\> Get-WooCommerceCredential
	
	.NOTES
		Additional information about the function.
#>
function Get-WooCommerceCredential {
	if ($script:woocommerceUrl -and $script:woocommerceBase64AuthInfo) {
		return $true
	}
	else {
		Write-Error -Message "You have to run 'Set-WooCommerceCredential' first" -Category AuthenticationError
		return $false
	}
}


<#
	.SYNOPSIS
		A brief description of the Set-WooCommerceCredential function.
	
	.DESCRIPTION
		A detailed description of the Set-WooCommerceCredential function.
	
	.PARAMETER url
		The url of your WooCommerce installation
	
	.PARAMETER apiKey
		The api Key provided by WooCommerce
	
	.PARAMETER apiSecret
		The api secret provided by WooCommerce
	
	.EXAMPLE
		PS C:\> Set-WooCommerceCredential -url 'Value1' -apiKey 'Value2' -apiSecret 'Value3'
	
	.NOTES
		Additional information about the function.
#>
function Set-WooCommerceCredential {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true,
			Position = 1, HelpMessage = "The root url of your WooCommerce installation")]
		[ValidateNotNullOrEmpty()]
		[System.String]$url,
		[Parameter(Mandatory = $true,
			Position = 2, ParameterSetName = "UsernamePassword", HelpMessage = "The api key provided by WooCommerce")]
		[ValidateNotNullOrEmpty()]
		[System.String]$apiKey,
		[Parameter(Mandatory = $true,
			Position = 3, ParameterSetName = "UsernamePassword", HelpMessage = "The api secret provided by WooCommerce")]
		[ValidateNotNullOrEmpty()]
		[System.String]$apiSecret
		# [Parameter(Mandatory = $true,
		# 	Position = 2, ParameterSetName = "Credential")]
		# [System.Management.Automation.PSCredential]$APICredential
	)
	
	If ($PSCmdlet.ShouldProcess("Check if the provided credentials and uri is correct")) {
		Try {
			Write-Debug "GET $url/$script:woocommerceApiPrefix"
			Write-Debug (@{ Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $apiKey, $apiSecret))) } | Out-String)
			Invoke-RestMethod -Method GET -Uri "$url/$script:woocommerceApiPrefix" -Headers @{ Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $apiKey, $apiSecret))) } -ErrorAction Stop | Out-Null
			# $authHeader = @{
			# 	Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $apiKey, $apiSecret)))
			# }
			# $invokeParams = @{
			# 	Method      = 'GET'
			# 	Uri         = "$url/$script:woocommerceApiPrefix"
			# 	Headers     = $authHeader
			# 	ErrorAction = 'Stop'
			# }
			# Write-Debug ($invokeParams | Out-String)
			# Invoke-WooCommerceAPICall @invokeParams | Out-Null

			$script:woocommerceApiSecret = $apiSecret
			$script:woocommerceApiKey = $apiKey
			$script:woocommerceBase64AuthInfo = @{
				Authorization = ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $script:woocommerceApiKey, $script:woocommerceApiSecret))))
			}
			$script:woocommerceUrl = $url
		}
		catch {
			Write-Error -Message "Wrong Credentials or URL" -Category AuthenticationError -RecommendedAction "Please provide valid Credentials or the right uri"
		}
	}
}
#endregion Credentials
function Invoke-WooCommerceAPICall {
	param (
		[Parameter (Mandatory = $true, HelpMessage = "The relative url of the WooCommerce API e.g. /products")]
		$RelativeUrl,
		[Parameter (Mandatory = $true, HelpMessage = "The HTTP Method to use e.g. GET")]
		[ValidateSet("GET", "POST", "PUT", "DELETE")]
		$Method,
		$Headers = $script:woocommerceBase64AuthInfo,
		$Body = $null
	)

	# construct the absolute url
	$url = $script:woocommerceUrl + "/" + $script:woocommerceApiPrefix + $RelativeUrl
	Write-Debug " RelativeUrl: $RelativeUrl"
	Write-Debug "$Method $url"

	try {
		$invokeParams = @{
			Method                  = $Method
			Uri                     = "$url"
			Headers                 = $script:woocommerceBase64AuthInfo
			Body                    = $Body
			ResponseHeadersVariable = 'responseHeaders'
			ContentType             = 'application/json'
		}
		$result = Invoke-RestMethod @invokeParams

		if ($result) {
			# loop trough all following pages and add to result if available
			if ($responseHeaders.'X-WP-TotalPages') {
				Write-Debug -Message "Total#: $($responseHeaders.'X-WP-Total')"
				Write-Debug -Message "TotalPages: $($responseHeaders.'X-WP-TotalPages')"
				$i = 2
				while ($i -le [int]($responseHeaders.'X-WP-TotalPages'[0])) {
					Write-Debug -Message "GET $($url)?page=$i"
					$invokeParams.Uri = "$($url)?page=$i"
					$result += Invoke-RestMethod @invokeParams
					$i++
				}
			}		
			return $result
		}
		else {
			return $null
		}
	}
	catch {
		$errorMessage = $_.Exception.Message
		Write-Error -Message "Error while calling the WooCommerce API with url $($url):`n $errorMessage" -Category InvalidOperation
		return $null
	}
}
#endregion Helper Functions

#region Order
<#
	.SYNOPSIS
		Return a list of WooCommerce orders
	
	.DESCRIPTION
		Returns a list or a single WooCommerce order based on the parameters provided
	
	.PARAMETER id
		The id of your WooCommerce order
	
	.PARAMETER all
		Return all orders if nothing is set or if explicitly set
	
	.EXAMPLE
		PS C:\> Get-WooCommerceOrder
	
	.NOTES
		Additional information about the function.
#>
function Get-WooCommerceOrder {
	param
	(
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[Parameter(Position = 2, HelpMessage = "Limit result set to orders assigned a specific status. Options: any, pending, processing, on-hold, completed, cancelled, refunded, failed and trash. Default is any." )]
		[ValidateSet('any', 'pending', 'processing', 'on-hold', 'completed', 'cancelled', 'refunded', 'failed', 'trash')]
		[string]$Status = 'any',
		[Parameter(Position = 3, HelpMessage = "Limit result set to orders assigned a specific customer_id. Default is 0.")]
		$customer_id = "0",
		[Parameter()]
		[string]$addquery,
		[Parameter(HelpMessage = "Limit response to resources published before a given ISO8601 compliant date.")]
		$before,
		[Parameter(HelpMessage = "Limit response to resources published after a given ISO8601 compliant date.")]
		$after,
		[Parameter(HelpMessage = "Order sort attribute ascending or descending. Options: asc, desc. Default is asc.")]
		[ValidateSet('asc', 'desc')]
		$order = 'asc',
		[Parameter(HelpMessage = "Sort collection by object attribute. Options: id, include, title, slug, date. Default is date.")]
		[ValidateSet('id', 'include', 'title', 'slug', 'date')]
		$orderby = 'date'		
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/orders"
		if ($id) {
			$url += "/$id"
		}
		else {
			$url += "?status=$Status&customer_id=$customer_id&orderby=$orderby&order=$order"
			if ($before) {
				$before_date = Get-Date $before -Format "yyyy-MM-ddTHH:mm:ss"
				$url += "&before=$before_date"
			}
			if ($after) {
				$after_date = Get-Date $after -Format "yyyy-MM-ddTHH:mm:ss"
				$url += "&after=$after_date"
			}
		}
		if ($addquery) {
			$url += $addquery
		}
		#$result = Invoke-RestMethod -Method GET -Uri "$url" -Headers $script:woocommerceBase64AuthInfo
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
}

function Get-WooCommerceOrderNote {
	param
	(
		[Parameter(Mandatory = $true , Position = 1, HelpMessage = "The id of the order")]
		[Alias("OrderId")]
		[System.String]$id,
		[Parameter(Position = 2, HelpMessage = "The id of the note")]
		[string]$NoteId
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/orders/$id/notes"
		if ($id -and !$all) {
			$url += "/$id"
		}
		if ($NoteId) {
			$url += "/$NoteId"
		}
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
}

function Remove-WooCommerceOrderNote {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, HelpMessage = "The id of the order")]
		[Alias("OrderId")]
		[System.String]$id,
		[Parameter(Mandatory = $true, Position = 2, HelpMessage = "The id of the note")]
		[string]$NoteId
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/orders/$id/notes"
		if ($id -and !$all) {
			$url += "/$id"
		}
		if ($NoteId) {
			$url += "/$NoteId"
		}
		if ($pscmdlet.ShouldProcess("Remove order note $id")) {
			$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
			return $result
		}
		else {
			return $null
		}
	}
}
#endregion Order

#region Tag
function Get-WooCommerceProductTag {
	param
	(
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[Parameter(Position = 2)]
		[switch]$all
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/products/tags"
		if ($id -and !$all) {
			$url += "/$id"
		}
		#$result = Invoke-RestMethod -Method GET -Uri "$url" -Headers $script:woocommerceBase64AuthInfo -ResponseHeadersVariable responseHeaders
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
}
#endregion Tag

#region Product
<#
	.SYNOPSIS
		Creates a new WooCommerce product
	
	.DESCRIPTION
		Creates a new WooCommerce product with the specified parameters
	
	.PARAMETER name
		Provide a name for your product
	
	.PARAMETER type
		Defines the type of the product, avaible types are:
		simple, grouped, external and variable.
		Default is simple
	
	.PARAMETER description
		Provide a description of your product
	
	.PARAMETER short_description
		Provide a brief description of the product
	
	.PARAMETER status
		Defines the status of the product:
		draft, pending, private or publish
	
	.PARAMETER slug
		Slug is used for permalink, define property for custom permalink
	
	.PARAMETER featured
		Set the product as a featured product
	
	.PARAMETER catalog_visibility
		Defines the visibility to the catalog
		visible, catalog, search, hidden
	
	.PARAMETER sku
		Unique identifier of a product
	
	.PARAMETER regular_price
		Set the regular_price of your product
	
	.PARAMETER sale_price
		Price for products on sale
	
	.PARAMETER date_on_sale_from
		A description of the date_on_sale_from parameter.
	
	.PARAMETER date_on_sale_to
		A description of the date_on_sale_to parameter.
	
	.PARAMETER virtual
		A description of the virtual parameter.
	
	.PARAMETER downloadable
		A description of the downloadable parameter.
	
	.EXAMPLE
		PS C:\> New-WooCommerceProduct -regular_price $value1 -name 'Value2' -description 'Value3' -short_description 'Value4'
	
	.NOTES
		Additional information about the function.
#>
function New-WooCommerceProduct {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]$name,
		[ValidateSet('external', 'grouped', 'simple', 'variable')]
		[ValidateNotNullOrEmpty()]
		[System.String]$type = 'simple',
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.String]$description,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[System.String]$short_description,
		[ValidateSet('draft', 'pending', 'private', 'publish')]
		[ValidateNotNullOrEmpty()]
		[System.String]$status = 'publish',
		[ValidateNotNullOrEmpty()]
		[System.String]$slug,
		[ValidateSet('false', 'true')]
		[ValidateNotNullOrEmpty()]
		[System.String]$featured = 'false',
		[ValidateSet('visible', 'catalog', 'search', 'hidden')]
		[ValidateNotNullOrEmpty()]
		[System.String]$catalog_visibility = 'visible',
		[ValidateNotNullOrEmpty()]
		[System.String]$sku,
		[ValidateNotNullOrEmpty()]
		[double]$regular_price,
		[ValidateNotNullOrEmpty()]
		[double]$sale_price,
		[ValidateNotNullOrEmpty()]
		[datetime]$date_on_sale_from,
		[ValidateNotNullOrEmpty()]
		[datetime]$date_on_sale_to,
		[ValidateSet('false', 'true')]
		[ValidateNotNullOrEmpty()]
		[System.String]$virtual = 'false',
		[ValidateSet('false', 'true')]
		[ValidateNotNullOrEmpty()]
		[System.String]$downloadable = 'false'
	)
	
	If ($PSCmdlet.ShouldProcess("Create a new product")) {
		If (Get-WooCommerceCredential) {
			$query = @{
			}
			$url = "$script:woocommerceUrl/$script:woocommerceProducts"
			
			$CommandName = $PSCmdlet.MyInvocation.InvocationName
			$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object {
				$_ -notin $filterParameter
			}
			
			ForEach ($Parameter In $ParameterList) {
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				If ($var.Value -match "\d|\w") {
					$value = $var.Value
					If ($var.Name -in @("date_on_sale_from", "date_on_sale_to")) {
						$value = Get-Date $value -Format s
					}
					$query += @{
						$var.Name = "$value"
					}
				}
			}
			$json = $query | ConvertTo-Json
			$result = Invoke-RestMethod -Method POST -Uri "$url" -Headers $script:woocommerceBase64AuthInfo -Body $json -ContentType 'application/json'
			If ($result) {
				Return $result
			}
		}
	}
}

function Get-WooCommerceProduct {
	<#
	.SYNOPSIS
		Return a list of WooCommerce products
	
	.DESCRIPTION
		Returns a list or a single WooCommerce product based on the parameters provided
	
	.PARAMETER all
		Return all products if nothing is set or if explicitly set
	
	.PARAMETER id
		The id of your WooCommerce product
	
	.EXAMPLE
		PS C:\> Get-WooCommerceProduct
	
	.NOTES
		Additional information about the function.
#>
	param
	(
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[Parameter(Position = 2)]
		[switch]$all,
		[Parameter(Position = 3)]
		[string]$addquery,
		[Parameter(HelpMessage = "Sort products ascending or descending. Options: asc, desc. Default is asc.")]
		[ValidateSet('asc', 'desc')]
		$order = 'asc',
		[Parameter(HelpMessage = "Sort products by attribute. Options: id, include, title, slug, date. Default is date.")]
		[ValidateSet('id', 'include', 'title', 'slug', 'date')]
		$orderby = 'date',
		[Parameter(HelpMessage = "Limit result set to products with a specific SKU.")]
		$sku,
		[Parameter(HelpMessage = "Limit result set to products assigned to a specific category_id.")]
		$category,
		[Parameter(HelpMessage = "Limit result set to products assigned to a specific tag.")]
		$tag,
		[Parameter(HelpMessage = "Limit result set to products with a specific stock status. Options: instock, outofstock, onbackorder. Default is instock.")]
		[ValidateSet('instock', 'outofstock', 'onbackorder')]
		$stockstatus = 'instock',
		[Parameter(HelpMessage = "Limit result set to products on sale.")]
		$on_sale
	)
	if (Get-WooCommerceCredential) {
		$url = "/products"
		if ($id -and !$all) {
			$url += "/$id"
		}
		else {
			$url += "?orderby=$orderby&order=$order&stock_status=$stockstatus"
			if ($sku) {
				$url += "&sku=$sku"
			}
			if ($category) {
				$url += "&category=$category"
			}
			if ($tag) {
				$url += "&tag=$tag"
			}
			if ($addquery) {
				$url += $addquery
			}
			if ($on_sale) {
				$url += "&on_sale=$on_sale"
			}
		}
		Write-Debug -Message "GET $url"
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
}

function Get-WooCommerceProductVariation {
	param
	(
		[Parameter(Mandatory = $true, Position = 1, HelpMessage = "The id of the product")]
		[ValidateNotNullOrEmpty()]
		[System.String]$ProductId,
		[Parameter(Position = 2, HelpMessage = "The id of the variation")]
		[string]$VariationId,
		$order = 'asc',
		[Parameter(HelpMessage = "Sort productvariants by attribute. Options: id, include, title, slug, date. Default is date.")]
		[ValidateSet('id', 'include', 'title', 'slug', 'date')]
		$orderby = 'date',
		[Parameter(HelpMessage = "Limit result set to product variants with a specific SKU.")]
		$sku,
		[Parameter(HelpMessage = "Limit result set to product variants with a specific slug.")]
		$slug,
		[Parameter(HelpMessage = "Limit result set to product variants on sale.")]
		$on_sale,
		[Parameter(HelpMessage = "Limit result set to product variants with a specific stock status. Options: instock, outofstock, onbackorder.")]
		[ValidateSet('instock', 'outofstock', 'onbackorder')]
		$stock_status
	)
	if (Get-WooCommerceCredential) {
		$url = "/products/$ProductId/variations"
		if ($VariationId) {
			$url = "/$VariationId"
		}
		else {
			$url += "?orderby=$orderby&order=$order"
			if ($sku) {
				$url += "&sku=$sku"
			}
			if ($slug) {
				$url += "&slug=$slug"
			}
			if ($on_sale) {
				$url += "&on_sale=$on_sale"
			}
			if ($stock_status) {
				$url += "&stock_status=$stock_status"
			}
		}
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
}

<#
	.SYNOPSIS
		Remove the provided WooCommerce product
	
	.DESCRIPTION
		Remove the provided WooCommerce product
	
	.PARAMETER id
		The id of the WooCommerce product to remove
	
	.PARAMETER permanently
		If set, the product will be deleted permanently
	
	.EXAMPLE
		PS C:\> Remove-WooCommerceProduct -id 'Value1'
	
	.NOTES
		Additional information about the function.
#>
function Remove-WooCommerceProduct {
	
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param
	(
		[Parameter(Mandatory = $true,
			Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[switch]$permanently = $false
	)
	
	if ($pscmdlet.ShouldProcess("Remove product $id")) {
		if (Get-WooCommerceCredential) {
			$url = "/products/$id"
			if ($permanently) {
				$url += "?force=true"
			}
			Write-Debug "DELETE $url"
			$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "DELETE"
			Return $result
		}
	}
 else {
		Return $null
	}
}

<#
	.SYNOPSIS
		Modifys a WooCommerce product
	
	.DESCRIPTION
		Modifys a WooCommerce product with the specified parameters
	
	.PARAMETER id
		A description of the id parameter.
	
	.PARAMETER price
		Set the price of your product
	
	.PARAMETER name
		Provide a name for your product
	
	.PARAMETER description
		Provide a description of your product
	
	.PARAMETER short_description
		Provide a brief description of the product
	
	.EXAMPLE
		PS C:\> Set-WooCommerceProduct -id 'Value1'
	
	.NOTES
		Additional information about the function.
#>
function Set-WooCommerceProduct {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true,
			Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[ValidateNotNullOrEmpty()]
		[System.String]$regular_price,
		[ValidateNotNullOrEmpty()]
		[System.String]$name,
		[ValidateNotNullOrEmpty()]
		[System.String]$description,
		[ValidateNotNullOrEmpty()]
		[System.String]$short_description
	)
	
	if ($pscmdlet.ShouldProcess("Modify product $id")) {
		if (Get-WooCommerceCredential) {
			$query = @{ }
			
			$CommandName = $PSCmdlet.MyInvocation.InvocationName
			$ParameterList = (Get-Command -Name $CommandName).Parameters.Keys | Where-Object { $_ -notin $filterParameter }
			
			foreach ($Parameter in $ParameterList) {
				$var = Get-Variable -Name $Parameter -ErrorAction SilentlyContinue
				if ($var.Value -match "\d|\w") {
					$query += @{ $var.Name = $var.Value }
				}
			}
			if ($query.Count -gt 0) {
				$json = $query | ConvertTo-Json
				$result = Invoke-WooCommerceAPICall -RelativeUrl "/products/$id" -Method "PUT" -Body $json
				return $result
			}
			else {
				Write-Error -Message "No value provided" -Category InvalidData
			}
		}
	}
}

function Get-WooCommerceProductReview {
	param
	(
		[Parameter(Position = 1, HelpMessage = "The id of the product")]
		[ValidateNotNullOrEmpty()]
		[System.String]$ProductId
	)
	if (Get-WooCommerceCredential) {
		$url = "/products/reviews"
		if ($id) {
			$url += "/$id"
		}
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
}

function Remove-WooCommerceProductReview {	
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param
	(
		[Parameter(Mandatory = $true,
			Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[switch]$permanently = $false
	)
	
	if ($pscmdlet.ShouldProcess("Remove product $id")) {
		if (Get-WooCommerceCredential) {
			$url = "/products/reviews/$id"
			if ($permanently) {
				$url += "?force=true"
			}
			Write-Debug "DELETE $url"
			$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "DELETE"
			Return $result
		}
	}
 else {
		Return $null
	}
}
#endregion Product

#region Category
function Get-WooCommerceCategory {
	
	param
	(
		[Parameter(Position = 1, HelpMessage = "The id of the category, if not set, all categories will be returned")]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[string]$addquery
	)
	if (Get-WooCommerceCredential) {
		$url = "/products/categories"
		if ($id) {
			$url += "/$id"
		}
		
		if ($addquery) {
			$url += $addquery
		}
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
}

#endregion Category

#region Customer
function Get-WooCommerceCustomer {
	param
	(
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$id,
		[Parameter(Position = 2, HelpMessage = "imit result set to resources with a specific role. Options: all, administrator, editor, author, contributor, subscriber, customer and shop_manager. Default is customer.")]
		[ValidateSet("all", "administrator", "editor", "author", "contributor", "subscriber", "customer", "shop_manager")]
		$role = 'customer',
		[Parameter(Position = 3)]
		[ValidateSet("id", "include", "name", "registered_date")]
		$orderby = 'id',
		[Parameter(Position = 4)]
		[ValidateSet("asc", "desc")]
		$order = 'asc'
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/customers"
		if ($id) {
			$url += "/$id"
		}
		else {
			Write-Debug "Role: $role OrderBy: $orderby"
			$url += "?role=$($role)&orderby=$($orderby)&order=$($order)"
		}
		Write-Debug "GET $url"
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
 else {
		return $null
	}
}

function Remove-WooCommerceCustomer {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param
	(
		[Parameter(Position = 1, HelpMessage = "The id of the customer")]
		[ValidateNotNullOrEmpty()]
		[System.String]$id
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/customers/$id"
		if ($PSCmdlet.ShouldProcess($id)) {
			$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "DELETE"
			return $result
		}
		else {
			return $null
		}
	}
}
#endregion Customer

#region refunds
function Get-WooCommerceRefund {
	param
	(
		[Parameter(Position = 1)]
		[System.String]$addquery
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/customers"
		if ($addquery) {
			$url += "/$addquery"
		}
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}
#endregion refunds

#region Webhooks
function Get-WooCommerceWebhook {
	param
	(
		[Parameter(Position = 1)]
		$id,
		[Parameter(Position = 2, HelpMessage = "Limit result set to resources with a specific status. Options: all, active, inactive, paused, disabled. Default is all.")]
		[ValidateSet("all", "active", "inactive", "paused", "disabled")]
		$status = "all",
		[System.String]$addquery
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/webhooks"
		if ($id) {
			$url += "/$id"
		} else {
			$url += "?status=$status"
		}
		if ($addquery) {
			$url += "/$addquery"
		}
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}
#endregion Webhooks

#region Settings
function Get-WooCommerceSetting {
	param
	(
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/settings"
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}

function Get-WooCommerceSettingOption {
	param
	(
		[Parameter(Mandatory =$true, Position = 1)]
		[System.String]$group_id,
		[Parameter(Mandatory = $true, Position = 2)]
		$id
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/settings/$group_id/$id"
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}
#endregion Settings

#region PaymentGateways
function Get-WooCommercePaymentGateway {
	param
	(
		[Parameter(Position = 1)]
		[System.String]$id
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/payment_gateways"
		if ($id) {
			$url += "/$id"
		}
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}
#endregion PaymentGateways

#region Data
function Get-WooCommerceData {
	param
	(
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/data"
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}
#endregion Data

#region ShippingMethods
function Get-WooCommerceShippingMethod {
	param
	(
		[Parameter(Position = 1)]
		[System.String]$id
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/shipping_methods"
		if ($id) {
			$url += "/$id"
		}
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}
#endregion ShippingMethods

#region ShippingZones
function Get-WooCommerceShippingZone {
	param
	(
		[Parameter(Position = 1)]
		[System.String]$id
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/shipping/zones"
		if ($id) {
			$url += "/$id"
		}
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}
#endregion ShippingZones
function Get-WooCommerceShippingZone {
	param
	(
		[Parameter(Position = 1)]
		[System.String]$id
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/shipping/zones"
		if ($id) {
			$url += "/$id"
		}
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}
#region ShippingZoneLocations
function Get-WooCommerceShippingZoneLocation {
	param
	(
		[Parameter(Mandatory = $true, Position = 1)]
		[System.String]$id
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/shipping/zones/$id/locations"
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}
#endregion ShippingZoneLocations

#region ShippingZoneMethods
function Get-WooCommerceShippingZoneMethod {
	param
	(
		[Parameter(Mandatory = $true, Position = 1)]
		[System.String]$id
	)
	
	if (Get-WooCommerceCredential) {
		$url = "/shipping/zones/$id/methods"
		$result = Invoke-WooCommerceAPICall -RelativeUrl $url -Method "GET"
		return $result
	}
	else {
		return $null
	}
}
#endregion ShippingZoneMethods

Export-ModuleMember -Function Get-WooCommerceCategory,
Get-WooCommerceCustomer,
Get-WooCommerceData,
Get-WooCommerceOrder,
Get-WooCommerceOrderNote,
Get-WooCommercePaymentGateway,
Get-WooCommerceProduct,
Get-WooCommerceProductReview,
Get-WooCommerceProductTag,
Get-WooCommerceProductVariation,
Get-WooCommerceRefund,
Get-WooCommerceSetting,
Get-WooCommerceSettingOption,
Get-WooCommerceShippingMethod,
Get-WooCommerceShippingZone,
Get-WooCommerceShippingZoneLocation,
Get-WooCommerceShippingZoneMethod,
Get-WooCommerceWebhook,
Invoke-WooCommerceAPICall,
New-WooCommerceProduct,
Remove-WooCommerceCustomer,
Remove-WooCommerceOrderNote,
Remove-WooCommerceProductReview,
Remove-WooCommerceProduct,
Set-WooCommerceCredential,
Set-WooCommerceProduct