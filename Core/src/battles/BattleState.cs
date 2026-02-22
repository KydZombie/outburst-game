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

    /// <summary>
    /// Index of the character targeted by card effects (e.g. emotion or damage).
    /// Default 0. Set before playing a card to choose the target.
    /// </summary>
    public int TargetCharacterIndex { get; set; } = 0;

    public List<Character> Characters { get; } = characters;

    /// <summary>
    /// Gets the character at <see cref="TargetCharacterIndex"/> if the index is valid.
    /// </summary>
    public Character? GetTargetCharacter()
    {
        if (TargetCharacterIndex < 0 || TargetCharacterIndex >= Characters.Count)
            return null;
        return Characters[TargetCharacterIndex];
    }

    public List<Card> Deck { get; internal set; } = cards;
    public List<Card> Hand { get; internal set; } = [];
    public List<Card> DiscardPile { get; internal set; } = [];

    private Card? GetCardInHand(Guid cardId)
    {
        return Hand.Find(card => card.CardId == cardId);
    }

    public Card? DrawCard()
    {
        // TODO: Hand limit
        if (Deck.Count == 0) return null;

        var card = Deck[0];
        Deck.RemoveAt(0);

        Hand.Add(card);

        return card;
    }

    private bool RemoveCardFromHand(Guid cardId)
    {
        var index = Hand.FindIndex(card => card.CardId == cardId);
        if (index == -1) return false;
        Hand.RemoveAt(index);
        return true;
    }

    /// <summary>
    /// Plays a card from the player's hand.
    /// Moves the card to the discard pile if it is successfully played.
    /// </summary>
    /// <returns>Whether the card was successfully played.</returns>
    public bool PlayCardFromHand(Guid cardId)
    {
        var found = GetCardInHand(cardId);

        // ReSharper disable once InvertIf
        if (found?.Play(this) ?? false)
        {
            RemoveCardFromHand(cardId);
            return true;
        }

        return false;
    }
}
