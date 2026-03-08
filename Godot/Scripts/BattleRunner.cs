using System;
using System.Collections.Generic;
using Godot;
using Outburst.Core.Battles;
using Outburst.Core.Cards;
using Outburst.Core.Cards.Requirements;
using Outburst.Core.Characters;

namespace Outburst.Godot;

/// <summary>
/// Creates BattleState with the same characters and deck shape as Terminal, draws initial hand.
/// Attach to the Battle scene root. Does not modify Core or any existing Godot scenes/scripts.
/// </summary>
public partial class BattleRunner : Node2D
{
    private BattleState? _state;

    /// <summary>Current battle state. Null until <see cref="StartBattle"/> is called.</summary>
    public BattleState? State => _state;

    /// <summary>Current energy. For GDScript energy UI.</summary>
    public int GetEnergy()
    {
        return (int)(_state?.Energy ?? 0);
    }

    /// <summary>Number of cards in hand. For GDScript hand sync.</summary>
    public int GetHandCount()
    {
        return _state?.Hand.Count ?? 0;
    }

    /// <summary>CardId of the card at index (as string for GDScript). Returns empty string if invalid.</summary>
    public string GetHandCardId(int index)
    {
        if (_state == null || index < 0 || index >= _state.Hand.Count)
            return "";
        return _state.Hand[index].CardId.ToString();
    }

    /// <summary>Display name (Identifier) of the card at index. Returns empty string if invalid.</summary>
    public string GetHandCardName(int index)
    {
        if (_state == null || index < 0 || index >= _state.Hand.Count)
            return "";
        return _state.Hand[index].Data.Identifier;
    }

    /// <summary>Energy cost of the card at hand index (from Core EnergyRequirement). Returns 0 if invalid or no energy requirement. For GDScript.</summary>
    public int GetHandCardCost(int index)
    {
        if (_state == null || index < 0 || index >= _state.Hand.Count)
            return 0;
        var data = _state.Hand[index].Data;
        foreach (var req in data.Requirements)
        {
            if (req is EnergyRequirement er)
                return (int)er.Amount;
        }
        return 0;
    }

    /// <summary>Sets the character index targeted by the next card play. For GDScript.</summary>
    public void SetTargetCharacterIndex(int index)
    {
        if (_state != null)
            _state.TargetCharacterIndex = index;
    }

    /// <summary>Plays a card by its CardId string (Guid). Returns true if played successfully. For GDScript.</summary>
    public bool PlayCardFromHandByCardId(string cardIdStr)
    {
        if (_state == null || string.IsNullOrEmpty(cardIdStr) || !Guid.TryParse(cardIdStr, out var cardId))
            return false;
        return _state.PlayCardFromHand(cardId);
    }

    /// <summary>Number of characters in battle (from Core). For GDScript.</summary>
    public int GetCharacterCount()
    {
        return _state?.Characters.Count ?? 0;
    }

    /// <summary>Name of character at index. Returns empty string if invalid. For GDScript.</summary>
    public string GetCharacterName(int index)
    {
        if (_state == null || index < 0 || index >= _state.Characters.Count)
            return "";
        return _state.Characters[index].Name;
    }

    /// <summary>Current health of character at index. Returns 0 if invalid. For GDScript.</summary>
    public int GetCharacterHealth(int index)
    {
        if (_state == null || index < 0 || index >= _state.Characters.Count)
            return 0;
        return (int)_state.Characters[index].Health;
    }

    /// <summary>Max health of character at index. Returns 0 if invalid. For GDScript.</summary>
    public int GetCharacterMaxHealth(int index)
    {
        if (_state == null || index < 0 || index >= _state.Characters.Count)
            return 0;
        return (int)_state.Characters[index].MaxHealth;
    }

    /// <summary>Draws one card from deck into hand (Core). Returns true if a card was drawn. For GDScript.</summary>
    public bool DrawOneCard()
    {
        if (_state == null)
            return false;
        return _state.DrawCard() != null;
    }

    /// <summary>Enemy name from Core. For GDScript.</summary>
    public string GetEnemyName()
    {
        return _state?.Enemy.Name ?? "";
    }

    /// <summary>Enemy current health from Core. For GDScript.</summary>
    public int GetEnemyHealth()
    {
        return (int)(_state?.Enemy.Health ?? 0);
    }

    /// <summary>Enemy max health from Core. For GDScript.</summary>
    public int GetEnemyMaxHealth()
    {
        return (int)(_state?.Enemy.MaxHealth ?? 0);
    }

    /// <summary>Runs the enemy turn (Core DoEnemyAi). Call when player ends turn. For GDScript.</summary>
    public void DoEnemyTurn()
    {
        _state?.DoEnemyAi();
    }

    public override void _Ready()
    {
        StartBattle();
    }

    /// <summary>
    /// Creates characters, enemy, and deck using Core (same as Terminal). Draws initial hand.
    /// </summary>
    public void StartBattle()
    {
        var characters = Character.CreateDefaultCharacters();
        var enemy = new Enemy("Jeff", 60, 10);
        var cards = Card.CreateDefaultDeck();
        _state = new BattleState(characters, enemy, cards);

        // Draw initial hand (4 cards)
        for (var i = 0; i < 4; i++)
            _state.DrawCard();
    }
}
