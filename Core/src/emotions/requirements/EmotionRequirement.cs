using Outburst.Core.Battles;
using Outburst.Core.Cards.Requirements;
using Outburst.Core.Emotions;

namespace Outburst.Core.Emotions.Requirements;

public readonly record struct EmotionRequirement(Emotion Emotion, uint Amount) : IRequirement
{
    public bool MeetsRequirements(BattleState battleState)
    {
        var target = battleState.GetTargetCharacter();
        if (target == null) return false;
        return target.Emotions.TryGetValue(Emotion, out var level) && level >= Amount;
    }

    public void TakeRequirements(BattleState battleState)
    {
        var target = battleState.GetTargetCharacter();
        target?.RemoveEmotion(Emotion, Amount);
    }
}
