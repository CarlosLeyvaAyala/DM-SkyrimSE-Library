Scriptname DM_Spell_ModAV extends ActiveMagicEffect 
{Usually used to modify an actor value which we don't want to show colored}

string Property AV Auto
{https://www.creationkit.com/index.php?title=Actor_Value_List}
int Property Sign = 1 Auto
{1 or -1. Is the magnitude positive or negative?}

Event OnEffectStart(Actor akTarget, Actor akCaster)
    akTarget.ModAV(AV, GetMagnitude() * Sign)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    akTarget.ModAV(AV, GetMagnitude() * -Sign)
EndEvent