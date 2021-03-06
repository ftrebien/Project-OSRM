-- Begin of globals
require("lib/access")

barrier_whitelist = { ["cattle_grid"] = true, ["border_control"] = true, ["toll_booth"] = true, ["sally_port"] = true, ["gate"] = true, ["no"] = true, ["entrance"] = true}
access_tag_whitelist = { ["yes"] = true, ["motorcar"] = true, ["motor_vehicle"] = true, ["vehicle"] = true, ["permissive"] = true, ["designated"] = true  }
access_tag_blacklist = { ["no"] = true, ["private"] = true, ["agricultural"] = true, ["forestry"] = true, ["emergency"] = true }
access_tag_restricted = { ["destination"] = true, ["delivery"] = true }
access_tags = { "motorcar", "motor_vehicle", "vehicle" }
access_tags_hierachy = { "motorcar", "motor_vehicle", "vehicle", "access" }
service_tag_restricted = { ["parking_aisle"] = true }
ignore_in_grid = { ["ferry"] = true }
restriction_exception_tags = { "motorcar", "motor_vehicle", "vehicle" }

speed_profile = {
  ["motorway"] = 90,
  ["motorway_link"] = 75,
  ["trunk"] = 85,
  ["trunk_link"] = 70,
  ["primary"] = 65,
  ["primary_link"] = 60,
  ["secondary"] = 55,
  ["secondary_link"] = 50,
  ["tertiary"] = 40,
  ["tertiary_link"] = 30,
  ["unclassified"] = 25,
  ["residential"] = 25,
  ["living_street"] = 10,
  ["service"] = 15,
--  ["track"] = 5,
  ["ferry"] = 5,
  ["shuttle_train"] = 10,
  ["default"] = 10
}

-- [1] is safe absolute speed
-- [2] is preference level (multiplied by way speed)
tracktype_qualities = {
  ["grade1"] = { 300, 1.00 },
  ["grade2"] = {  60, 0.63 },
  ["grade3"] = {  40, 0.40 },
  ["grade4"] = {  20, 0.25 },
  ["grade5"] = {  10, 0.16 }
}

-- [1] is safe absolute speed
-- [2] is preference level (multiplied by way speed)
smoothness_qualities = {
  ["excellent"]       = { 300, 1.00 },
  ["thin_rollers"]    = { 300, 1.00 },
  ["good"]            = { 120, 0.98 },
  ["thin_wheels"]     = { 120, 0.98 },
  ["intermediate"]    = {  60, 0.96 },
  ["wheels"]          = {  60, 0.96 },
  ["bad"]             = {  15, 0.24 },
  ["robust_wheels"]   = {  15, 0.24 },
  ["very_bad"]        = {   3, 0.06 },
  ["high_clearance"]  = {   3, 0.06 }
}

-- surface materials can be seen as having expected tracktype and smoothness
-- but these are just guesses based on OSM's wiki articles
surface_tracktype_qualities = {
  ["asphalt"] = tracktype_qualities["grade1"],
  ["concrete"] = tracktype_qualities["grade1"],
  ["tartan"] = tracktype_qualities["grade1"],
  ["paved"] = tracktype_qualities["grade1"],
  ["paving_stones"] = tracktype_qualities["grade1"],
  ["concrete:plates"] = tracktype_qualities["grade1"],
  ["metal"] = tracktype_qualities["grade1"],
  ["compacted"] = tracktype_qualities["grade1"],
  ["sett"] = tracktype_qualities["grade1"],
  ["concrete:lanes"] = tracktype_qualities["grade1"],
  ["bricks"] = tracktype_qualities["grade1"],
  ["cement"] = tracktype_qualities["grade1"],
  ["cobblestone"] = tracktype_qualities["grade1"],
  ["wood"] = tracktype_qualities["grade1"],
  ["stone"] = tracktype_qualities["grade1"],
  ["rocky"] = tracktype_qualities["grade1"],
  ["grass_paver"] = tracktype_qualities["grade2"],
  ["gravel"] = tracktype_qualities["grade2"],
  ["fine_gravel"] = tracktype_qualities["grade2"],
  ["unpaved"] = tracktype_qualities["grade3"],
  ["ground"] = tracktype_qualities["grade3"],
  ["dirt"] = tracktype_qualities["grade3"],
  ["grass"] = tracktype_qualities["grade3"],
  ["pebblestone"] = tracktype_qualities["grade3"],
  ["clay"] = tracktype_qualities["grade4"],
  ["sand"] = tracktype_qualities["grade5"],
  ["earth"] = tracktype_qualities["grade5"],
  ["mud"] = tracktype_qualities["grade5"]
}

