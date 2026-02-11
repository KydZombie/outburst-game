using Outburst.Core.Battles;

namespace Outburst.Core.Cards;

public struct Card(CardData cardData)
{
    public CardData Data { get; } = cardData;

    // Unique identifier for this individual card instance.
    public Guid CardId { get; } = Guid.NewGuid();

    public bool MeetsRequirements(BattleState battleState)
    {
        return Data.Requirements.All(requirement => requirement.MeetsRequirements(battleState));
    }

    public bool Play(BattleState battleState)
    {
        if (!MeetsRequirements(battleState)) return false;
        foreach (var requirement in Data.Requirements) requirement.TakeRequirements(battleState);
        foreach (var effect in Data.Effects) effect.ApplyEffect(battleState);
        return true;
    }
}
