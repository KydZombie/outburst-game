using Outburst.Core.Emotions;

namespace Outburst.Core.Characters;

public class Character(string name, uint maxHealth)
{
    ///Character's display name (Niko, Remi, etc.)
    public string Name { get; } = name;

    public uint Health { get; private set; } = maxHealth;
    public uint MaxHealth { get; } = maxHealth;



    /// <summary>
    /// Maps from emotion type to current level.
    /// Should only be accessed directly for iteration.
    /// </summary>
    public Dictionary<Emotion, uint> Emotions { get; } = Enum
        .GetValues<Emotion>()
        .ToDictionary(e => e, _ => 0u);


    /// Deals damage without letting health go below zero
    public void Damage(uint amount)
    {
        Health = amount >= Health ? 0 : Health - amount;
    }

   ///Heals the character but never above MaxHealth.
    public void Heal(uint amount)
    {
        Health = Math.Min(MaxHealth, Health + amount);

    }

   ///Sets an emotion to an exact value.
    public void SetEmotion(Emotion emotion, uint amount)
    {
        Emotions[emotion] = amount;
    }

   /// Increases an emotion by a given amount (default is 1).
    public void AddEmotion(Emotion emotion, uint amount = 1)
    {
        checked
        {
            Emotions[emotion] += amount;
        }
    }


   /// Lowers an emotion but never below zero.
    public void RemoveEmotion(Emotion emotion, uint amount)
    {
        Emotions[emotion] = amount >= Emotions[emotion] ? 0 : Emotions[emotion] - amount;
    }

   /// Resets a single emotion back to zero
    public void ClearEmotion(Emotion emotion)
    {
        Emotions[emotion] = 0;
    }
}
// Factory for creating preset characters.
// Keeps character creation consistent across the project.
public static class CharacterFactory
{
    public static List<Character> CreateDefaultCharacters()
    {
        return new List<Character>
        {
            new Character("Niko",   100),
            new Character("Remi",   100),
            new Character("Arna",   100),
            new Character("Caelum", 100),
            new Character("Syd",    100)
        };
    }
}
