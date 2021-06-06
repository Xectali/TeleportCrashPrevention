#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int g_iEntTarget;

Handle g_hCBaseEntity_GetRefEHandle = null;

public Plugin myinfo =
{
	name = "[CS:GO] Teleport Crash Prevention",
	author = "PerfectLaugh && PŠΣ™ SHUFEN",
	description = "",
	version = "",
	url = "https://possession.jp"
};

public void OnPluginStart()
{
	GameData hGameConf = new GameData("TeleportCrashPrevention.games");
	if (hGameConf == null) {
		SetFailState("Could not open TeleportCrashPrevention.games gamedata");
	}

	// CBaseHandle CBaseEntity::GetRefEHandle( void )
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseEntity::GetRefEHandle")) {
		SetFailState("PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, \"CBaseEntity::GetRefEHandle\") failed!");
	}
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hCBaseEntity_GetRefEHandle = EndPrepSDKCall();
	if (g_hCBaseEntity_GetRefEHandle == null) {
		SetFailState("Method \"CBaseEntity::GetRefEHandle\" was not loaded right.");
	}

	g_iEntTarget = hGameConf.GetOffset("CTriggerTeleport::m_pentTarget");
	if (g_iEntTarget == -1) {
		SetFailState("Could not get offset CTriggerTeleport::m_pentTarget");
	}
}

public void OnEntityDestroyed(int entity)
{
	int trigger = INVALID_ENT_REFERENCE;
	while ((trigger = FindEntityByClassname(trigger, "trigger_teleport")) != INVALID_ENT_REFERENCE) {
		Address pEntTarget = view_as<Address>(LoadFromAddress(GetEntityAddress(trigger) + view_as<Address>(g_iEntTarget), NumberType_Int32));
		if (pEntTarget == Address_Null) {
			continue;
		}

		int entTarget = CBaseEntity_GetEntIndex(pEntTarget);
		if (entTarget == entity) {
			LogMessage("Prevent teleport use-after-free crash: trigger: %d, target: %d", trigger, entTarget);
			StoreToAddress(GetEntityAddress(trigger) + view_as<Address>(g_iEntTarget), 0, NumberType_Int32);
		}
	}
}

stock Address CBaseEntity_GetRefEHandle(Address pEntity)
{
	if (pEntity == Address_Null)
		return Address_Null;

	return SDKCall(g_hCBaseEntity_GetRefEHandle, pEntity);
}

stock int CBaseEntity_GetEntIndex(Address pEntity)
{
	int ref = CBaseEntity_GetEntReference(pEntity);
	if (ref == INVALID_ENT_REFERENCE)
		return INVALID_ENT_REFERENCE;

	return EntRefToEntIndex(ref);
}

stock int CBaseEntity_GetEntReference(Address pEntity)
{
	Address addr = CBaseEntity_GetRefEHandle(pEntity);
	if (addr == Address_Null)
		return INVALID_ENT_REFERENCE;

	int EntHandle = LoadFromAddress(addr, NumberType_Int32);
	return (EntHandle | (1 << 31)) & 0xffffffff;
}
