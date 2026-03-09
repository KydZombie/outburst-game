using Outburst.Core.Emotions;

namespace Outburst.Core.Characters;

public class Character(string name, uint maxHealth)
{
    public const uint DefaultMaxHealth = 100;

    public static List<Character> CreateDefaultCharacters() =>
    [
        new("Niko", DefaultMaxHealth),
        new("Remi", DefaultMaxHealth),
        new("Arna", DefaultMaxHealth),
        new("Caelum", DefaultMaxHealth),
        new("Syd", DefaultMaxHealth)
    ];

    public string Name { get; } = name;

    public uint Health { get; private set; } = maxHealth;
    public uint MaxHealth { get; } = maxHealth;

    /// <summary>
    /// Maps from emotion type to current level.
    /// Should only be accessed directly for iteration.
    /// </summary>
    public Dictionary<Emotion, uint> Emotions { get; } = new();

    public void Heal(uint amount)
    {
        var healAmount = Math.Min(amount, MaxHealth - Health);

        Health += healAmount;
    }

    public event EventHandler? OnDeath;

    public void Damage(uint amount)
    {
        var damageAmount = Math.Min(amount, Health);

        Health -= damageAmount;

        if (Health == 0)
        {
            OnDeath?.Invoke(this, EventArgs.Empty);
        }
    }

    public void SetEmotion(Emotion emotion, uint amount)
    {
        if (amount == 0)
            Emotions.Remove(emotion);
        else
            Emotions[emotion] = amount;
    }

    public void AddEmotion(Emotion emotion, uint amount = 1)
    {
        Emotions.TryGetValue(emotion, out var current);
        Emotions[emotion] = current + amount;
    }

    public void RemoveEmotion(Emotion emotion, uint amount)
    {
        if (!Emotions.TryGetValue(emotion, out var current)) return;
        if (amount >= current)
            Emotions.Remove(emotion);
        else
            Emotions[emotion] = current - amount;
    }

    public void ClearEmotion(Emotion emotion)
    {
        Emotions.Remove(emotion);
    }
}
