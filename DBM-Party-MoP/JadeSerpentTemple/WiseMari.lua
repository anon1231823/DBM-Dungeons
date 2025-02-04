local mod	= DBM:NewMod(672, "DBM-Party-MoP", 1, 313)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,challenge,timewalker"

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(56448)
mod:SetEncounterID(1418)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20230410000000)
mod:SetMinSyncRevision(20230410000000)
mod.sendMainBossGUID = true

mod:RegisterCombat("combat")

--mod:RegisterEventsInCombat(

--)

--Hybrid mod that works for both Season 1 Dragonflight version and original version you seen in timewalking
--[[
ability.id = 397783 and type = "begincast"
 or ability.id = 397797 and type = "applydebuff"
 or type = "dungeonencounterstart" or type = "dungeonencounterend"
--]]
local warnCorruptedVortex			= mod:NewTargetAnnounce(397797, 3)
local warnCorruptedGeyser			= mod:NewCountAnnounce(397793, 3)
local warnBubbleBurst				= mod:NewCastAnnounce(106612, 3)
local warnAddsLeft					= mod:NewAddsLeftAnnounce(-5616, 2, 106526)

local specWarnLivingWater			= mod:NewSpecialWarningSwitch(-5616, "-Healer", nil, nil, 1, 2)
local specWarnWashAway				= mod:NewSpecialWarningDodge(397783, nil, nil, nil, 2, 2)
local specWarnCorruptedVortex		= mod:NewSpecialWarningMoveAway(397797, nil, nil, nil, 1, 2)
local yellCorruptedVortex			= mod:NewYell(397797)
local yellCorruptedVortexFades		= mod:NewShortFadesYell(397797)
local specWarnHydrolance			= mod:NewSpecialWarningInterrupt(397801, "HasInterrupt", nil, nil, 1, 2)
local specWarnGTFO					= mod:NewSpecialWarningGTFO(397799, nil, nil, nil, 1, 8)

local timerWashAwayCD				= mod:NewCDTimer(41.3, 397783, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)--41-44
local timerCorruptedVortexCD		= mod:NewCDTimer(13, 397797, nil, nil, nil, 3, nil, DBM_COMMON_L.HEALER_ICON)
local timerCorruptedGeyserCD		= mod:NewCDCountTimer("d5", 397793, nil, nil, nil, 3)
local timerLivingWater				= mod:NewCastTimer(5.5, 106526, nil, nil, nil, 1)

--mod:AddSetIconOption("SetIconOnAdds", "ej5616", false, true, {8})--FIXME, where the fuck did scanner go?

mod.vb.addsRemaining = 4--Also 4 on heroic?
mod.vb.firstAdd = false
local addsName = DBM:EJ_GetSectionInfo(5616)

function mod:OnCombatStart(delay)
	if self:IsMythicPlus() then
		timerCorruptedVortexCD:Start(8.5-delay)
		timerWashAwayCD:Start(20.6-delay)
		self:RegisterShortTermEvents(
			"SPELL_CAST_START 397783 397801",
			"SPELL_AURA_APPLIED 397797 397799",
			"SPELL_AURA_REMOVED 397797"
		)
	else
		self.vb.addsRemaining = 4
		self.vb.firstAdd = false
		timerLivingWater:Start(13-delay)
		self:RegisterShortTermEvents(
			"SPELL_AURA_APPLIED 106653",
			"SPELL_CAST_START 106526 106612",
			"SPELL_DAMAGE 115167",
			"SPELL_MISSED 115167",
			"UNIT_DIED"
		)
	end
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	--Retail M+ stuff
	if spellId == 397783 then
		specWarnWashAway:Show()
		specWarnWashAway:Play("watchstep")
		timerWashAwayCD:Start()
		timerCorruptedVortexCD:Restart(16)
		--"<432.19 20:50:33> [CLEU] SPELL_CAST_START#Creature-0-3772-960-3510-56448-000045A960#Der weise Mari(56.1%-100.0%)##nil#397783#Wegspülen#nil#nil", -- [3320]
		--"<435.47 20:50:36> [CLEU] SPELL_DAMAGE[CONDENSED]#Creature-0-3772-960-3510-56448-000045A960#Der weise Mari#2 Targets#397793#Verderbter Geysir", -- [3338]
		--"<440.60 20:50:41> [CLEU] SPELL_DAMAGE#Creature-0-3772-960-3510-56448-000045A960#Der weise Mari#Player-1401-04216D3A#Valî-Shattrath#397793#Verderbter Geysir", -- [3373]
		--"<445.52 20:50:46> [CLEU] SPELL_DAMAGE#Creature-0-3772-960-3510-56448-000045A960#Der weise Mari#Player-1401-04216D3A#Valî-Shattrath#397793#Verderbter Geysir", -- [3382]
		warnCorruptedGeyser:Schedule(3.2, 1)
		timerCorruptedGeyserCD:Start(3.2, 1)
		warnCorruptedGeyser:Schedule(8.3, 2)
		timerCorruptedGeyserCD:Start(8.3, 2)
		warnCorruptedGeyser:Schedule(13.3, 3)
		timerCorruptedGeyserCD:Start(13.3, 3)
	elseif spellId == 397801 and self:CheckInterruptFilter(args.sourceGUID, false, true) then
		specWarnHydrolance:Show(args.sourceName)
		specWarnHydrolance:Play("kickcast")
	--Classic and retail timewalking/non mythic+
	elseif args.spellId == 106526 then--Call Water
		if not self.vb.firstAdd then
			self.vb.firstAdd = true
		else
			timerLivingWater:Start()
		end
		specWarnLivingWater:Schedule(5.5)
		specWarnLivingWater:ScheduleVoice(5.5, "killmob")
	elseif args.spellId == 106612 then--Bubble Burst (phase 2)
		warnBubbleBurst:Show()
		timerWashAwayCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 397797 then
		if self:AntiSpam(5, 1) then
			timerCorruptedVortexCD:Start()
		end
		if args:IsPlayer() then
			specWarnCorruptedVortex:Show()
			specWarnCorruptedVortex:Play("runout")
			yellCorruptedVortex:Yell()
			yellCorruptedVortexFades:Countdown(spellId)
		end
	elseif (spellId == 106653 or spellId == 397799) and args:IsPlayer() and self:AntiSpam(3, 2) then
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 397797 then
		if args:IsPlayer() then
			yellCorruptedVortexFades:Cancel()
		end
	end
end

function mod:SPELL_DAMAGE(_, _, _, _, destGUID, _, _, _, spellId, spellName)
	if spellId == 115167 and destGUID == UnitGUID("player") and self:AntiSpam(3, 2) then
		specWarnGTFO:Show(spellName)
		specWarnGTFO:Play("watchfeet")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 56511 then--Corrupt Living Water
		self.vb.addsRemaining = self.vb.addsRemaining - 1
		warnAddsLeft:Show(self.vb.addsRemaining)
	end
end
