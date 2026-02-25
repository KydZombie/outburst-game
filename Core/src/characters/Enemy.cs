using Outburst.Core.Battles;

namespace Outburst.Core.Characters;

public class Enemy(string name, uint maxHealth)
{
    public string Name { get; } = name;
    public uint Health { get; private set; } = maxHealth;
    public uint MaxHealth { get; } = maxHealth;

    public event EventHandler<IEnemyAction>? OnAction;

    public event EventHandler<uint>? OnDamaged;

    public void Damage(uint amount)
    {
        var damageAmount = Math.Min(amount, Health);
        Health = Health - damageAmount;
        OnDamaged?.Invoke(this, damageAmount);

        OnAction?.Invoke(this, new EnemyAttackAction(1, 10));
    }

    public event EventHandler<uint>? OnHealed;

    public void Heal(uint amount)
    {
        var healAmount = Math.Min(amount, MaxHealth - Health);
        Health = Health + healAmount;
        OnHealed?.Invoke(this, healAmount);
    }
}

public interface IEnemyAction
{
    string GetDebugMessage(Enemy enemy);
}

public readonly record struct EnemyAttackAction(int CharacterIdx, int Amount) : IEnemyAction
{
    public string GetDebugMessage(Enemy enemy)
    {
        return "Damaged enemy";
    }
}
