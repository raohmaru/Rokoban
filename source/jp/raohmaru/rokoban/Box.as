package jp.raohmaru.rokoban
{

/**
 * Caja que el jugador debe colocar en la posición de destino.
 * @author raohmaru
 */
public class Box extends MovableSprite 
{
	public static const className :String = "box",
						type :String = "$";
						
	public var movable :Boolean = true;
	
	
	
	public function Box(game :Rokoban, px :int, py :int)
	{
		super(game, className, px, py);
	}
}
}