using Outburst.Core.Battles;
using Outburst.Core.Emotions;

namespace Outburst.Core.Cards.Requirements;

/// <summary>
/// Requires the target character to have at least the given amount of an emotion.
/// When <see cref="ConsumeOnPlay"/> is true, playing the card removes that amount from the target.
/// </summary>
public readonly record struct EmotionRequirement(Emotion Emotion, uint Amount, bool ConsumeOnPlay = true) : IRequirement
{
    public bool MeetsRequirements(BattleState battleState)
    {
        var target = battleState.GetTargetCharacter();
        if (target == null) return false;
        return target.Emotions.TryGetValue(Emotion, out var level) && level >= Amount;
    }

    public void TakeRequirements(BattleState battleState)
    {
        if (!ConsumeOnPlay) return;
        var target = battleState.GetTargetCharacter();
        target?.RemoveEmotion(Emotion, Amount);
    }
}
