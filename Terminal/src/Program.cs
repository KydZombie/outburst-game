using Outburst.Core.Battles;
using Outburst.Core.Cards;
using Outburst.Core.Cards.Effects;
using Outburst.Core.Cards.Requirements;
using Outburst.Core.Characters;
using Outburst.Core.Emotions;
using Outburst.Terminal;

List<Character> characters = Character.CreateDefaultCharacters();

Console.WriteLine("Characters:");
foreach (var c in characters)
    Console.WriteLine($"  {c.Name}: {c.Health}/{c.MaxHealth} health");
Console.WriteLine();

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
    )),
    new(new CardData(
        "get_angry",
        new List<IRequirement>(),
        new List<IEffect> { new AddEmotionEffect(Emotion.Angry, 2) }
    )),
    new(new CardData(
        "vent_anger",
        new List<IRequirement> { new EmotionRequirement(Emotion.Angry, 1) },
        new List<IEffect>
        {
            new PrintEffect("Vented anger!")
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

// Emotion demo: target Niko (index 0), add Angry then play vent_anger
state.TargetCharacterIndex = 0;
var getAngryCard = state.DrawCard();
if (getAngryCard != null && state.PlayCardFromHand(getAngryCard.Value.CardId))
    Console.WriteLine("Play success (get_angry)!");
var ventCard = state.DrawCard();
if (ventCard != null && state.PlayCardFromHand(ventCard.Value.CardId))
    Console.WriteLine("Play success (vent_anger)!");
else if (ventCard != null)
    Console.WriteLine("Could not play vent_anger (need 1+ Angry on target).");

Console.WriteLine();
Console.WriteLine("Characters (after emotion cards):");
foreach (var c in characters)
{
    var emotions = c.Emotions.Count == 0 ? " (no emotions)" : " " + string.Join(", ", c.Emotions.Select(e => $"{e.Key}: {e.Value}"));
    Console.WriteLine($"  {c.Name}: {c.Health}/{c.MaxHealth} health{emotions}");
}
