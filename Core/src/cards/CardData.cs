using Outburst.Core.Cards.Effects;
using Outburst.Core.Cards.Requirements;

namespace Outburst.Core.Cards;

/// <summary>
/// All the immutable data of a card.
/// </summary>
/// <param name="Identifier">Unlocalized name of card for data lookup (Textures, localization, etc.).</param>
public record struct CardData(
    string Identifier,
    IReadOnlyList<IRequirement> Requirements,
    IReadOnlyList<IEffect> Effects,
    bool RequiresCharacterTarget = false
);
