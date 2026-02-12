using Outburst.Core.Battles;

namespace Outburst.Core.Cards.Effects;

public interface IEffect
{
    public void ApplyEffect(BattleState battleState);
}
