local CATEGORY_NAME = "Utility"

if SERVER then
	util.AddNetworkString( "ulx_geoip_data" )
end

if CLIENT then
	net.Receive( "ulx_geoip_data",
		function( len )
			local rawdata = net.ReadString()
			local data = util.JSONToTable( rawdata )

			PrintTable( data )
		end )
end

function ulx.geoip( calling_ply, target_ply )
	if IsValid(target_ply) then
		local user_name = target_ply:Nick()

		-- Thanks to Garry, LocalPlayer():IPAddress() returns <IP>:<PORT>. All we want is <IP>.
		local user_ip = target_ply:IPAddress():match("%d+%.%d+%.%d+%.%d+") or ""

		-- Thanks, http://www.telize.com/ for the wonderful REST API!
		-- (Switched from FreeGeoIP.net because of better information, considering switching back)
		local query_string = "http://www.telize.com/geoip/" .. user_ip

		-- Get the JSON table containing the users' location, etc
		http.Fetch( query_string,
			function ( json, number, headers, status )
				local rawdata = json
				local data = util.JSONToTable( rawdata )

				-- Type consistency checks
				if not data or type( data ) ~= "table" then
					if IsValid( calling_ply ) then
						calling_ply:ChatPrint( "Failed to fetch location - no or invalid data returned." )
					else
						ServerLog( "Failed to fetch location - no or invalid data returned." )
					end
					return
				end

				-- Notifications
				if IsValid( calling_ply ) then
					calling_ply:ChatPrint( string.format( "Location data for %s (%s) printed to console.", user_name, user_ip ) )
					-- Note that the information displayed is what they were looking for
					if SERVER then
						calling_ply:PrintMessage( HUD_PRINTCONSOLE, string.format( "Location data for %s (%s):", user_name, user_ip ) )

						-- ServerLog( "Sent message ulx_geoip_msg to " .. calling_ply:Nick() )
					end
				else
					-- Tell console that this is in fact the information it's looking for
					ServerLog( string.format( "Location data for %s (%s):", user_name, user_ip ) )
				end

				-- Tell target_ply they've been tracked
				target_ply:ChatPrint( "An admin captured your GeoIP data." )

				if IsValid( calling_ply ) then
					if SERVER then
						net.Start( "ulx_geoip_data" )
							net.WriteString( rawdata )
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
				if IsValid( calling_ply ) then
					calling_ply:ChatPrint( string.format( "Failed to fetch location - HTTP request failed with status code %s.", status ) )
				else 
					ServerLog( string.format( "Failed to fetch location - HTTP request failed with status code %s.", status ) )
				end
				return
			end )
	else
		-- Target ply validity checks
		if IsValid( calling_ply ) then
			calling_ply:ChatPrint( string.format( "Failed to fetch location - %s is not a valid player (possibly disconnected?).", user_name ) )
		else
			ServerLog( string.format( "Failed to fetch location - %s is not a valid player (possibly disconnected?).", user_name ) )
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A captured the GeoIP location data for #T", target_ply )
end

local geoip = ulx.command( CATEGORY_NAME, "ulx geoip", ulx.geoip, "!geoip" )
geoip:addParam{ type=ULib.cmds.PlayerArg }
geoip:defaultAccess( ULib.ACCESS_SUPERADMIN )
geoip:help( "Prints geographical information about a user from their IP to console." )
