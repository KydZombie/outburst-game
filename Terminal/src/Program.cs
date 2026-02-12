using Outburst.Core.Battles;
using Outburst.Core.Cards;
using Outburst.Core.Cards.Effects;
using Outburst.Core.Cards.Requirements;
using Outburst.Core.Characters;
using Outburst.Terminal;

List<Character> characters =
[
    new(80)
];

List<Card> cards =
[
    new(new CardData(
        "gain_energy",
        new List<IRequirement>(),
        new List<IEffect>
        {
            new GainEnergyEffect(8)
        }
    )),
    new(new CardData(
        "hello",
        new List<IRequirement>
        {
            new EnergyRequirement(2)
        },
        new List<IEffect>
        {
            new PrintEffect("Hello from card!")
        }
    ))
];

BattleState state = new(characters, cards);

var energyCard = state.DrawCard();

if (energyCard == null) throw new Exception("Drew null on a deck with two cards left.");

if (state.PlayCardFromHand(energyCard.Value.CardId))
    Console.WriteLine("Play success (gain_energy)!");
else
    throw new Exception("Failed to play card with no requirements.");

var punchCard = state.DrawCard();

if (punchCard == null) throw new Exception("Drew null on a deck with one card left.");

if (state.PlayCardFromHand(punchCard.Value.CardId))
    Console.WriteLine("Play success (hello)!");
else
    throw new Exception("Failed to play card with valid amount of energy.");
