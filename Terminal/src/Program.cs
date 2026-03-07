using Outburst.Core.Cards;
using Outburst.Core.Characters;
using Outburst.Terminal;

var characters = Character.CreateDefaultCharacters();

var cards = Card.CreateDefaultDeck();

var game = new TerminalGameLoop(
    characters,
    new Enemy("Jeff", 60, 10),
    cards
);

game.Run();
