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
            {
                Console.WriteLine($"{((Enemy)sender!).Name} attacks {characters[attack.Target].Name} for {attack.Amount}");
            }
            else if (action is EnemyHealAction heal)
            {
                Console.WriteLine($"{((Enemy)sender!).Name} heals for {heal.Amount}");
            }
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
        Console.WriteLine("\nPlayer Turn");

        for (var i = 0; i < state.Hand.Count; i++)
        {
            var card = state.Hand[i];
            Console.WriteLine($"{i + 1} {card.Data.Identifier}");
        }
        Console.WriteLine("# to play card. s to skip turn.");

        Console.Write("> ");
        var input = Console.ReadLine();
        if (input is null)
        {
            // Console.
        }
    }

    private void EnemyTurn()
    {
        Console.WriteLine("\nEnemy Turn");
        state.EnemyAI();
    }
}
