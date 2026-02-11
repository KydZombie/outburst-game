using Outburst.Core.Emotions;

namespace Outburst.Core.Characters;

public class Character(uint maxHealth)
{
    public uint Health { get; private set; } = maxHealth;
    public uint MaxHealth { get; } = maxHealth;

    /// <summary>
    /// Maps from emotion type to current level.
    /// Should only be accessed directly for iteration.
    /// </summary>
    public Dictionary<Emotion, uint> Emotions { get; } = new();

    public void Damage(uint amount)
    {
        throw new NotImplementedException();
    }

    public void Heal(uint amount)
    {
        throw new NotImplementedException();
    }

    public void SetEmotion(Emotion emotion, uint amount)
    {
        throw new NotImplementedException();
    }

    public void AddEmotion(Emotion emotion, uint amount = 1)
    {
        throw new NotImplementedException();
    }

    public void RemoveEmotion(Emotion emotion, uint amount)
    {
        throw new NotImplementedException();
    }

    public void ClearEmotion(Emotion emotion)
    {
        throw new NotImplementedException();
    }
}
