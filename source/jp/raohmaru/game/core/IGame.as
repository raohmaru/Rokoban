package jp.raohmaru.game.core 
{
import flash.events.IEventDispatcher;

/**
 * @author raohmaru
 */
public interface IGame extends IEventDispatcher
{
	function start() :void;
}
}