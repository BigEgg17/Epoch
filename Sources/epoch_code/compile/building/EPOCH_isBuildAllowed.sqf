/*
	Author: Aaron Clark - EpochMod.com

    Contributors: Raimonds Virtoss

	Description:
	check if building is allowed

    Licence:
    Arma Public License Share Alike (APL-SA) - https://www.bistudio.com/community/licenses/arma-public-license-share-alike

    Github:
    https://github.com/EpochModTeam/Epoch/tree/release/Sources/epoch_code/compile/building/EPOCH_isBuildAllowed.sqf

    Example:
    _isAllowed = "" call EPOCH_isBuildAllowed;
	_isAllowed = _objType call EPOCH_isBuildAllowed;

    Parameter(s):
		_this select 0: OBJECT - Base building object

	Returns:
	BOOL
*/
private ["_cfgBaseBuilding","_buildingJammerRange","_buildingCountLimit","_buildingAllowed","_nearestJammer","_ownedJammerExists","_objectCount","_limitNearby","_restricted","_range","_config","_staticClass","_objType","_simulClass","_bypassJammer","_jammer","_restrictedLocations","_myPosATL"];

_buildingAllowed = true;
_ownedJammerExists = false;
_nearestJammer = objNull;

// reject building if in vehicle
if (vehicle player != player)exitWith{["Building Disallowed: Inside Vehicle", 5] call Epoch_message; false };

// defaults
_config = 'CfgEpochClient' call EPOCH_returnConfig;
_cfgBaseBuilding = 'CfgBaseBuilding' call EPOCH_returnConfig;
_buildingJammerRange = getNumber(_config >> "buildingJammerRange");
_buildingCountLimit = getNumber(_config >> "buildingCountLimit");
if (_buildingJammerRange == 0) then { _buildingJammerRange = 75; };
if (_buildingCountLimit == 0) then { _buildingCountLimit = 200; };

// input
params ["_objType"];
_obj = objNull;
if (_objType isEqualType objNull) then {
	_obj = _objType;
	_objType = typeOf _objType;
};

_staticClass = getText(_cfgBaseBuilding >> _objType >> "staticClass");
_simulClass = getText(_cfgBaseBuilding >> _objType >> "simulClass");
_bypassJammer = getNumber(_cfgBaseBuilding >> _staticClass >> "bypassJammer");

// Jammer
_jammer = nearestObjects[player, ["PlotPole_EPOCH"], _buildingJammerRange*3];
if !(_jammer isEqualTo []) then {
	if (_objType in ["PlotPole_EPOCH", "PlotPole_SIM_EPOCH"]) then {
		{
			if (alive _x) exitWith{
				_buildingAllowed = false;
				["Building Disallowed: Existing Jammer Signal", 5] call Epoch_message;
			};
		} foreach _jammer;
	} else {

		{
			if (alive _x && (_x distance player) <= _buildingJammerRange) exitWith{
				_nearestJammer = _x;
			};
		} foreach _jammer;

		if !(isNull _nearestJammer) then {
			if ((_nearestJammer getVariable["BUILD_OWNER", "-1"]) in[getPlayerUID player, Epoch_my_GroupUID]) then {
				_ownedJammerExists = true;
			} else {
				_buildingAllowed = false;
				["Building Disallowed: Frequency Blocked", 5] call Epoch_message;
			};
			_objectCount = count nearestObjects[_nearestJammer, ["Constructions_static_F"], _buildingJammerRange];
			if (_objectCount >= _buildingCountLimit) then {
				_buildingAllowed = false;
				["Building Disallowed: Frequency Overloaded", 5] call Epoch_message;
			};
		};
	};
};
if !(_buildingAllowed)exitWith{ false };

// Max object
if (!_ownedJammerExists) then{
	_limitNearby = getNumber(_cfgBaseBuilding >> _staticClass >> "limitNearby");

	if (_limitNearby > 0) then{
		// remove current target from objects
		_objectCount = count (nearestObjects[player, [_staticClass, _simulClass], _buildingJammerRange] - [_obj]);
		// TODO: not properly limiting simulated objects
		if (_objectCount >= _limitNearby) then{
			_buildingAllowed = false;
			[format["Building Disallowed: Limit %1", _limitNearby], 5] call Epoch_message;
		};
	};
};
if !(_buildingAllowed)exitWith{ false };

// require jammer check if not found as owner of jammer
if (getNumber(_config >> "buildingRequireJammer") == 0 && _bypassJammer == 0) then{
	if !(_objType in ["PlotPole_EPOCH", "PlotPole_SIM_EPOCH"]) then {
		_buildingAllowed = _ownedJammerExists;
		if !(_buildingAllowed) then {
			["Building Disallowed: Frequency Jammer Needed", 5] call Epoch_message;
		};
	};
};
if !(_buildingAllowed)exitWith{ false };

if (getNumber(_config >> "buildingNearbyMilitary") == 0) then{
	_range = getNumber(_config >> "buildingNearbyMilitaryRange");
	if (_range > 0) then {
		_restricted = nearestObjects [player, ["ProtectionZone_Invisible_F","Cargo_Tower_base_F","Cargo_HQ_base_F","Cargo_Patrol_base_F","Cargo_House_base_F"], 300];
	} else {
		_restricted = nearestObjects [player, ["Cargo_Tower_base_F","Cargo_HQ_base_F","Cargo_Patrol_base_F","Cargo_House_base_F"], _range];
		_restricted append (nearestObjects [player, ["ProtectionZone_Invisible_F","Cargo_Tower_base_F","Cargo_HQ_base_F","Cargo_Patrol_base_F","Cargo_House_base_F"], 300]);
	};
} else {
	_restricted = nearestObjects [player, ["ProtectionZone_Invisible_F"], 300];
};
if !(_restricted isEqualTo []) then {
	_buildingAllowed = false;
	["Building Disallowed: Protected Frequency", 5] call Epoch_message;
};

_restrictedLocations = nearestLocations [player, ["NameCityCapital"], 300];
if !(_restrictedLocations isEqualTo []) then {
	_buildingAllowed = false;
	["Building Disallowed: Protected Frequency", 5] call Epoch_message;
};

_myPosATL = getPosATL player;
{
	if ((_x select 0) distance _myPosATL < (_x select 1)) exitWith {
		_buildingAllowed = false;
		["Building Disallowed: Protected Frequency", 5] call Epoch_message;
	};
} forEach(getArray(_config >> worldname >> "blockedArea"));

_buildingAllowed
