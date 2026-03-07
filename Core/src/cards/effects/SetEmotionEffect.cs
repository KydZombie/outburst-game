using Outburst.Core.Battles;
using Outburst.Core.Emotions;

namespace Outburst.Core.Cards.Effects;

public readonly record struct SetEmotionEffect(Emotion Emotion, uint Amount = 1) : IEffect
{
    public void ApplyEffect(BattleState battleState)
    {
        var target = battleState.GetTargetCharacter();
        target?.SetEmotion(Emotion, Amount);
    }
}
