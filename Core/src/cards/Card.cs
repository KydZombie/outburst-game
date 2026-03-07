using Outburst.Core.Battles;
using Outburst.Core.Cards.Effects;
using Outburst.Core.Cards.Requirements;
using Outburst.Core.Emotions;

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

    public Card Copy()
    {
        return new Card(Data);
    }

    internal bool Play(BattleState battleState)
    {
        if (!MeetsRequirements(battleState)) return false;
        foreach (var requirement in Data.Requirements) requirement.TakeRequirements(battleState);
        foreach (var effect in Data.Effects) effect.ApplyEffect(battleState);
        return true;
    }

    public static List<Card> CreateDefaultDeck()
    {
        var energyCard = new Card(new CardData(
            "gain_energy",
            new List<IRequirement>(),
            new List<IEffect>
            {
                new GainEnergyEffect(8)
            }
        ));

        var basicPunch = new Card(new CardData(
            "basic_punch",
            new List<IRequirement> { new EnergyRequirement(1) },
            new List<IEffect>
            {
                new DamageEnemyEffect(2)
            }
        ));

        var getAngry = new Card(new CardData(
            "get_angry",
            new List<IRequirement>(),
            new List<IEffect> { new AddEmotionEffect(Emotion.Angry, 2) },
            true
        ));

        var angryPunch = new Card(new CardData(
            "angry_punch",
            new List<IRequirement> { new EmotionRequirement(Emotion.Angry, 1) },
            new List<IEffect>
            {
                new DamageEnemyEffect(5)
            },
            true
        ));

        return
        [
            energyCard.Copy(),
            energyCard.Copy(),
            energyCard.Copy(),
            basicPunch.Copy(),
            basicPunch.Copy(),
            basicPunch.Copy(),
            basicPunch.Copy(),

            getAngry.Copy(),
            getAngry.Copy(),
            getAngry.Copy(),

            angryPunch.Copy(),
            angryPunch.Copy(),

            new Card(new CardData(
                "cheer_up",
                new List<IRequirement>
                {
                    new EnergyRequirement(1)
                },
                new List<IEffect>
                {
                    new SetEmotionEffect(Emotion.Angry, 0),
                    new SetEmotionEffect(Emotion.Sad, 0),
                    new AddEmotionEffect(Emotion.Happy, 2)
                },
                true
            ))
        ];
    }
}
