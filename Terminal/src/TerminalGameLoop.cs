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

            }
        };

        state.Enemy.OnDamaged += (sender, amount) =>
            Console.WriteLine($"Enemy {((Enemy)sender!).Name} damaged for {amount}");

        state.Enemy.OnHealed += (sender, amount) =>
            Console.WriteLine($"Enemy {((Enemy)sender!).Name} healed for {amount}");
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
        Console.WriteLine("Player Turn");

        for (var i = 0; i < state.Hand.Count; i++)
        {
            var card = state.Hand[i];
            Console.WriteLine($"{i+1} {card.Data.Identifier}");
        }
        Console.WriteLine("# to play card. s to skip turn.");

        Console.Write("> ");
        var input = Console.ReadLine();
        if (input is null) {
            // Console.
        }
    }

    private void EnemyTurn()
    {
        Console.WriteLine("starting enemy turn");

        Console.WriteLine("ending enemy turn");
    }
}