surface_smoothness_qualities = {
  ["asphalt"] = smoothness_qualities["thin_rollers"],
  ["concrete"] = smoothness_qualities["thin_rollers"],
  ["tartan"] = smoothness_qualities["thin_rollers"],
  ["paved"] = smoothness_qualities["thin_rollers"],
  ["paving_stones"] = smoothness_qualities["thin_wheels"],
  ["concrete:plates"] = smoothness_qualities["thin_wheels"],
  ["metal"] = smoothness_qualities["thin_wheels"],
  ["compacted"] = smoothness_qualities["wheels"],
  ["sett"] = smoothness_qualities["wheels"],
  ["concrete:lanes"] = smoothness_qualities["wheels"],
  ["bricks"] = smoothness_qualities["wheels"],
  ["cement"] = smoothness_qualities["wheels"],
  ["grass_paver"] = smoothness_qualities["wheels"],
  ["cobblestone"] = smoothness_qualities["robust_wheels"],
  ["wood"] = smoothness_qualities["robust_wheels"],
  ["stone"] = smoothness_qualities["robust_wheels"],
  ["rocky"] = smoothness_qualities["robust_wheels"],
  ["gravel"] = smoothness_qualities["robust_wheels"],
  ["fine_gravel"] = smoothness_qualities["robust_wheels"],
  ["unpaved"] = smoothness_qualities["robust_wheels"],
  ["ground"] = smoothness_qualities["robust_wheels"],
  ["dirt"] = smoothness_qualities["robust_wheels"],
  ["grass"] = smoothness_qualities["robust_wheels"],
  ["pebblestone"] = smoothness_qualities["robust_wheels"],
  ["clay"] = smoothness_qualities["robust_wheels"],
  ["sand"] = smoothness_qualities["robust_wheels"],
  ["earth"] = smoothness_qualities["robust_wheels"],
  ["mud"] = smoothness_qualities["high_clearance"]
}

take_minimum_of_speeds  = false
obey_oneway 			      = true
obey_bollards           =  true
use_restrictions 		    = true
ignore_areas 			      = true -- future feature
traffic_signal_penalty  = 2
u_turn_penalty 			    = 20

-- End of globals

function get_exceptions(vector)
	for i,v in ipairs(restriction_exception_tags) do
		vector:Add(v)
	end
end

local function parse_maxspeed(source)
	if source == nil then
		return 0
	end
	local n = tonumber(source:match("%d*"))
	if n == nil then
		n = 0
	end
	if string.match(source, "mph") or string.match(source, "mp/h") then
		n = (n*1609)/1000;
	end
	return math.abs(n)
end

function node_function (node)
  local barrier = node.tags:Find("barrier")
  local access = Access.find_access_tag(node, access_tags_hierachy)
  local traffic_signal = node.tags:Find("highway")

  --flag node if it carries a traffic light

  if traffic_signal == "traffic_signals" then
    node.traffic_light = true;
  end

	-- parse access and barrier tags
	if access  and access ~= "" then
		if access_tag_blacklist[access] then
			node.bollard = true
		end
	elseif barrier and barrier ~= "" then
		if barrier_whitelist[barrier] then
			return
		else
			node.bollard = true
		end
	end
end


function way_function (way)
  -- we dont route over areas
  local area = way.tags:Find("area")
  if ignore_areas and ("yes" == area) then
    return
  end

  -- check if oneway tag is unsupported
  local oneway = way.tags:Find("oneway")
  if "reversible" == oneway then
    return
  end

  local impassable = way.tags:Find("impassable")
  if "yes" == impassable then
    return
  end

  local status = way.tags:Find("status")
  if "impassable" == status then
    return
  end

  -- Check if we are allowed to access the way
  local access = Access.find_access_tag(way, access_tags_hierachy)
  if access_tag_blacklist[access] then
    return
  end
  
  -- Don't route over difficult surfaces or invalid tracktype and smoothness values
  local tracktype = way.tags:Find("tracktype")
  if tracktype ~= "" then
    if tracktype_qualities[tracktype] == nil then
      return
    end
  end
  local smoothness = way.tags:Find("smoothness")
  if smoothness ~= "" then
    if smoothness_qualities[smoothness] == nil then
      return
    end
  end

  -- Second, parse the way according to these properties
  local highway = way.tags:Find("highway")
  local name = way.tags:Find("name")
  local ref = way.tags:Find("ref")
  local junction = way.tags:Find("junction")
  local route = way.tags:Find("route")
  local maxspeed = parse_maxspeed(way.tags:Find ( "maxspeed") )
  local maxspeed_forward = parse_maxspeed(way.tags:Find( "maxspeed:forward"))
  local maxspeed_backward = parse_maxspeed(way.tags:Find( "maxspeed:backward"))
  local barrier = way.tags:Find("barrier")
  local cycleway = way.tags:Find("cycleway")
  local duration  = way.tags:Find("duration")
  local service  = way.tags:Find("service")
  local surface = way.tags:Find("surface")

  -- Set the name that will be used for instructions
	if "" ~= ref then
	  way.name = ref
	elseif "" ~= name then
	  way.name = name
