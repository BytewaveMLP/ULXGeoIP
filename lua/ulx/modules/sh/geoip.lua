local CATEGORY_NAME = "Utility"

if SERVER then
	util.AddNetworkString( "ulx_geoip_msg" )
	util.AddNetworkString( "ulx_geoip_data" )
end

if CLIENT then
	net.Receive( "ulx_geoip_msg",
		function( len )
			-- MsgN( "Received net message ulx_geoip_msg with length " .. len )

			MsgN( net.ReadString() )
		end )
	net.Receive( "ulx_geoip_data",
		function( len )
			-- MsgN( "Received net message ulx_geoip_data with length" .. len )

			data = net.ReadTable()

			for k, v in pairs( data ) do
				MsgN( string.format( "%s: %s", k, v ) )
			end
		end )
end

function ulx.geoip( calling_ply, target_ply )
	if target_ply:IsValid() then
		user_name = target_ply:Nick()

		-- Thanks to Garry, LocalPlayer():IPAddress() returns <IP>:<PORT>. All we want is <IP>.
		user_ip = target_ply:IPAddress():match("%d+%.%d+%.%d+%.%d+") or ""

		-- Thanks, http://www.telize.com/ for the wonderful REST API!
		-- (Switched from FreeGeoIP.net because of better information, considering switching back)
		query_string = "http://www.telize.com/geoip/" .. user_ip

		-- Get the JSON table containing the users' location, etc
		http.Fetch( query_string,
			function ( json, number, headers, status )
				local data = util.JSONToTable( json )

				-- Type consistency checks
				if data == nil or type( data ) ~= "table" then
					if calling_ply:IsValid() then
						calling_ply:PrintMessage( HUD_PRINTTALK, "Failed to fetch location - no or invalid data returned." )
					else
						ServerLog( "Failed to fetch location - no or invalid data returned." )
					end
					return
				end

				-- Notifications
				if calling_ply:IsValid() then
					calling_ply:PrintMessage( HUD_PRINTTALK, string.format( "Location data for %s (%s) printed to console.", user_name, user_ip ) )
					-- Note that the information displayed is what they were looking for
					if SERVER then
						net.Start( "ulx_geoip_msg" )
							net.WriteString( string.format( "Location data for %s (%s):", user_name, user_ip ) )
						net.Send( calling_ply )

						-- ServerLog( "Sent message ulx_geoip_msg to " .. calling_ply:Nick() )
					end
				else
					-- Tell console that this is in fact the information it's looking for
					ServerLog( string.format( "Location data for %s (%s):", user_name, user_ip ) )
				end

				-- Tell target_ply they've been tracked
				target_ply:PrintMessage( HUD_PRINTTALK, "An admin captured your GeoIP data." )

				if calling_ply:IsValid() then
					if SERVER then
						net.Start( "ulx_geoip_data" )
							net.WriteTable( data )
						net.Send( calling_ply )

						-- ServerLog( "Sent message ulx_geoip_data to " .. calling_ply:Nick() )
					end
				else
					for k, v in pairs( data ) do
						ServerLog( string.format( "%s: %s", k, v ) )
					end
				end
			end,
			function ( status, user_name )
				-- Display HTTP status code to calling_ply
				if calling_ply:IsValid() then
					calling_ply:PrintMessage( HUD_PRINTTALK, string.format( "Failed to fetch location - HTTP request failed with status code %s.", status ) )
				else 
					ServerLog( string.format( "Failed to fetch location - HTTP request failed with status code %s.", status ) )
				end
				return
			end )
	else
		-- Target ply validity checks
		if calling_ply:IsValid() then
			calling_ply:PrintMessage( HUD_PRINTTALK, string.format( "Failed to fetch location - %s is not a valid player (possibly disconnected?).", target_ply:Nick() ) )
		else
			ServerLog( string.format( "Failed to fetch location - %s is not a valid player (possibly disconnected?).", target_ply:Nick() ) )
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A captured the GeoIP location data for #T", target_ply )
end

local geoip = ulx.command( CATEGORY_NAME, "ulx geoip", ulx.geoip, "!geoip" )
geoip:addParam{ type=ULib.cmds.PlayerArg }
geoip:defaultAccess( ULib.ACCESS_SUPERADMIN )
geoip:help( "Prints geographical information about a user from their IP to console." )
