using Outburst.Core.Battles;

namespace Outburst.Core.Cards.Effects;

public readonly record struct DamageEnemyEffect(uint Amount) : IEffect
{
    public void ApplyEffect(BattleState battleState)
    {
        battleState.Enemy.Damage(Amount);
    }
}
