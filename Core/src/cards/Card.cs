using Outburst.Core.Battles;

namespace Outburst.Core.Cards;

/// <summary>
/// An individual instance of a Card.
/// </summary>
public struct Card(CardData cardData)
{
    public CardData Data { get; } = cardData;

    /// <summary>
    /// Unique identifier for this individual card instance.
    /// </summary>
    public Guid CardId { get; } = Guid.NewGuid();

    public bool MeetsRequirements(BattleState battleState)
    {
        return Data.Requirements.All(requirement => requirement.MeetsRequirements(battleState));
    }

    internal bool Play(BattleState battleState)
    {
        if (!MeetsRequirements(battleState)) return false;
        foreach (var requirement in Data.Requirements) requirement.TakeRequirements(battleState);
        foreach (var effect in Data.Effects) effect.ApplyEffect(battleState);
        return true;
    }
}
