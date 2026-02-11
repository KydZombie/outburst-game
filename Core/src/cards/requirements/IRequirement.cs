using Outburst.Core.Battles;

namespace Outburst.Core.Cards.Requirements;

public interface IRequirement
{
    public bool MeetsRequirements(BattleState battleState);
    internal void TakeRequirements(BattleState battleState);
}
