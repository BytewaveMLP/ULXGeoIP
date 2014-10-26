local CATEGORY_NAME = "Utility"

function ulx.geoip( calling_ply, target_ply )
	if target_ply:IsValid() then
		user_name = target_ply:Nick()

		-- Thanks to Garry, LocalPlayer():IPAddress() returns <IP>:<PORT>. All we want is <IP>.
		-- Code below courtesy of Cobalt.
		user_ip = tostring(
				string.sub(
					tostring(
						target_ply:IPAddress()
						),
					1,
					string.len(
						tostring(
							target_ply:IPAddress()
						)
					) - 6
				) -- /sub
			) -- /tostring

		-- Thanks, freegeoip.net for the wonderful REST API!
		query_string = "http://freegeoip.net/json/" .. user_ip

		-- Get the JSON table containing the users' location, etc
		http.Fetch( query_string, function ( json, number, headers, status )
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
					-- Tell calling_ply where the information is
					calling_ply:PrintMessage( HUD_PRINTTALK, string.format( "Location data for %s (%s) printed to console.", user_name, user_ip ) )
					-- Note that the information displayed is what they were looking for
					calling_ply:SendLua( [[MsgN( string.format( "Location data for %s (%s):", "]] .. user_name .. [[", "]] .. user_ip .. [[" ) )]])
				else
					-- Tell console that this is in fact the information it's looking for
					ServerLog( string.format( "Location data for %s (%s):", user_name, user_ip ) )
				end

				-- Tell target_ply they've been tracked
				target_ply:PrintMessage( HUD_PRINTTALK, "An admin captured your GeoIP data." )

				for k, v in pairs( data ) do
					-- Print the information
					if calling_ply:IsValid() then
						-- Client call
						calling_ply:SendLua( [[MsgN( string.format( "%s: %s", "]] .. k .. [[", "]] .. v .. [[" ) )]])
					else
						-- Server call
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

	ulx.fancyLogAdmin( calling_ply, "#A got the GeoIP location of #T", target_ply )
end
local geoip = ulx.command( CATEGORY_NAME, "ulx geoip", ulx.geoip, "!geoip" )
geoip:addParam{ type=ULib.cmds.PlayerArg }
geoip:defaultAccess( ULib.ACCESS_SUPERADMIN )
geoip:help( "Prints geographical information about a user from their IP to chat." )