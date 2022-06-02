if not shared.SelectionLibrary then
    shared.SelectionLibrary = {
        Signals = {};
        Actions = {};
        Enabled = true;
        Target = nil;
        SelectedData = nil;
    }; 
    shared.SelectionLibrary.__index = shared.SelectionLibrary;
end

local OldPrint = print;

print = function(...)
    return OldPrint("SelectionLibrary:", ...)
end;

local SelectionLibrary = shared.SelectionLibrary

local Players = game:GetService("Players");
local ContextActionService = game:GetService("ContextActionService");
local UserInputService = game:GetService("UserInputService");

local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse()

local Character = nil;
local Camera = nil;

local InitBodyParts = {
    "HumanoidRootPart";
    "Head";
}

local PositionMap = nil;

PositionMap = {
    ["CFrame"] = function(Arg)
        return Arg.Position
    end;
    ["Vector3"] = function(Arg)
        return Arg
    end;
    ["Instance"] = function(Arg)
        for Index, Value in pairs(PositionMap.__InstanceMap) do
            if Arg:IsA(Index) then
                return Value(Arg);
            end
        end
    end;
    __InstanceMap = {
        ["PVInstance"] = function(Arg)
            return Arg:GetPivot().Position;
        end;
        ["Player"] = function(Arg) 
            local Character = Arg.Character or Arg.CharacterAdded:Wait();
            
            if Character then
                return Character:GetPivot().Position;
            end
        end
    };
}

local function ConvertToPosition(Arg1)
    return PositionMap[typeof(Arg1)](Arg1);
end

local function FlushSignals()
    if SelectionLibrary.Signals then
        for Index, Signals in pairs(SelectionLibrary.Signals) do
            Signals:Disconnect()
        end
    end
end

local function FlushActions()
    if SelectionLibrary.Actions then
        for Index, Value in pairs(SelectionLibrary.Actions) do
            ContextActionService:UnbindAction(Value);
        end
    end
end

FlushSignals(); FlushActions();

local function AddSignal(Signal)
    return table.insert(SelectionLibrary.Signals, Signal);
end

local function AddAction(Name, KeyCode, Function)
    ContextActionService:BindActionAtPriority(Name, Function, false, -100000,KeyCode)
    
    return table.insert(SelectionLibrary.Actions, Name);
end

local function InitializeVariables()
    local MainFuncEnv = getfenv(2);
    
    Camera = workspace.Camera;
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
    
    for Index, Value in pairs(InitBodyParts) do
        local ObjectThatExists = Character:WaitForChild(Value);
        
        if ObjectThatExists then
            MainFuncEnv[Value] = ObjectThatExists;
        end
    end
    
    return MainFuncEnv
end

InitializeVariables()

AddSignal(LocalPlayer.CharacterAdded:Connect(function()
    InitializeVariables();
    print("Respawned")
end))

AddSignal(Camera.Destroying:Connect(function()
    Camera = workspace.CurrentCamera;
end))

local function GetHighlight()
    local Highlight = SelectionLibrary.Highlight
    
    if not Highlight then
        Highlight = Instance.new("Highlight");
        Highlight.Parent = LocalPlayer;
        
        SelectionLibrary.Highlight = Highlight;
    end
    
    return Highlight
end

local function Raycast(StartPosition, EndPosition, RaycastParams)
    StartPosition = ConvertToPosition(StartPosition);
    EndPosition = ConvertToPosition(EndPosition);
    
    local Expression = (StartPosition - EndPosition);
    
    if StartPosition and EndPosition and RaycastParams then
        local ReturnValue = workspace:Raycast(StartPosition, Expression.Unit * Expression.Magnitude, RaycastParams)
        
        return ReturnValue
    end
end

local function RaycastFromVector2(Vector, Distance, RaycastParams)
    local UnitRay = Camera:ScreenPointToRay(Vector.X, Vector.Y)
    
    return workspace:Raycast(UnitRay.Origin, UnitRay.Direction * Distance, RaycastParams) 
end

local function FindPlayer(Starting, Levels)
    local CurrentInstance = Starting;
    
    for i = 1, Levels do
        CurrentInstance = CurrentInstance["Parent"];
        
        if CurrentInstance then
            local Player = Players:GetPlayerFromCharacter(CurrentInstance) 
            
            if Player then
                return Player
            end
        end
    end
end

function SelectionLibrary.Init()
    local self = {
        Handlers = {};
        IgnoreList = {};
        Distance = 500;
    };
    
    if SelectionLibrary.Enabled then
        AddAction("OnMouseMove", Enum.UserInputType.MouseMovement, function()
            local Highlight = GetHighlight()
            local RaycastParams = RaycastParams.new() do
                RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist;
                RaycastParams.FilterDescendantsInstances = self.IgnoreList;
                RaycastParams.IgnoreWater = true;
            end
        
            local RaycastResult = RaycastFromVector2(UserInputService:GetMouseLocation(), self.Distance, RaycastParams);
            
            if RaycastResult then
                local Hit = RaycastResult["Instance"];
                
                if Hit then
                    local Found = nil;
                    local SelectedData = nil;
                    
                    for Index, Value in pairs(self.Handlers) do
                        local Parsed = Value.Handler(Hit)
                        
                        if Parsed then
                            Found = Parsed
                            SelectionLibrary.SelectedData = Value;
                            SelectionLibrary.Target = Parsed;
                            
                            break
                        end
                    end
                    
                    if Found then
                        for Index, Property in pairs(SelectionLibrary.SelectedData.Properties) do
                            Highlight[Index] = Property; 
                        end
                        
                        Highlight.Parent = Found
                        Highlight.Adornee = Found;
                        Highlight.Enabled = true;
                        
                    elseif not Found then
                        Highlight.Parent = LocalPlayer
                        Highlight.Adornee = nil;
                    end
                elseif not Hit then
                    Highlight.Parent = LocalPlayer
                    Highlight.Adornee = nil;
                end
            elseif not RaycastResult then
                Highlight.Parent = LocalPlayer
                Highlight.Adornee = nil;
            end
        end)
        AddAction("Activated", Enum.UserInputType.MouseButton1, function(ActionName, InputState, InputObject) 
            local SelectedData = SelectionLibrary.SelectedData
            
            if SelectedData then
                if InputState == Enum.UserInputState.Begin then
                    if SelectedData["Activated"] then
                        SelectedData["Activated"](ActionName, InputState, InputObject);
                    end
                end
            end
        end)
    end
    
    return setmetatable(self, SelectionLibrary);
end

function SelectionLibrary:AddSelectionHandler(Name, Data) 
    Data.Name = Name;
    self.Handlers[Name] = Data; 
    
    Data.Unbind = function() -- i do not need to make another fucking library just for ONE single method
       self.Handlers[Name] = nil; 
    end
    
    return Data;
end;


function SelectionLibrary:AddToIgnoreList(InstanceIgnore) table.insert(self.IgnoreList, InstanceIgnore) end;
function SelectionLibrary:RemoveFromIgnoreList(InstanceIgnore) table.remove(self.IgnoreList, table.find(self.IgnoreList, InstanceIgnore)) end;
function SelectionLibrary:SetRayDistance(Distance) Distance = Distance or 500 self.Distance = Distance; end;

return SelectionLibrary
