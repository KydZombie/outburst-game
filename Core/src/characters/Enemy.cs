using Outburst.Core.Battles;

namespace Outburst.Core.Characters;

public interface IEnemyAction { }

public readonly record struct EnemyAttackAction(int Target, uint Amount) : IEnemyAction { }
public readonly record struct EnemyHealAction(uint Amount) : IEnemyAction { }

public class Enemy(string name, uint maxHealth, uint power)
{
    public string Name { get; } = name;

    public uint Health { get; private set; } = maxHealth;
    public uint MaxHealth { get; } = maxHealth;

    public uint Power { get; } = power;

    public event EventHandler<IEnemyAction>? OnAction;

    public void Attack(BattleState state, int targetIdx, uint amount)
    {
        var attackAmount = Math.Min(amount, state.Characters[targetIdx].Health);

        state.Characters[targetIdx].Damage(attackAmount);
        OnAction?.Invoke(this, new EnemyAttackAction(targetIdx, attackAmount));
    }

    public void Heal(uint amount)
    {
        var healAmount = Math.Min(amount, MaxHealth - Health);

        Health += healAmount;
        OnAction?.Invoke(this, new EnemyHealAction(healAmount));
    }

    public event EventHandler? OnDeath;
    public event EventHandler<uint>? OnDamaged;

    public void Damage(uint amount)
    {
        var damageAmount = Math.Min(amount, Health);

        Health -= damageAmount;
        OnDamaged?.Invoke(this, damageAmount);

        if (Health == 0)
        {
            OnDeath?.Invoke(this, EventArgs.Empty);
        }
    }
}
