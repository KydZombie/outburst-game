using Outburst.Core.Battles;
using Outburst.Core.Cards.Effects;
using Outburst.Core.Emotions;

namespace Outburst.Core.Emotions.Effects;

public readonly record struct AddEmotionEffect(Emotion Emotion, uint Amount = 1) : IEffect
{
    public void ApplyEffect(BattleState battleState)
    {
        var target = battleState.GetTargetCharacter();
        target?.AddEmotion(Emotion, Amount);
    }
}
