// Tool by NotAKid, please dont eat my footsies

TOOL.Category		= "NotAKid"
TOOL.Name			= "Stunt Track Tool"

TOOL.ClientConVar[ "selected_track" ] = "gmod_stunt_tube_corner90"
TOOL.ClientConVar[ "selected_color" ] = "White"
TOOL.ClientConVar[ "rotation" ] = 0

TOOL.Information = {							
	{ name = "left" }, 
	{ name = "right" }, 
	{ name = "reload" } 
}

-- Language stuff
if CLIENT then
	language.Add("tool.stunt_track_tool.name", "Stunt Track Placer")
	language.Add("tool.stunt_track_tool.desc", "Hold DUCK to disable snapping!")
	language.Add("tool.stunt_track_tool.help", "Use nak_rebuild_spawnicons in console to generate spawnicons!")

	language.Add("tool.stunt_track_tool.left", "Place")
	language.Add("tool.stunt_track_tool.right", "Delete")
	language.Add("tool.stunt_track_tool.reload", "Copy - not added")
end	


local CurEntity = nil

function TOOL:LeftClick( trace )
	if SERVER then
		--define the suspected parent track, hitpos, player, and fetch clientinfo
		local ParentTrack = trace.Entity
		local HitPos = trace.HitPos
		local Ply = self:GetOwner()
		local selectedtrack = self:GetClientInfo( "selected_track")
		local selectedcolor = self:GetClientInfo( "selected_color")
		local Roll = self:GetClientInfo( "rotation")
 
		-- create the track and continue if it exists
		local Track = ents.Create( selectedtrack )
		if !IsValid(Track) then return end
		
		-- align the track with the parent track, or just to the players eyes
		if ParentTrack.StuntTrack and !Ply:KeyDown( 4 ) then
			Track:AlignToTrack(ParentTrack, HitPos, -Roll)
			Track:Spawn()
			Track:Activate()
		else
			local pos = trace.HitPos + (Track.SpawnOffset or Vector(0,0,0))
			local ang = Ply:EyeAngles()
			local offset = Track.SpawnOffset and Track.SpawnOffset or 480
			ang.pitch = 0
			ang.roll = -Roll
			ang.yaw = ang.yaw + 180 + (Track.SpawnAngleOffset and Track.SpawnAngleOffset or 0)
			Track:SetPos( pos )
			Track:SetAngles( ang )
			Track:Spawn()
			Track:Activate()
			-- local fixpos = Track:GetModelBounds()
			Track:SetPos(Track:GetPos() + offset * Track:GetUp())
		end
		
		if selectedcolor != nil then
			if ProxyColor then
				Track:SetProxyColor(list.Get("NAKStuntColors").CTable[selectedcolor])
			end
		end

		undo.Create(selectedtrack)
		 undo.AddEntity(Track)
		 undo.SetPlayer(Ply)
		undo.Finish()
	end
	return true	
end

function TOOL:Holster()
	if SERVER then
		if IsValid(CurEntity) then
			CurEntity = nil
		end
	end
end

function TOOL:RightClick( trace )
	if SERVER then
		local ParentTrack = trace.Entity
		if ParentTrack.StuntTrack then
			ParentTrack:Remove()
		end
	end
	return true
end

function TOOL:Reload( trace )
	return true
end

function TOOL:Think()
end

