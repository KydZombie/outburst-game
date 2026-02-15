using System;
using System.Collections.Generic;
namespace Outburst.Core.Emotions;

public enum Emotion
{
    Happy,
    Sad,
    Angry
}

// Handles all emotion values for a character.
// Keeping this separate from Character makes the system cleaner
//and easier to expand without touching character logic.

public class EmotionState
{
    // Stores the current level of each emotion.
    private readonly Dictionary<Emotion, uint> _levels = new();

   // Initializes all emotions to zero.
    public EmotionState()
    {
        foreach (Emotion emotion in Enum.GetValues(typeof(Emotion)))
            _levels[emotion] = 0;
    }

    // Gets the current level of an emotion.
    public uint GetEmotionLevel(Emotion emotion)
    {
        return _levels[emotion];
    }

    // Sets an emotion to an exact value.
    public void SetEmotionLevel(Emotion emotion, uint level)
    {
        _levels[emotion] = level;
    }

    // Increases an emotion by a given amount (default is 1).
    public void AddEmotion(Emotion emotion, uint amount = 1)
    {
        checked
        {
            _levels[emotion] += amount;
        }
    }

    // Lowers an emotion but never below zero.
    public void RemoveEmotion(Emotion emotion, uint amount)
    {
        _levels[emotion] = amount >= _levels[emotion] ? 0 : _levels[emotion] - amount;
    }

    // Resets a single emotion back to zero
    public void ClearEmotion(Emotion emotion)
    {
        _levels[emotion] = 0;
    }

    // Exposes the emotion dictionary as read‑only for iteration.
    public IReadOnlyDictionary<Emotion, uint> AsReadOnly() => _levels;
}


