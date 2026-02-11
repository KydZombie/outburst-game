using Outburst.Core.Battles;

namespace Outburst.Core.Cards.Effects;

public interface IEffect
{
    internal void ApplyEffect(BattleState battleState);
}