local ConVarsDefault = TOOL:BuildConVarList()
function TOOL.BuildCPanel( CPanel, track )

	CPanel:AddControl( "Header", { Description = "#tool.stunt_track_tool.desc" } )
	-- CPanel:AddControl( "Header", { Description = "#tool.stunt_track_tool.help" } )
	-- CPanel:AddControl( "ComboBox", { MenuButton = 1, Folder = "gtav_stunt_track", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )	

	-- Preview category, made so preview can be hidden
	local PrevMenu = vgui.Create("DCollapsibleCategory")
	PrevMenu:SetLabel("Preview")
	CPanel:AddItem(PrevMenu) -- parent to the base panel
	local PrevList = vgui.Create("DPanelList", PrevMenu)
	PrevList:SetHeight(350)
	PrevList:SetPadding(10)
	PrevList:SetSpacing(5)
	PrevList:Dock(TOP)
	PrevMenu:InvalidateLayout(true)
	PrevMenu:SetExpanded(true)


	-- the model preview panel itself
	local PreviewPanel = vgui.Create( "DModelPanel" )
	PreviewPanel:SetModel( "models/notakid/gtav/stunt_tubes/stunt_tube_crn90.mdl" )
	PreviewPanel:SetPos( 10, 10 )
	PreviewPanel:SetSize( 280, 280 )
	PreviewPanel:SetFOV( 45 )
	local ent = PreviewPanel.Entity
	ent:SetModelScale( 0.1, 0 )
	local mn, mx = ent:GetRenderBounds()
	local pos = LerpVector( 0.5, mn, mx )
	local fitcam = math.abs(pos.x*2) + math.abs(mn.y*2) -- fit entire model in camera
	PreviewPanel:SetCamPos(pos-Vector(fitcam,0,0))
	PreviewPanel:SetLookAt(pos)
	function PreviewPanel:LayoutEntity(ent)
		-- rotate the prop
		ent:SetAngles( Angle( 0, RealTime() * 10 % 360, 0 ) )
		-- move the prop to center it
		local mn, mx = ent:GetRenderBounds()
		local pos = LerpVector( 0.5, mn, mx )
		ent:SetPos( Vector(0,0,0) + (ent:GetForward() * -pos.x) )
	end
	PrevList:AddItem(PreviewPanel) -- parent the preview panel to the preview list

	-- color selection
	local DComboBox = vgui.Create( "DComboBox" )
	DComboBox:SetPos( 5, 30 )
	DComboBox:SetSize( 100, 20 )
	DComboBox:SetValue( "Set Proxy Colors" )
	-- DComboBox:ChooseOption( "", number index )
	for k,v in pairs(list.Get("NAKStuntColors").Index) do
		DComboBox:AddChoice( v )
	end
	DComboBox.OnSelect = function( self, index, value )
		local ent = PreviewPanel.Entity
		if ProxyColor then
			ent:SetProxyColor(list.Get("NAKStuntColors").CTable[value])
			GetConVar("stunt_track_tool_selected_color"):SetString(value)
		end
	end
	PrevList:AddItem(DComboBox) -- parent the preview panel to the preview list

	local DermaNumSlider = vgui.Create( "DNumSlider" )
	DermaNumSlider:SetPos( 50, 50 )
	DermaNumSlider:SetSize( 200, 15 )
	DermaNumSlider:SetText( "Rotation" )
	DermaNumSlider:SetDark( true )
	DermaNumSlider:SetMin( 0 )
	DermaNumSlider:SetMax( 359 )
	DermaNumSlider:SetDecimals( 0 )
	DermaNumSlider:SetConVar( "stunt_track_tool_rotation" )
	CPanel:AddItem(DermaNumSlider) -- parent to the base panel

	--the spawnicons of the tubes
	local List = vgui.Create( "DIconLayout" )
	List:SetSpaceY( 5 )
	List:SetSpaceX( 5 )
	for k,v in pairs(list.Get("NAKStuntTrack")) do 
		local ListItem = List:Add( "SpawnIcon" )
		ListItem:SetSize( 80, 80 )
		ListItem:SetModel( v.MDL )
		function ListItem:DoClick()
			PreviewPanel:SetModel(v.MDL)
			local ent = PreviewPanel.Entity
			ent:SetModelScale( 0.1, 0 )
			local mn, mx = ent:GetRenderBounds()
			local pos = LerpVector( 0.5, mn, mx )
			local fitcam = math.abs(pos.x*2) + math.abs(mn.y*2) -- fit entire model in camera
			PreviewPanel:SetCamPos(pos-Vector(fitcam,0,0))
			PreviewPanel:SetLookAt(pos)
			GetConVar("stunt_track_tool_selected_track"):SetString(v.Class)
			if ProxyColor then
				ent:SetProxyColor(list.Get("NAKStuntColors").CTable[DComboBox:GetSelected()])
			end
		end
	end
	CPanel:AddItem(List) -- parent to the base panel	
	
	local DermaButton = vgui.Create( "DButton" )
	DermaButton:SetText( "Generate Icons" )
	DermaButton:SetPos( 25, 50 )
	DermaButton:SetSize( 250, 30 )
	DermaButton.DoClick = function()
		RunConsoleCommand( "nak_rebuild_spawnicons", DComboBox:GetSelected() )
	end
	CPanel:AddItem(DermaButton) -- parent to the base panel	
end