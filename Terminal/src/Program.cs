using Outburst.Core.Battles;
using Outburst.Core.Cards;
using Outburst.Core.Cards.Effects;
using Outburst.Core.Cards.Requirements;
using Outburst.Core.Characters;
using Outburst.Core.Emotions;
using Outburst.Terminal;

var characters = Character.CreateDefaultCharacters();

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

var game = new TerminalGameLoop(
    characters,
    new Enemy("Jeff", 60, 10),
    cards
);

game.Run();
