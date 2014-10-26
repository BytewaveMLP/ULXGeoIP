local CATEGORY_NAME = "Utility"

function ulx.geoip( calling_ply, target_ply )
	if target_ply:IsValid() then
		-- This is so bad... Thanks, Cobalt.
		user_name = target_ply:Nick()
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
				)
			)

		query_string = "http://freegeoip.net/json/" .. user_ip

		-- Get the JSON table containing the users' location, etc
		http.Fetch( query_string, function ( json, number, headers, status )
				local data = util.JSONToTable( json )

				if data == nil or type( data ) ~= "table" then
					if calling_ply:IsValid() then
						calling_ply:PrintMessage( HUD_PRINTTALK, "Failed to fetch location - no or invalid data returned." )
					else
						ServerLog( "Failed to fetch location - no or invalid data returned." )
					end
					return
				end

				if calling_ply:IsValid() then
					calling_ply:PrintMessage( HUD_PRINTTALK, string.format( "Location data for %s (IP: %s) printed to console.", user_name, user_ip ) )
					target_ply:PrintMessage( HUD_PRINTTALK, "An admin captured your GeoIP data." )
				else
					ServerLog( string.format( "Location data for %s (IP: %s) printed to console.", user_name, user_ip ) )
				end

				for k, v in pairs( data ) do
					if k == "ip" then
						user_ip_r = v
					end
					if calling_ply:IsValid() then
						calling_ply:SendLua( [[MsgN( string.format( "%s: %s", "]] .. k .. [[", "]] .. v .. [[" ) )]])
					else
						ServerLog( string.format( "%s: %s", k, v ) )
					end
				end

				
			end,
			function ( status, user_name )
				if calling_ply:IsValid() then
					calling_ply:PrintMessage( HUD_PRINTTALK, string.format( "Failed to fetch location - HTTP request failed with status code %s.", status ) )
				else 
					ServerLog( string.format( "Failed to fetch location - HTTP request failed with status code %s.", status ) )
				end
				return
			end )
	else
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