package jp.raohmaru.game.core 
{

/**
 * @author raohmaru
 */
public interface IGameElement 
{
	function get game() : IGame;
	function set game(value : IGame) : void;
}
}