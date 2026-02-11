using Outburst.Core.Cards;
using Outburst.Core.Characters;

namespace Outburst.Core.Battles;

/// <summary>
/// All the persistent state of a battle.
/// </summary>
/// <param name="cards">All cards that will be in the deck from the start of the battle.</param>
public class BattleState(List<Character> characters, List<Card> cards)
{
    public uint Energy { get; internal set; }

    public List<Character> Characters { get; } = characters;

    public List<Card> Deck { get; internal set; } = cards;
    public List<Card> Hand { get; internal set; } = [];
    public List<Card> DiscardPile { get; internal set; } = [];

    public Card? GetCardInHand(Guid cardId)
    {
        throw new NotImplementedException();
    }

    public Card? DrawCard()
    {
        throw new NotImplementedException();
    }

    /// <summary>
    /// Plays a card from the player's hand.
    /// Moves the card to the discard pile if it is successfully played.
    /// </summary>
    /// <returns>Whether the card was successfully played.</returns>
    public bool PlayCardFromHand(Guid cardId)
    {
        throw new NotImplementedException();
    }
}
