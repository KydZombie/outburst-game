using Outburst.Core.Battles;

namespace Outburst.Core.Cards.Effects;

public readonly record struct GainEnergyEffect(uint Amount) : IEffect
{
    public void ApplyEffect(BattleState battleState)
    {
        battleState.Energy += Amount;
    }
}
