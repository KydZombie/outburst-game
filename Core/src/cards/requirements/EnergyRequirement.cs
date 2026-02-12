using Outburst.Core.Battles;

namespace Outburst.Core.Cards.Requirements;

public readonly record struct EnergyRequirement(uint Amount) : IRequirement
{
    public bool MeetsRequirements(BattleState battleState)
    {
        return battleState.Energy >= Amount;
    }

    public void TakeRequirements(BattleState battleState)
    {
        battleState.Energy -= Amount;
    }
}
