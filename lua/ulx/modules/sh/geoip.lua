if SERVER then
	util.AddNetworkString( "geoip_data" )
end

if CLIENT then
	net.Receive( "geoip_data",
		function( len )
			local rawdata = net.ReadString()
			local data = util.JSONToTable( rawdata )

			PrintTable( data )
		end
	)
end

function geoip_capture( ply, callback, errcallback )
	local ip = ply:IPAddress():match( "%d+%.%d+%.%d+%.%d+" ) or ""
	local query_string = "http://www.telize.com/geoip/" .. ip

	http.Fetch( query_string,
		function( json, len, headers, status )
			callback( json )
		end,
		function( err )
			errcallback( err )
		end
	)
end

function ulx.geoip( calling_ply, target_ply )
	local user_name = target_ply:Nick()
	ULib.tsay( calling_ply, "ULX GeoIP: Attempting to fetch GeoIP data for: " .. user_name )

	if not IsValid( target_ply ) then
		ULib.tsayError( calling_ply, "ULX GeoIP: Failed to fetch data: " .. user_name .. " is not a valid player (disconnected?)." )
		return
	end

	if SERVER then
		geoip_capture( target_ply,
			function( data )
				if not calling_ply:IsPlayer() then for k, v in pairs( util.JSONToTable( data ) ) do ServerLog( k..":    "..v ) end return end

				net.Start( "geoip_data" )
					net.WriteString( data )
				net.Send( calling_ply )
				ULib.tsay( calling_ply, "ULX GeoIP: Data for " .. user_name .. " has been printed to console." )

				ulx.fancyLogAdmin( calling_ply, "#A captured the GeoIP location data for #T", target_ply )
			end,
			function( err )
				local errstr = "ULX GeoIP: Failed to fetch data: " .. err
				if not calling_ply:IsPlayer() then ServerLog( errstr ) return end

				ULib.tsayError( calling_ply, errstr )
			end
		)
	end
end

local geoip = ulx.command( "Utility", "ulx geoip", ulx.geoip, "!geoip" )
geoip:addParam{ type = ULib.cmds.PlayerArg }
geoip:defaultAccess( ULib.ACCESS_SUPERADMIN )
geoip:help( "Prints geographical information about a user from their IP to console." )