--	else
--      way.name = highway		-- if no name exists, use way type
	end

	if "roundabout" == junction then
	  way.roundabout = true;
	end

  -- Handling ferries and piers
  if (speed_profile[route] ~= nil and speed_profile[route] > 0) then
    if durationIsValid(duration) then
      way.duration = math.max( parseDuration(duration), 1 );
    end
    way.direction = Way.bidirectional
    if speed_profile[route] ~= nil then
      highway = route;
    end
    if tonumber(way.duration) < 0 then
      way.speed = speed_profile[highway]
    end
  end

  -- Set the avg speed on the way if it is accessible by road class
  if (speed_profile[highway] ~= nil and way.speed == -1 ) then
    if maxspeed > speed_profile[highway] then
      way.speed = maxspeed
    else
      if 0 == maxspeed then
        maxspeed = math.huge
      end
      way.speed = math.min(speed_profile[highway], maxspeed)
    end
  end

  -- Set the avg speed on ways that are marked accessible
  if "" ~= highway and access_tag_whitelist[access] and way.speed == -1 then
    if 0 == maxspeed then
      maxspeed = math.huge
    end
    way.speed = math.min(speed_profile["default"], maxspeed)
  end
  
  -- Calculate safe speed and preference factor
  local preference_factor = 1;
  local safe_speed = 300;
  
  if tracktype ~= "" then
    safe_speed = tracktype_qualities[tracktype][1]
    preference_factor = tracktype_qualities[tracktype][2]
  else
    if surface_tracktype_qualities[surface] ~= nil then
      safe_speed = surface_tracktype_qualities[surface][1]
      preference_factor = surface_tracktype_qualities[surface][2]
    end
  end
  if smoothness ~= "" then
    safe_speed = math.min(safe_speed, smoothness_qualities[smoothness][1])
    preference_factor = math.min(preference_factor, smoothness_qualities[smoothness][2])
  else
    if surface_smoothness_qualities[surface] ~= nil then
      safe_speed = math.min(safe_speed, surface_smoothness_qualities[surface][1])
      preference_factor = math.min(preference_factor, surface_smoothness_qualities[surface][2])
    end
  end
  
  -- Use explicit forward/backward maxspeed when given and apply safe speed and preference factor to both directions
  way.speed = math.min(safe_speed, way.speed * preference_factor)
  if way.speed > 0 and maxspeed_forward ~= nil and maxspeed_forward > 0 then
    if Way.bidirectional == way.direction then
      way.backward_speed = way.speed
    end
    way.speed = math.min(safe_speed, maxspeed_forward * preference_factor)
  end
  if maxspeed_backward ~= nil and maxspeed_backward > 0 then
    way.backward_speed = math.min(safe_speed, maxspeed_backward * preference_factor)
  end
  
  -- Set access restriction flag if access is allowed under certain restrictions only
  if access ~= "" and access_tag_restricted[access] then
    way.is_access_restricted = true
  end

  -- Set access restriction flag if service is allowed under certain restrictions only
  if service ~= "" and service_tag_restricted[service] then
	  way.is_access_restricted = true
  end

  -- Set direction according to tags on way
  way.direction = Way.bidirectional
  if obey_oneway  then
	  if oneway == "-1" then
	    way.direction = Way.opposite
    elseif oneway == "yes" or
      oneway == "1" or
      oneway == "true" or
      junction == "roundabout" or
      (highway == "motorway_link" and oneway ~="no") or
      (highway == "motorway" and oneway ~= "no")
      then
	     way.direction = Way.oneway
    end
  end  

  -- Override general direction settings of there is a specific one for our mode of travel
  if ignore_in_grid[highway] ~= nil and ignore_in_grid[highway] then
		way.ignore_in_grid = true
	end
	way.type = 1
  return
end

-- These are wrappers to parse vectors of nodes and ways and thus to speed up any tracing JIT

function node_vector_function(vector)
 for v in vector.nodes do
  node_function(v)
 end
end
