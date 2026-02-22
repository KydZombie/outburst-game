using Outburst.Core.Battles;
using Outburst.Core.Cards.Effects;
using Outburst.Core.Emotions;

namespace Outburst.Core.Emotions.Effects;

public readonly record struct RemoveEmotionEffect(Emotion Emotion, uint Amount) : IEffect
{
    public void ApplyEffect(BattleState battleState)
    {
        var target = battleState.GetTargetCharacter();
        target?.RemoveEmotion(Emotion, Amount);
    }
}
