using Outburst.Core.Battles;
using Outburst.Core.Cards.Effects;

namespace Outburst.Terminal;

public readonly record struct PrintEffect(string Message) : IEffect
{
    public void ApplyEffect(BattleState battleState)
    {
        Console.WriteLine($"{Message}");
    }
}
