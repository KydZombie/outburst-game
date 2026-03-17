using System;
using System.Collections.Generic;
using Godot;
using Outburst.Core.Battles;
using Outburst.Core.Cards;
using Outburst.Core.Characters;

// Alias to avoid confusion with the Outburst.Godot namespace name.
using GCollections = Godot.Collections;

namespace Outburst.Godot;

/// <summary>
/// Thin adapter that exposes the Core BattleState to Godot via
/// simple methods and Godot collections. Attach this to a node
/// in your battle scene (for example, a child of BattleScene).
/// </summary>
[GlobalClass]
public partial class GodotBattleAdapter : Node
{
    [Signal]
    public delegate void EnemyHealedEventHandler(int amount);

    private BattleState _state = null!;

    private List<Character> _characters = null!;
    private Enemy _enemy = null!;

    public override void _Ready()
    {
        // Initialize default battle exactly like the Terminal frontend.
        _characters = Character.CreateDefaultCharacters();
        var cards = Card.CreateDefaultDeck();
        _enemy = new Enemy("Jeff", 60, 10);

        _state = new BattleState(_characters, _enemy, cards);

        // Bridge Core heal actions into a Godot signal so GDScript
        // can keep its existing enemy_heal_action behavior.
        _enemy.OnAction += (_, action) =>
        {
            if (action is EnemyHealAction heal)
            {
                EmitSignal(SignalName.EnemyHealed, (int)heal.Amount);
            }
        };
    }

    /// <summary>
    /// Draws a single card and returns its identifier, or null if deck is empty.
    /// </summary>
    public string? DrawCard()
    {
        var card = _state.DrawCard();
        return card?.Data.Identifier;
    }

    /// <summary>
    /// Plays a card from hand by 0-based index. Returns true if played.
    /// If the card requires a character target, pass the target index.
    /// </summary>
    public bool PlayCardByIndex(int handIndex, int? targetCharacterIndex = null)
    {
        if (handIndex < 0 || handIndex >= _state.Hand.Count)
            return false;

        if (targetCharacterIndex is { } idx)
            _state.TargetCharacterIndex = idx;

        var card = _state.Hand[handIndex];
        return _state.PlayCardFromHand(card.CardId);
    }

    /// <summary>
    /// Runs one enemy AI step (matches BattleState.DoEnemyAi).
    /// </summary>
    public void DoEnemyTurn()
    {
        _state.DoEnemyAi();
    }

    /// <summary>
    /// Returns a snapshot of the current battle state as a Dictionary
    /// that GDScript can easily consume.
    /// </summary>
    public GCollections.Dictionary GetSnapshot()
    {
        var partyArray = new GCollections.Array<GCollections.Dictionary>();
        foreach (var c in _state.Characters)
        {
            var emotions = new GCollections.Dictionary();
            foreach (var kv in c.Emotions)
                emotions[kv.Key.ToString()] = (int)kv.Value;

            var cd = new GCollections.Dictionary
            {
                ["name"] = c.Name,
                ["hp"] = (int)c.Health,
                ["max_hp"] = (int)c.MaxHealth,
                ["emotions"] = emotions
            };
            partyArray.Add(cd);
        }

        var enemyDict = new GCollections.Dictionary
        {
            ["name"] = _enemy.Name,
            ["hp"] = (int)_enemy.Health,
            ["max_hp"] = (int)_enemy.MaxHealth,
            ["power"] = (int)_enemy.Power
        };

        var enemiesArray = new GCollections.Array<GCollections.Dictionary> { enemyDict };

        var handArray = new GCollections.Array<string>();
        foreach (var card in _state.Hand)
            handArray.Add(card.Data.Identifier);

        return new GCollections.Dictionary
        {
            ["party"] = partyArray,
            ["enemies"] = enemiesArray,
            ["energy"] = (int)_state.Energy,
            ["turn"] = 0, // Turn tracking lives in Core consumer frontends; UI can track separately if needed.
            ["hand"] = handArray,
            ["deck_size"] = _state.Deck.Count,
            ["discard_size"] = _state.DiscardPile.Count,
            ["target_character_index"] = _state.TargetCharacterIndex
        };
    }
}

