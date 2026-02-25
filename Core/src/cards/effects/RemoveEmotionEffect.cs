using Outburst.Core.Battles;
using Outburst.Core.Emotions;

namespace Outburst.Core.Cards.Effects;

public readonly record struct RemoveEmotionEffect(Emotion Emotion, uint Amount) : IEffect
{
    public void ApplyEffect(BattleState battleState)
    {
        var target = battleState.GetTargetCharacter();
        target?.RemoveEmotion(Emotion, Amount);
    }
}
