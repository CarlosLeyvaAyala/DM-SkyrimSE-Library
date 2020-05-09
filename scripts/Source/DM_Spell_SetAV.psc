Scriptname DM_Spell_SetAV extends ActiveMagicEffect 
{Usually used to modify an actor value which we don't want to show colored}

string Property AV Auto
{https://www.creationkit.com/index.php?title=Actor_Value_List}
int Property Sign = 1 Auto
{1 or -1. Is the magnitude positive or negative?}

Event OnEffectStart(Actor akTarget, Actor akCaster)
    akTarget.SetActorValue(AV, Modify(akTarget))
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    akTarget.SetActorValue(AV, Restore(akTarget))
EndEvent

float Function ModifyValue(Actor akTarget, float x)
    Return akTarget.GetBaseActorValue(AV) + x
EndFunction

float Function Modify(Actor akTarget)
    Return ModifyValue(akTarget, GetMagnitude() * Sign)
EndFunction

float Function Restore(Actor akTarget)
    Return ModifyValue(akTarget, GetMagnitude() * -Sign)
EndFunction

