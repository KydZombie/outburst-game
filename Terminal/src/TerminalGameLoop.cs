using Outburst.Core.Battles;
using Outburst.Core.Cards;
using Outburst.Core.Characters;

namespace Outburst.Terminal;

public class TerminalGameLoop
{
    private readonly BattleState state;
    private bool shouldQuit = false;

    public TerminalGameLoop(List<Character> characters, Enemy enemy, List<Card> cards)
    {
        state = new BattleState(
            characters,
            enemy,
            cards
        );

        state.Enemy.OnAction += (sender, action) =>
        {
            if (action is EnemyAttackAction attack)
                Console.WriteLine(
                    $"{((Enemy)sender!).Name} attacks {characters[attack.Target].Name} for {attack.Amount}");
            else if (action is EnemyHealAction heal)
                Console.WriteLine($"{((Enemy)sender!).Name} heals for {heal.Amount}");
        };

        state.Enemy.OnDamaged += (sender, amount) =>
        {
            Console.WriteLine($"{((Enemy)sender!).Name} damaged for {amount}");
        };

        state.Enemy.OnDeath += (sender, e) =>
        {
            Console.WriteLine($"{((Enemy)sender!).Name} defeated");
            shouldQuit = true;
        };
    }

    public void Run()
    {
        for (var i = 0; i < 3; i++) state.DrawCard();

        while (true)
        {
            PlayerTurn();
            if (shouldQuit) break;
            EnemyTurn();
            if (shouldQuit) break;
        }
    }

    private void PlayerTurn()
    {
        do
        {
            Console.WriteLine("\nPlayer Turn");

            Console.WriteLine($"Energy: {state.Energy}");

            Console.Write("Characters: ");
            for (var i = 0; i < state.Characters.Count; i++)
            {
                var character = state.Characters[i];
                Console.Write($"{i + 1}) {character.Name} {character.Health}/{character.MaxHealth} ");

                if (character.Emotions.Count > 0)
                    foreach (var emotion in character.Emotions)
                        Console.Write($"{emotion.Key}: {emotion.Value} ");
            }

            Console.WriteLine();

            Console.Write("Cards: ");

            for (var i = 0; i < state.Hand.Count; i++)
            {
                var card = state.Hand[i];
                Console.Write($"{i + 1}) {card.Data.Identifier} ");
            }

            Console.WriteLine();

            Console.WriteLine(
                "# to play card. d to draw a card and end your turn. s to skip turn without drawing. q to quit.");

            Console.Write("> ");

            var input = Console.ReadLine();
            if (input is null) continue;
            input = input.Trim();
            if (int.TryParse(input, out var number))
            {
                if (number <= 0 || number > state.Hand.Count)
                {
                    Console.WriteLine($"{number} is an invalid card index.");
                }
                else
                {
                    var card = state.Hand[number - 1];
                    if (card.Data.RequiresCharacterTarget)
                    {
                        Console.Write("Choose character to target: ");
                        input = Console.ReadLine();
                        if (input is null) continue;
                        if (int.TryParse(input, out var characterTarget) &&
                            characterTarget > 0 && characterTarget <= state.Characters.Count)
                        {
                            state.TargetCharacterIndex = characterTarget - 1;
                        }
                        else
                        {
                            Console.WriteLine("No character target chosen/Invalid character target.");
                            Console.ReadLine();
                            continue;
                        }
                    }

                    Console.WriteLine(state.PlayCardFromHand(card.CardId)
                        ? $"Successfully played card {card.Data.Identifier}"
                        : $"Failed to play card {card.Data.Identifier}");
                }
            }
            else
            {
                switch (input)
                {
                    case "q":
                        shouldQuit = true;
                        return;
                    case "d":
                        var card = state.DrawCard();
                        Console.WriteLine(card is not null ? $"Drew {card.Value.Data.Identifier}." : "Deck is empty.");
                        return;
                    case "s":
                        return;
                }
            }

            Console.ReadLine();
        } while (true);
    }

    private void EnemyTurn()
    {
        Console.WriteLine("\nEnemy Turn");
        state.EnemyAI();
    }
}
