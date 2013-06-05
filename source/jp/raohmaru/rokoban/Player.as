package jp.raohmaru.rokoban
{
import jp.raohmaru.game.enums.Direction;

/**
 * Sprite del jugador principal.
 * @author raohmaru
 */
public class Player extends MovableSprite 
{
	public static const className :String = "player",
						type :String = "@";
						
	private var _facing :String;
	public var pushing :Boolean;
		
	public function set facing(value :String) :void
	{
		_facing = value;
		var fcng :String = _facing + (pushing ? "_push" : "");
		
		if(_moving)
			movie.gotoAndPlay(fcng);
		else
			movie.gotoAndStop(fcng);
	}

	
	
	public function Player(game :Rokoban, px :int, py :int)
	{
		super(game, className, px, py);
	}
	
	override public function move(px :int, py :int, rewind :Boolean=false) :void
	{
		super.move(px, py, rewind);
		
		faceToDirection(_vx, _vy, rewind);
	}
	
	override public function stop() :void
	{
		pushing = false;
		super.stop();
	}
	
	override public function update() :void
	{
		if(_moving && _t >= _dur)
		{
			pushing = false;			
			movie.gotoAndStop(_facing);
		}
		
		super.update();
	}

	override public function reset(x :int=-1, y :int=-1) :void
	{
		super.reset(x, y);
		movie.gotoAndStop(Direction.DOWN);
		pushing = false;
	}
	
	/**
	 * Encara al personaje según una dirección.
	 * @param reverse Hace que mire en dirección contraria.
	 */
	public function faceToDirection(x :int, y :int, reverse :Boolean=false) :void
	{
		if(reverse)
		{
			x = -x;
			y = -y;
		}
		facing = (x < 0 ? Direction.LEFT : (x > 0 ? Direction.RIGHT : (y < 0 ? Direction.UP : (y > 0 ? Direction.DOWN : _facing))));
	}
}
}